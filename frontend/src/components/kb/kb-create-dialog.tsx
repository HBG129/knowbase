"use client";

import { useState, useRef, useEffect } from "react";
import { useRouter } from "next/navigation";
import { Plus, X, Library } from "lucide-react";
import { useKBStore } from "@/stores/kb-store";
import { Button } from "@/components/ui/button";
import { kbDetailPath } from "@/lib/routes";

interface KBCreateDialogProps {
  children?: React.ReactNode;
}

export function KBCreateDialog({ children }: KBCreateDialogProps) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [desc, setDesc] = useState("");
  const [loading, setLoading] = useState(false);
  const fetchKBs = useKBStore((s) => s.fetchKBs);
  const createKB = useKBStore((s) => s.createKB);
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    function onClick(e: MouseEvent) { if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false); }
    if (open) document.addEventListener("mousedown", onClick);
    return () => document.removeEventListener("mousedown", onClick);
  }, [open]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    setLoading(true);
    const kb = await createKB(name.trim(), desc.trim() || undefined);
    await fetchKBs();
    setName(""); setDesc(""); setLoading(false); setOpen(false);
    router.push(kbDetailPath(kb.id));
  }

  return (
    <div className="relative inline-block" ref={ref}>
      {children ? (
        <div onClick={() => setOpen(true)}>{children}</div>
      ) : (
        <Button variant="primary" onClick={() => setOpen(true)}>
          <Plus className="h-4 w-4" /> New Knowledge Base
        </Button>
      )}

      {open && (
        <div className="absolute right-0 top-full mt-2 w-96 rounded-2xl glass p-6 shadow-xl z-50 animate-scale-in">
          <div className="flex items-center justify-between mb-5">
            <h3 className="text-base font-semibold text-ink flex items-center gap-2">
              <Library className="h-4 w-4 text-accent" /> Create Knowledge Base
            </h3>
            <button onClick={() => setOpen(false)} className="p-1.5 rounded-lg hover:bg-canvas-soft transition-colors">
              <X className="h-4 w-4 text-ink-muted" />
            </button>
          </div>
          <form onSubmit={submit} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-ink-soft mb-1.5">Name</label>
              <input
                value={name} onChange={(e) => setName(e.target.value)} required autoFocus
                className="w-full h-10 px-3.5 rounded-lg border border-hairline bg-canvas text-ink text-sm focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10 placeholder:text-ink-placeholder"
                placeholder="e.g. Product Documentation"
              />
            </div>
            <div>
              <label className="block text-sm font-medium text-ink-soft mb-1.5">Description (optional)</label>
              <textarea
                value={desc} onChange={(e) => setDesc(e.target.value)} rows={2}
                className="w-full px-3.5 py-2.5 rounded-lg border border-hairline bg-canvas text-ink text-sm focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10 resize-none placeholder:text-ink-placeholder"
                placeholder="A brief description of this knowledge base…"
              />
            </div>
            <Button type="submit" loading={loading} className="w-full">
              {loading ? "Creating…" : "Create Knowledge Base"}
            </Button>
          </form>
        </div>
      )}
    </div>
  );
}
