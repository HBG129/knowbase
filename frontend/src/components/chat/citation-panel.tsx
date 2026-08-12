"use client";

import { FileText, X } from "lucide-react";
import { cn } from "@/lib/utils";
import { useI18nStore } from "@/stores/i18n-store";

interface Citation {
  doc_id: string;
  doc_filename?: string;
  chunk_index: number;
  snippet: string;
  score?: number;
}

interface CitationPanelProps {
  citations: Citation[];
  activeCitation?: { docId: string; chunkIndex: number } | null;
  onCitationClick?: (docId: string, chunkIndex: number) => void;
  onClose?: () => void;
  className?: string;
}

export function CitationPanel({ citations, activeCitation, onCitationClick, onClose, className }: CitationPanelProps) {
  const { t } = useI18nStore();
  if (citations.length === 0) {
    return (
      <div className={cn("p-6", className)}>
        <div className="flex flex-col items-center justify-center h-full text-center space-y-3">
          <FileText className="h-8 w-8 text-ink-muted/40" />
          <div>
            <p className="text-sm font-medium text-ink-muted">{t("chat.noSources")}</p>
            <p className="text-xs text-ink-muted/60 mt-1">{t("chat.noSourcesHint")}</p>
          </div>
        </div>
      </div>
    );
  }

  const grouped = citations.reduce((acc, cite) => {
    if (!acc[cite.doc_id]) acc[cite.doc_id] = [];
    acc[cite.doc_id].push(cite);
    return acc;
  }, {} as Record<string, Citation[]>);

  return (
    <div className={cn("h-full flex flex-col", className)}>
      <div className="flex items-center justify-between p-4 border-b border-hairline">
        <h3 className="text-sm font-semibold text-ink">
          {citations.length === 1
            ? t("chat.sourceCountOne")
            : t("chat.sourcesCount", { count: citations.length })}
        </h3>
        {onClose && (
          <button onClick={onClose} aria-label={t("common.close")} title={t("common.close")} className="p-1 rounded-md hover:bg-canvas-soft transition-colors">
            <X className="h-4 w-4 text-ink-muted" />
          </button>
        )}
      </div>

      <div className="flex-1 overflow-y-auto p-3 space-y-3">
        {Object.entries(grouped).map(([docId, cites]) => (
          <div key={docId} className="space-y-1.5">
            <p className="text-xs font-medium text-ink-muted uppercase tracking-wider px-1">
              {cites[0]?.doc_filename || t("chat.documentFallback", { id: docId.slice(0, 8) })}
            </p>
            {cites.map((cite) => {
              const isActive =
                activeCitation?.docId === cite.doc_id &&
                activeCitation?.chunkIndex === cite.chunk_index;

              return (
                <button
                  key={`${cite.doc_id}-${cite.chunk_index}`}
                  onClick={() => onCitationClick?.(cite.doc_id, cite.chunk_index)}
                  className={cn(
                    "w-full text-left p-3 rounded-lg transition-all duration-150 border",
                    isActive
                      ? "border-accent bg-accent-soft/60 shadow-sm"
                      : "border-hairline bg-canvas hover:border-hairline-strong hover:shadow-sm"
                  )}
                >
                  <div className="flex items-center justify-between mb-1.5">
                    <span className="text-xs font-medium text-ink-soft">{t("chat.chunk", { index: cite.chunk_index })}</span>
                    {cite.score !== undefined && (
                      <span className="text-[10px] text-ink-muted">
                        {(cite.score * 100).toFixed(0)}%
                      </span>
                    )}
                  </div>
                  <p className="text-xs text-ink-body line-clamp-3 leading-relaxed">{cite.snippet}</p>
                </button>
              );
            })}
          </div>
        ))}
      </div>
    </div>
  );
}
