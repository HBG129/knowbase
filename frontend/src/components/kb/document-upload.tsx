"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Upload, File, FileText, X, Loader2, CheckCircle2, AlertCircle, MessageSquare } from "lucide-react";
import { cn } from "@/lib/utils";
import { Badge } from "@/components/ui/badge";
import { apiPostForm } from "@/lib/api";

interface UploadingFile {
  name: string;
  progress: number;
  status: "uploading" | "processing" | "done" | "error";
  error?: string;
}

interface DocumentUploadProps {
  kbId: string;
  onUploadComplete?: () => void;
}

const supportedTypes = ["PDF", "DOCX", "DOC", "MD", "TXT", "CSV"];

export function DocumentUpload({ kbId, onUploadComplete }: DocumentUploadProps) {
  const router = useRouter();
  const [dragOver, setDragOver] = useState(false);
  const [files, setFiles] = useState<UploadingFile[]>([]);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    setDragOver(false);
    const dropped = Array.from(e.dataTransfer.files);
    processFiles(dropped);
  }, [kbId]);

  const handleSelect = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      processFiles(Array.from(e.target.files));
    }
  };

  const processFiles = async (fileList: File[]) => {
    const newFiles: UploadingFile[] = fileList.map((f) => ({
      name: f.name,
      progress: 0,
      status: "uploading" as const,
    }));
    setFiles((prev) => [...prev, ...newFiles]);

    for (const file of fileList) {
      const formData = new FormData();
      formData.append("file", file);

      try {
        setFiles((prev) => prev.map((f) => (f.name === file.name ? { ...f, status: "uploading" } : f)));
        const data = await apiPostForm<{ id: string; status: string; error_message?: string }>(
          `/api/kb/${kbId}/documents`,
          formData
        );
        if (data.status === "completed") {
          setFiles((prev) => prev.map((f) => (f.name === file.name ? { ...f, status: "done" } : f)));
        } else if (data.status === "failed") {
          setFiles((prev) => prev.map((f) => (f.name === file.name ? { ...f, status: "error", error: data.error_message } : f)));
        } else {
          setFiles((prev) => prev.map((f) => (f.name === file.name ? { ...f, status: "processing" } : f)));
        }
      } catch (err: any) {
        setFiles((prev) => prev.map((f) => (f.name === file.name ? { ...f, status: "error", error: err.message } : f)));
      }
    }
    onUploadComplete?.();
  };

  return (
    <div className="space-y-4">
      {/* Drop Zone */}
      <div
        onDragOver={(e) => { e.preventDefault(); setDragOver(true); }}
        onDragLeave={() => setDragOver(false)}
        onDrop={handleDrop}
        className={cn(
          "relative border-2 border-dashed rounded-2xl p-10 text-center transition-all duration-200 cursor-pointer",
          dragOver
            ? "border-accent bg-accent-soft/30 scale-[1.01]"
            : "border-hairline bg-canvas-soft/50 hover:border-hairline-strong hover:bg-canvas-soft"
        )}
      >
        <input
          type="file"
          multiple
          onChange={handleSelect}
          className="absolute inset-0 opacity-0 cursor-pointer"
          accept=".pdf,.docx,.doc,.md,.txt,.csv"
        />
        <div className="mx-auto mb-4 flex h-12 w-12 items-center justify-center rounded-xl border border-hairline bg-canvas">
          <Upload className="h-6 w-6 text-accent" />
        </div>
        <p className="text-sm font-medium text-ink">Drop files here or click to upload</p>
        <p className="text-xs text-ink-muted mt-1">PDF, Word, Markdown, TXT, CSV — up to 50MB</p>
        <div className="mt-5 flex flex-wrap justify-center gap-2">
          {supportedTypes.map((type) => (
            <span
              key={type}
              className="inline-flex items-center gap-1.5 rounded-md border border-hairline bg-canvas px-2.5 py-1 text-xs font-medium text-ink-muted"
            >
              <FileText className="h-3.5 w-3.5 text-accent" />
              {type}
            </span>
          ))}
        </div>
      </div>

      {/* File List */}
      {files.length > 0 && (
        <div className="space-y-2">
          {files.map((file) => (
            <div
              key={file.name}
              className="flex items-center gap-3 p-3 rounded-lg border border-hairline bg-canvas animate-scale-in"
            >
              <File className="h-5 w-5 text-ink-muted flex-shrink-0" />
              <div className="flex-1 min-w-0">
                <p className="text-sm text-ink truncate">{file.name}</p>
                <div className="flex items-center gap-2 mt-1">
                  {file.status === "uploading" && (
                    <>
                      <div className="flex-1 h-1 bg-canvas-soft rounded-full overflow-hidden">
                        <div className="h-full bg-accent rounded-full animate-pulse" style={{ width: "60%" }} />
                      </div>
                      <Loader2 className="h-3 w-3 text-accent animate-spin flex-shrink-0" />
                    </>
                  )}
                  {file.status === "processing" && (
                    <span className="text-xs text-ink-muted flex items-center gap-1.5">
                      <Loader2 className="h-3 w-3 animate-spin" />
                      Processing…
                    </span>
                  )}
                  {file.status === "done" && (
                    <Badge variant="success">
                      <CheckCircle2 className="h-3 w-3 mr-1" /> Ready
                    </Badge>
                  )}
                  {file.status === "error" && (
                    <span className="text-xs text-error flex items-center gap-1.5">
                      <AlertCircle className="h-3 w-3" />
                      {file.error || "Failed"}
                    </span>
                  )}
                </div>
              </div>
              {file.status !== "uploading" && file.status !== "processing" && (
                <button
                  onClick={() => setFiles((prev) => prev.filter((f) => f.name !== file.name))}
                  className="p-1 rounded hover:bg-canvas-soft"
                >
                  <X className="h-3.5 w-3.5 text-ink-muted" />
                </button>
              )}
            </div>
          ))}
          {(() => {
            const doneCount = files.filter((f) => f.status === "done").length;
            if (doneCount > 0 && !files.some((f) => f.status === "uploading" || f.status === "processing")) {
              return (
                <button
                  onClick={() => router.push("/kb/" + kbId + "/chat")}
                  className="w-full inline-flex items-center justify-center gap-2 h-10 rounded-xl bg-ink text-canvas text-sm font-medium hover:bg-ink-soft transition-all active:scale-[0.98]"
                >
                  <MessageSquare className="h-4 w-4" />
                  Start Chat ({doneCount} doc{doneCount > 1 ? "s" : ""} ready)
                </button>
              );
            }
            return null;
          })()}
        </div>
      )}
    </div>
  );
}
