"use client";

import { useState, useEffect } from "react";
import { createPortal } from "react-dom";
import { useRouter } from "next/navigation";
import { Plus, X, Library } from "lucide-react";
import { useKBStore } from "@/stores/kb-store";
import { Button } from "@/components/ui/button";
import { kbDetailPath } from "@/lib/routes";
import { useI18nStore } from "@/stores/i18n-store";

interface KBCreateDialogProps {
  children?: React.ReactNode;
}

export function KBCreateDialog({ children }: KBCreateDialogProps) {
  const router = useRouter();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [desc, setDesc] = useState("");
  const [loading, setLoading] = useState(false);
  const [mounted, setMounted] = useState(false);
  const fetchKBs = useKBStore((s) => s.fetchKBs);
  const createKB = useKBStore((s) => s.createKB);
  const { t } = useI18nStore();

  useEffect(() => {
    setMounted(true);
  }, []);

  useEffect(() => {
    function onKeyDown(e: KeyboardEvent) {
      if (e.key === "Escape") setOpen(false);
    }

    if (open) document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [open]);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    if (!name.trim()) return;
    setLoading(true);
    const kb = await createKB(name.trim(), desc.trim() || undefined);
    await fetchKBs();
    setName("");
    setDesc("");
    setLoading(false);
    setOpen(false);
    router.push(kbDetailPath(kb.id));
  }

  return (
    <div className="inline-block">
      {children ? (
        <div onClick={() => setOpen(true)}>{children}</div>
      ) : (
        <Button variant="primary" onClick={() => setOpen(true)}>
          <Plus className="h-4 w-4" /> {t("kb.newKb")}
        </Button>
      )}

      {mounted &&
        open &&
        createPortal(
          <div
            className="fixed inset-0 z-[100] flex items-center justify-center bg-ink/45 px-4 py-6 backdrop-blur-sm"
            onMouseDown={() => setOpen(false)}
          >
            <div
              className="w-full max-w-md rounded-2xl border border-hairline bg-canvas p-6 shadow-2xl animate-scale-in"
              role="dialog"
              aria-modal="true"
              aria-labelledby="kb-create-dialog-title"
              onMouseDown={(e) => e.stopPropagation()}
            >
              <div className="flex items-center justify-between mb-5">
                <h3
                  id="kb-create-dialog-title"
                  className="text-base font-semibold text-ink flex items-center gap-2"
                >
                  <Library className="h-4 w-4 text-accent" /> {t("kb.createKb")}
                </h3>
                <button
                  onClick={() => setOpen(false)}
                  aria-label={t("common.close")}
                  title={t("common.close")}
                  className="p-1.5 rounded-lg hover:bg-canvas-soft transition-colors"
                >
                  <X className="h-4 w-4 text-ink-muted" />
                </button>
              </div>
              <form onSubmit={submit} className="space-y-4">
                <div>
                  <label className="block text-sm font-medium text-ink-soft mb-1.5">
                    {t("common.name")}
                  </label>
                  <input
                    value={name}
                    onChange={(e) => setName(e.target.value)}
                    required
                    autoFocus
                    className="w-full h-10 px-3.5 rounded-lg border border-hairline bg-canvas text-ink text-sm focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10 placeholder:text-ink-placeholder"
                    placeholder={t("kb.namePlaceholder")}
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-ink-soft mb-1.5">
                    {t("kb.descriptionOptional")}
                  </label>
                  <textarea
                    value={desc}
                    onChange={(e) => setDesc(e.target.value)}
                    rows={2}
                    className="w-full px-3.5 py-2.5 rounded-lg border border-hairline bg-canvas text-ink text-sm focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10 resize-none placeholder:text-ink-placeholder"
                    placeholder={t("kb.descriptionPlaceholder")}
                  />
                </div>
                <Button type="submit" loading={loading} className="w-full">
                  {loading ? t("kb.creating") : t("kb.createKb")}
                </Button>
              </form>
            </div>
          </div>,
          document.body
        )}
    </div>
  );
}
