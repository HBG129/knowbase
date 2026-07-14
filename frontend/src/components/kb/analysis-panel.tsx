"use client";

import { useCallback, useEffect, useMemo, useState } from "react";
import { AlertTriangle, BarChart3, Clock, Database, Key, Play, Table2 } from "lucide-react";
import { ApiKeyDialog } from "@/components/auth/api-key-dialog";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { api } from "@/lib/api";

interface ColumnProfile {
  name: string;
  type: "number" | "text";
  missing_count: number;
  min?: number | null;
  max?: number | null;
  top_values?: { value: string; count: number }[];
}

interface Dataset {
  doc_id: string;
  filename: string;
  row_count: number;
  column_count: number;
  columns: ColumnProfile[];
  recommended_questions: string[];
  created_at: string;
}

interface Preview {
  columns: string[];
  rows: string[][];
  profile: {
    row_count: number;
    column_count: number;
    columns: ColumnProfile[];
  };
}

interface ChartSpec {
  type: "bar" | "line" | "pie" | "table";
  x: string;
  y: string;
  series: (string | number | null)[][];
  title: string;
}

interface AnalysisRun {
  id: string;
  run_id: string;
  kb_id: string;
  doc_id: string;
  question: string;
  sql: string | null;
  columns: string[];
  rows: (string | number | null)[][];
  chart: ChartSpec;
  summary: string;
  insights: string[];
  error_message?: string | null;
  created_at: string;
}

interface AnalysisPanelProps {
  kbId: string;
}

function isApiKeyError(message: string) {
  return message.toLowerCase().includes("api key");
}

