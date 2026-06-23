"use client";

import Link from "next/link";
import { useState } from "react";
import { BookOpen, Trash2, X } from "lucide-react";
import { useKBStore } from "@/stores/kb-store";
import { kbDetailPath } from "@/lib/routes";

interface Props { id: string; name: string; description: string | null; doc_count?: number; conversation_count?: number; }

export function KBCard({ id, name, description, doc_count = 0, conversation_count = 0 }: Props) {
  const deleteKB = useKBStore((s) => s.deleteKB);
  const [confirming, setConfirming] = useState(false);

  async function handleDelete(e: React.MouseEvent) {
    e.preventDefault(); e.stopPropagation();
    if (!confirming) {
      setConfirming(true);
      return;
    }
    await deleteKB(id);
  }

  return (
    <Link
      href={kbDetailPath(id)}
      className="group relative flex flex-col rounded-xl border border-hairline bg-canvas p-6 hover:border-hairline-strong hover:shadow-md transition-all duration-200 hover:-translate-y-0.5"
    >
      <div className="mb-3 h-10 w-10 rounded-lg bg-accent-soft flex items-center justify-center">
        <BookOpen className="h-5 w-5 text-accent" />
      </div>
      <h3 className="text-base font-semibold text-ink group-hover:text-accent transition-colors">{name}</h3>
      {description && <p className="mt-1 text-sm text-ink-body line-clamp-2">{description}</p>}
      <div className="flex items-center gap-1 mt-3 text-xs text-ink-muted group-hover:text-accent transition-colors">
        <span>{doc_count} docs · {conversation_count} chats</span>
      </div>
      {confirming ? (
        <div
          onClick={(e) => { e.preventDefault(); e.stopPropagation(); }}
          className="absolute inset-x-4 bottom-4 rounded-lg border border-error/30 bg-error-soft p-2"
        >
          <p className="mb-2 text-xs font-medium text-error">Delete knowledge base?</p>
          <div className="grid grid-cols-2 gap-2">
            <button
              onClick={(e) => { e.preventDefault(); e.stopPropagation(); setConfirming(false); }}
              className="inline-flex h-7 items-center justify-center gap-1 rounded-md bg-canvas text-xs font-medium text-ink-muted hover:text-ink"
            >
              <X className="h-3 w-3" />
              Cancel
            </button>
            <button
              onClick={handleDelete}
              className="inline-flex h-7 items-center justify-center gap-1 rounded-md bg-error text-xs font-medium text-white hover:opacity-90"
            >
              <Trash2 className="h-3 w-3" />
              Delete
            </button>
          </div>
        </div>
      ) : (
        <button
          onClick={handleDelete}
          className="absolute top-4 right-4 p-1.5 rounded-md text-ink-muted opacity-0 group-hover:opacity-100 hover:bg-error-soft/50 hover:text-error transition-all"
        >
          <Trash2 className="h-4 w-4" />
        </button>
      )}
    </Link>
  );
}
