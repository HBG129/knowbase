"use client";

import { useState, useEffect } from "react";
import { FileText, File, Trash2, Loader2, Clock, CheckCircle2, XCircle } from "lucide-react";
import { cn, formatRelativeTime } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";
import { api } from "@/lib/api";

interface Document {
  id: string;
  filename: string;
  file_type: string;
  file_size: number;
  status: string;
  chunk_count: number;
  created_at: string;
}

interface DocumentListProps {
  kbId: string;
  onSelect?: (doc: Document) => void;
  selectedId?: string | null;
}

const statusConfig = {
  pending: { icon: Clock, label: "Pending", variant: "default" as const },
  processing: { icon: Loader2, label: "Processing", variant: "warning" as const },
  completed: { icon: CheckCircle2, label: "Ready", variant: "success" as const },
  failed: { icon: XCircle, label: "Failed", variant: "error" as const },
};

export function DocumentList({ kbId, onSelect, selectedId }: DocumentListProps) {
  const [docs, setDocs] = useState<Document[]>([]);
  const [loading, setLoading] = useState(true);

  const fetchDocs = async () => {
    try {
      const data = await api.get<Document[]>(`/api/kb/${kbId}/documents`);
      setDocs(data);
    } catch {}
    setLoading(false);
  };

  useEffect(() => {
    fetchDocs();
  }, [kbId]);

  const deleteDoc = async (docId: string) => {
    await api.delete(`/api/kb/${kbId}/documents/${docId}`);
    setDocs((prev) => prev.filter((d) => d.id !== docId));
  };

  if (loading) {
    return (
      <div className="space-y-2">
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-16 rounded-lg animate-shimmer bg-canvas-soft" />
        ))}
      </div>
    );
  }

  if (docs.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center py-16 text-center">
        <FileText className="h-12 w-12 text-ink-muted/30 mb-4" />
        <p className="text-sm font-medium text-ink-muted">No documents yet</p>
        <p className="text-xs text-ink-muted/60 mt-1">Upload documents to start building your knowledge base</p>
      </div>
    );
  }

  return (
    <div className="space-y-1.5">
      {docs.map((doc) => {
        const config = statusConfig[doc.status as keyof typeof statusConfig] || statusConfig.pending;
        const Icon = config.icon;

        return (
          <div
            key={doc.id}
            onClick={() => onSelect?.(doc)}
            className={cn(
              "flex items-center gap-3 p-3 rounded-lg cursor-pointer transition-all duration-150 group",
              selectedId === doc.id
                ? "bg-accent-soft/60 border border-accent/20"
                : "hover:bg-canvas-soft border border-transparent"
            )}
          >
            <div className="h-9 w-9 rounded-lg bg-canvas-soft border border-hairline flex items-center justify-center flex-shrink-0">
              <File className="h-4 w-4 text-ink-muted" />
            </div>

            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium text-ink truncate">{doc.filename}</p>
              <div className="flex items-center gap-2 mt-0.5">
                <Badge variant={config.variant}>
                  <Icon className={cn("h-3 w-3 mr-1", doc.status === "processing" && "animate-spin")} />
                  {config.label}
                </Badge>
                <span className="text-xs text-ink-muted">
                  {doc.file_type.toUpperCase()} · {(doc.file_size / 1024).toFixed(1)}KB
                </span>
                {doc.chunk_count > 0 && (
                  <span className="text-xs text-ink-muted">{doc.chunk_count} chunks</span>
                )}
              </div>
            </div>

            <span className="text-xs text-ink-muted/60 flex-shrink-0">
              {formatRelativeTime(doc.created_at)}
            </span>

            <button
              onClick={(e) => { e.stopPropagation(); deleteDoc(doc.id); }}
              className="p-1.5 rounded-md opacity-0 group-hover:opacity-100 hover:bg-error-soft/50 text-ink-muted hover:text-error transition-all"
            >
              <Trash2 className="h-3.5 w-3.5" />
            </button>
          </div>
        );
      })}
    </div>
  );
}