function numberValue(value: string | number | null | undefined) {
  if (typeof value === "number") return Number.isFinite(value) ? value : 0;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

function MiniChart({ chart }: { chart?: ChartSpec }) {
  if (!chart || chart.type === "table" || chart.series.length === 0) {
    return (
      <div className="flex h-48 items-center justify-center rounded-lg border border-dashed border-hairline bg-canvas-soft text-sm text-ink-muted">
        No chart for this result
      </div>
    );
  }

  const width = 520;
  const height = 220;
  const padding = 28;
  const values = chart.series.map((row) => numberValue(row[1]));
  const minValue = Math.min(...values, 0);
  const maxValue = Math.max(...values, 0);
  const valueRange = Math.max(maxValue - minValue, 1);
  const scaleY = (value: number) =>
    height - padding - ((value - minValue) / valueRange) * (height - padding * 2);
  const zeroY = scaleY(0);

  if (chart.type === "pie") {
    let offset = 0;
    const total = values.reduce((sum, value) => sum + Math.max(value, 0), 0) || 1;
    return (
      <div className="rounded-lg border border-hairline bg-canvas p-4">
        <p className="mb-3 text-sm font-medium text-ink">{chart.title}</p>
        <div className="flex flex-col gap-4 md:flex-row md:items-center">
          <svg viewBox="0 0 120 120" className="h-44 w-44 shrink-0">
            {values.map((value, index) => {
              const amount = Math.max(value, 0) / total;
              const dash = `${amount * 100} ${100 - amount * 100}`;
              const color = ["#111827", "#2563eb", "#16a34a", "#f59e0b", "#dc2626"][index % 5];
              const slice = (
                <circle
                  key={index}
                  cx="60"
                  cy="60"
                  r="42"
                  fill="none"
                  stroke={color}
                  strokeWidth="22"
                  strokeDasharray={dash}
                  strokeDashoffset={-offset}
                  transform="rotate(-90 60 60)"
                />
              );
              offset += amount * 100;
              return slice;
            })}
          </svg>
          <div className="grid min-w-0 flex-1 gap-2 text-xs">
            {chart.series.slice(0, 6).map((row, index) => (
              <div key={index} className="flex items-center justify-between gap-3">
                <span className="truncate text-ink-body">{String(row[0])}</span>
                <span className="font-medium text-ink">{numberValue(row[1]).toLocaleString()}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    );
  }

  const points = values.map((value, index) => {
    const x = padding + (index * (width - padding * 2)) / Math.max(values.length - 1, 1);
    const y = scaleY(value);
    return { x, y, value };
  });

  return (
    <div className="overflow-hidden rounded-lg border border-hairline bg-canvas p-4">
      <p className="mb-3 text-sm font-medium text-ink">{chart.title}</p>
      <svg viewBox={`0 0 ${width} ${height}`} className="h-56 w-full">
        <line x1={padding} y1={zeroY} x2={width - padding} y2={zeroY} stroke="rgb(var(--hairline-strong))" />
        <line x1={padding} y1={padding} x2={padding} y2={height - padding} stroke="rgb(var(--hairline-strong))" />
        {chart.type === "bar" ? (
          points.map((point, index) => {
            const barWidth = Math.max(2, (width - padding * 2) / Math.max(points.length, 1) - 8);
            return (
              <rect
                key={index}
                x={point.x - barWidth / 2}
                y={Math.min(point.y, zeroY)}
                width={barWidth}
                height={Math.abs(point.y - zeroY)}
                rx="4"
                fill="rgb(var(--ink))"
              />
            );
          })
        ) : (
          <>
            <polyline
              fill="none"
              stroke="rgb(var(--ink))"
              strokeWidth="3"
              points={points.map((point) => `${point.x},${point.y}`).join(" ")}
            />
            {points.map((point, index) => (
              <circle key={index} cx={point.x} cy={point.y} r="4" fill="rgb(var(--ink))" />
            ))}
          </>
        )}
      </svg>
    </div>
  );
}

function ResultTable({ columns, rows }: { columns: string[]; rows: (string | number | null)[][] }) {
  if (columns.length === 0) return null;
  return (
    <div className="overflow-hidden rounded-lg border border-hairline">
      <div className="max-h-80 overflow-auto">
        <table className="w-full min-w-[520px] text-left text-xs">
          <thead className="sticky top-0 bg-canvas-soft text-ink-muted">
            <tr>
              {columns.map((column) => (
                <th key={column} className="border-b border-hairline px-3 py-2 font-medium">{column}</th>
              ))}
            </tr>
          </thead>
          <tbody className="divide-y divide-hairline">
            {rows.map((row, rowIndex) => (
              <tr key={rowIndex} className="bg-canvas">
                {columns.map((column, columnIndex) => (
                  <td key={column} className="px-3 py-2 text-ink-body">{String(row[columnIndex] ?? "")}</td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export function AnalysisPanel({ kbId }: AnalysisPanelProps) {
  const [datasets, setDatasets] = useState<Dataset[]>([]);
  const [selectedDocId, setSelectedDocId] = useState("");
  const [preview, setPreview] = useState<Preview | null>(null);
  const [runs, setRuns] = useState<AnalysisRun[]>([]);
  const [activeRun, setActiveRun] = useState<AnalysisRun | null>(null);
  const [question, setQuestion] = useState("");
  const [loading, setLoading] = useState(true);
  const [previewLoading, setPreviewLoading] = useState(false);
  const [running, setRunning] = useState(false);
  const [error, setError] = useState("");
  const [apiKeyOpen, setApiKeyOpen] = useState(false);

  const selectedDataset = useMemo(
    () => datasets.find((dataset) => dataset.doc_id === selectedDocId) || null,
    [datasets, selectedDocId]
  );

  const fetchDatasets = useCallback(async () => {
    setLoading(true);
    setError("");
    try {
      const data = await api.get<Dataset[]>(`/api/kb/${kbId}/analysis/datasets`);
      setDatasets(data);
      setSelectedDocId((current) => current || data[0]?.doc_id || "");
    } catch (err: any) {
      setError(err.message || "Failed to load datasets");
    } finally {
      setLoading(false);
    }
  }, [kbId]);

  const fetchRuns = useCallback(async () => {
    try {
      const data = await api.get<AnalysisRun[]>(`/api/kb/${kbId}/analysis/runs`);
      setRuns(data);
    } catch {
      setRuns([]);
    }
  }, [kbId]);

  useEffect(() => {
    fetchDatasets();
    fetchRuns();
  }, [fetchDatasets, fetchRuns]);

  useEffect(() => {
    if (!selectedDocId) {
      setPreview(null);
      return;
    }
    let cancelled = false;
    setPreview(null);
    setPreviewLoading(true);
    setError("");
    api.get<Preview>(`/api/kb/${kbId}/analysis/datasets/${selectedDocId}/preview`)
      .then((data) => {
        if (!cancelled) setPreview(data);
      })
      .catch((err: any) => {
        if (!cancelled) setError(err.message || "Failed to load preview");
      })
      .finally(() => {
        if (!cancelled) setPreviewLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, [kbId, selectedDocId]);

  async function handleAnalyze() {
    if (!selectedDocId || !question.trim() || running) return;
    setRunning(true);
    setError("");
    try {
      const run = await api.post<AnalysisRun>(`/api/kb/${kbId}/analysis/query`, {
        doc_id: selectedDocId,
        question: question.trim(),
      });
      setActiveRun(run);
      setRuns((current) => [run, ...current.filter((item) => item.id !== run.id)]);
    } catch (err: any) {
      const message = err.message || "Analysis failed";
      setError(message);
      if (isApiKeyError(message)) setApiKeyOpen(true);
      void fetchRuns();
    } finally {
      setRunning(false);
    }
  }

  if (loading) {
    return (
      <Card padding="lg" className="flex min-h-72 items-center justify-center">
        <div className="h-8 w-8 animate-spin rounded-full border-2 border-ink border-t-transparent" />
      </Card>
    );
  }

  if (error && datasets.length === 0) {
    return (
      <Card padding="lg" className="text-center">
        <AlertTriangle className="mx-auto h-6 w-6 text-error" />
        <h2 className="mt-3 text-base font-semibold text-ink">Could not load CSV datasets</h2>
        <p className="mx-auto mt-2 max-w-md text-sm text-error">{error}</p>
        <Button className="mt-4" variant="secondary" onClick={fetchDatasets}>Retry</Button>
      </Card>
    );
  }

  if (datasets.length === 0) {
    return (
      <Card padding="lg" className="text-center">
        <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl border border-hairline bg-canvas-soft">
          <Database className="h-5 w-5 text-ink-muted" />
        </div>
        <h2 className="text-base font-semibold text-ink">No CSV datasets yet</h2>
        <p className="mx-auto mt-2 max-w-md text-sm text-ink-muted">
          Upload a completed CSV document, then return here to preview the data and run AI analysis.
        </p>
      </Card>
    );
  }

  return (
    <div className="grid gap-6 xl:grid-cols-[280px_minmax(0,1fr)]">
      <div className="space-y-4">
        <Card padding="none" className="overflow-hidden">
          <div className="border-b border-hairline px-4 py-3">
            <h2 className="flex items-center gap-2 text-sm font-semibold text-ink">
              <Database className="h-4 w-4 text-ink-muted" /> Datasets
            </h2>
          </div>
          <div className="max-h-80 overflow-auto p-2">
            {datasets.map((dataset) => (
              <button
                key={dataset.doc_id}
                onClick={() => {
                  setSelectedDocId(dataset.doc_id);
                  setActiveRun(null);
                }}
                className={
                  "w-full rounded-lg px-3 py-2.5 text-left transition-colors " +
                  (selectedDocId === dataset.doc_id ? "bg-accent-soft text-accent" : "text-ink-body hover:bg-canvas-soft")
                }
              >
                <span className="block truncate text-sm font-medium">{dataset.filename}</span>
                <span className="mt-1 block text-xs text-ink-muted">
                  {dataset.row_count.toLocaleString()} rows / {dataset.column_count} columns
                </span>
              </button>
            ))}
          </div>
        </Card>

        <Card padding="none" className="overflow-hidden">
          <div className="border-b border-hairline px-4 py-3">
            <h2 className="flex items-center gap-2 text-sm font-semibold text-ink">
              <Clock className="h-4 w-4 text-ink-muted" /> History
            </h2>
          </div>
          <div className="max-h-80 overflow-auto p-2">
            {runs.length === 0 ? (
              <p className="px-2 py-3 text-xs text-ink-muted">No analysis runs yet.</p>
            ) : (
              runs.map((run) => (
                <button
                  key={run.id}
                  onClick={() => {
                    setSelectedDocId(run.doc_id);
                    setActiveRun(run);
                    setError("");
                  }}
                  className="w-full rounded-lg px-3 py-2.5 text-left text-ink-body transition-colors hover:bg-canvas-soft"
                >
                  <span className="line-clamp-2 text-sm font-medium">{run.question}</span>
                  {run.error_message && (
                    <span className="mt-1 flex items-center gap-1 text-xs text-error">
                      <AlertTriangle className="h-3 w-3" /> Failed
                    </span>
                  )}
                  <span className="mt-1 block text-xs text-ink-muted">
                    {run.created_at ? new Date(run.created_at).toLocaleString() : "Saved run"}
                  </span>
                </button>
              ))
            )}
          </div>
        </Card>
      </div>

      <div className="min-w-0 space-y-6">
        <Card padding="lg">
          <div className="mb-5 flex flex-col gap-3 md:flex-row md:items-start md:justify-between">
            <div>
              <h2 className="flex items-center gap-2 text-base font-semibold text-ink">
                <BarChart3 className="h-4 w-4 text-ink-muted" /> Ask your data
              </h2>
              <p className="mt-1 text-sm text-ink-muted">
                {selectedDataset?.filename || "Select a CSV dataset"}
              </p>
            </div>
            <Button variant="secondary" size="sm" onClick={() => setApiKeyOpen(true)}>
              <Key className="h-3.5 w-3.5" /> API Key
            </Button>
          </div>

          {selectedDataset && (
            <div className="mb-4 flex flex-wrap gap-2">
              {selectedDataset.recommended_questions.map((item) => (
                <button
                  key={item}
                  onClick={() => setQuestion(item)}
                  className="rounded-lg border border-hairline bg-canvas-soft px-3 py-1.5 text-xs text-ink-body transition-colors hover:border-hairline-strong"
                >
                  {item}
                </button>
              ))}
            </div>
          )}

          <div className="flex flex-col gap-3 md:flex-row">
            <textarea
              value={question}
              onChange={(event) => setQuestion(event.target.value)}
              rows={3}
              placeholder="Ask for a trend, ranking, anomaly, or short business report..."
              className="min-h-24 flex-1 resize-none rounded-lg border border-hairline bg-canvas px-3 py-2 text-sm text-ink outline-none transition-colors placeholder:text-ink-placeholder focus:border-hairline-focus focus:ring-2 focus:ring-accent/10"
            />
            <Button className="md:self-end" loading={running} disabled={!question.trim() || !selectedDocId} onClick={handleAnalyze}>
              <Play className="h-4 w-4" /> Analyze
            </Button>
          </div>

          {error && (
            <div className="mt-4 flex items-start gap-2 rounded-lg border border-error/20 bg-error/5 px-3 py-2 text-sm text-error">
              <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}
        </Card>

        {preview && (
          <Card padding="none" className="overflow-hidden">
            <div className="flex items-center justify-between border-b border-hairline px-4 py-3">
              <h2 className="flex items-center gap-2 text-sm font-semibold text-ink">
                <Table2 className="h-4 w-4 text-ink-muted" /> Data preview
              </h2>
              {previewLoading && <span className="text-xs text-ink-muted">Loading...</span>}
            </div>
            <div className="grid gap-4 p-4 lg:grid-cols-[220px_minmax(0,1fr)]">
              <div className="space-y-2">
                <div className="rounded-lg bg-canvas-soft p-3">
                  <p className="text-xs text-ink-muted">Rows</p>
                  <p className="text-lg font-semibold text-ink">{preview.profile.row_count.toLocaleString()}</p>
                </div>
                <div className="rounded-lg bg-canvas-soft p-3">
                  <p className="text-xs text-ink-muted">Columns</p>
                  <p className="text-lg font-semibold text-ink">{preview.profile.column_count}</p>
                </div>
                <div className="space-y-1.5">
                  {preview.profile.columns.slice(0, 8).map((column) => (
                    <div key={column.name} className="rounded-lg border border-hairline px-3 py-2">
                      <div className="flex items-center justify-between gap-2">
                        <span className="truncate text-xs font-medium text-ink">{column.name}</span>
                        <span className="text-[11px] uppercase text-ink-muted">{column.type}</span>
                      </div>
                      {column.missing_count > 0 && (
                        <p className="mt-1 text-[11px] text-warning">{column.missing_count} missing</p>
                      )}
                    </div>
                  ))}
                </div>
              </div>
              <ResultTable columns={preview.columns} rows={preview.rows} />
            </div>
          </Card>
        )}

        {activeRun && (
          <div className="space-y-6">
            {activeRun.error_message ? (
              <Card padding="lg" className="border-error/20 bg-error/5">
                <h2 className="mb-2 flex items-center gap-2 text-base font-semibold text-error">
                  <AlertTriangle className="h-4 w-4" /> Analysis failed
                </h2>
                <p className="text-sm leading-6 text-error">{activeRun.error_message}</p>
              </Card>
            ) : (
              <>
                <Card padding="lg">
                  <h2 className="mb-2 text-base font-semibold text-ink">Analysis summary</h2>
                  <p className="text-sm leading-6 text-ink-body">{activeRun.summary || "No summary returned."}</p>
                  {activeRun.insights.length > 0 && (
                    <div className="mt-4 flex flex-wrap gap-2">
                      {activeRun.insights.map((insight) => (
                        <span key={insight} className="rounded-lg bg-canvas-soft px-3 py-1 text-xs text-ink-muted">
                          {insight}
                        </span>
                      ))}
                    </div>
                  )}
                </Card>

                <MiniChart chart={activeRun.chart} />
              </>
            )}

            <Card padding="none" className="overflow-hidden">
              <div className="border-b border-hairline px-4 py-3">
                <h2 className="text-sm font-semibold text-ink">Generated SQL</h2>
              </div>
              <pre className="overflow-x-auto bg-ink p-4 text-xs leading-5 text-canvas">{activeRun.sql || "No SQL saved."}</pre>
            </Card>

            {!activeRun.error_message && (
              <Card padding="none" className="overflow-hidden">
                <div className="border-b border-hairline px-4 py-3">
                  <h2 className="text-sm font-semibold text-ink">Result rows</h2>
                </div>
                <div className="p-4">
                  <ResultTable columns={activeRun.columns} rows={activeRun.rows} />
                </div>
              </Card>
            )}
          </div>
        )}
      </div>

      <ApiKeyDialog open={apiKeyOpen} onClose={() => setApiKeyOpen(false)} />
    </div>
  );
}
