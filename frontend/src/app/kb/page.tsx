"use client";

import { useEffect, useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/auth-store";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { DocumentUpload } from "@/components/kb/document-upload";
import { DocumentList } from "@/components/kb/document-list";
import { AnalysisPanel } from "@/components/kb/analysis-panel";
import { BarChart3, BookOpen, MessageSquare, Trash2, ArrowLeft, Settings, FileText, Upload } from "lucide-react";
import { api } from "@/lib/api";
import { kbChatPath } from "@/lib/routes";
import { useI18nStore } from "@/stores/i18n-store";
import { formatDate } from "@/lib/utils";

interface KBInfo { id: string; name: string; description: string | null; owner_id: string; created_at: string; updated_at: string; }

export default function KBDetailPage() {
  const router = useRouter();
  const { user } = useAuthStore();
  const { lang, t } = useI18nStore();
  const [id, setId] = useState<string | null>(null);
  const [kb, setKb] = useState<KBInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [tab, setTab] = useState<"documents" | "analysis" | "settings">("documents");

  useEffect(() => {
    setId(new URLSearchParams(window.location.search).get("id") || "");
  }, []);

  const fetchKB = useCallback(async () => {
    if (!id) return;
    try {
      const data = await api.get<KBInfo>("/api/kb/" + id);
      setKb(data);
    } catch (e: any) { } finally { setLoading(false); }
  }, [id]);

  useEffect(() => { if (user) fetchKB(); }, [user, fetchKB]);

  if (id === null) return <div className="flex items-center justify-center h-full py-32"><div className="h-8 w-8 animate-spin rounded-full border-2 border-ink border-t-transparent" /></div>;
  if (!id) return <div className="max-w-5xl mx-auto px-8 py-8"><button onClick={() => router.push("/")} className="inline-flex items-center gap-1.5 text-sm text-ink-muted hover:text-ink transition-colors"><ArrowLeft className="h-3.5 w-3.5" /> {t("kb.backToKbs")}</button></div>;
  if (loading) return <div className="flex items-center justify-center h-full py-32"><div className="h-8 w-8 animate-spin rounded-full border-2 border-ink border-t-transparent" /></div>;
  if (!kb) return null;

  return (
    <div className="max-w-5xl mx-auto px-8 py-8 space-y-6 animate-fade-in">
      <button onClick={() => router.push("/")} className="inline-flex items-center gap-1.5 text-sm text-ink-muted hover:text-ink transition-colors mb-4"><ArrowLeft className="h-3.5 w-3.5" /> {t("kb.backToKbs")}</button>

      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="flex min-w-0 items-start gap-4">
          <div className="h-12 w-12 rounded-xl bg-accent-soft flex items-center justify-center"><BookOpen className="h-6 w-6 text-accent" /></div>
          <div>
            <h1 className="h3 text-ink">{kb.name}</h1>
            {kb.description && <p className="body-sm text-ink-body mt-1">{kb.description}</p>}
            <p className="caption text-ink-muted mt-1.5">{t("kb.created", { date: formatDate(kb.created_at, lang) })}</p>
          </div>
        </div>
        <div className="flex w-full items-center gap-2.5 sm:w-auto">
          <Button className="flex-1 whitespace-nowrap sm:flex-none" variant="primary" onClick={() => router.push(kbChatPath(id))}><MessageSquare className="h-4 w-4" /> {t("kb.chat")}</Button>
          <Button variant="secondary" onClick={() => setTab("settings")} aria-label={t("kb.settings")} title={t("kb.settings")}><Settings className="h-4 w-4" /></Button>
        </div>
      </div>

      <div className="flex gap-1 p-1 bg-canvas-soft rounded-xl w-fit">
        {[{ id: "documents" as const, label: t("kb.documents"), icon: FileText }, { id: "analysis" as const, label: t("kb.analysis"), icon: BarChart3 }, { id: "settings" as const, label: t("kb.settings"), icon: Settings }].map((item) => (
          <button key={item.id} onClick={() => setTab(item.id)} className={"inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all " + (tab === item.id ? "bg-canvas text-ink shadow-sm" : "text-ink-muted hover:text-ink")}><item.icon className="h-4 w-4" /> {item.label}</button>
        ))}
      </div>

      {tab === "documents" && (
        <div className="space-y-6">
          <Card variant="default" padding="none">
            <div className="p-6"><h2 className="text-base font-semibold text-ink flex items-center gap-2 mb-4"><Upload className="h-4 w-4 text-ink-muted" /> {t("kb.uploadDocs")}</h2><DocumentUpload kbId={id} onUploadComplete={fetchKB} /></div>
          </Card>
          <Card variant="default" padding="none">
            <div className="p-6 pb-4 border-b border-hairline"><h2 className="text-base font-semibold text-ink flex items-center gap-2"><FileText className="h-4 w-4 text-ink-muted" /> {t("kb.allDocs")}</h2></div>
            <div className="p-3"><DocumentList kbId={id} /></div>
          </Card>
        </div>
      )}

      {tab === "analysis" && <AnalysisPanel kbId={id} />}

      {tab === "settings" && (
        <Card variant="default" padding="lg">
          <h2 className="text-base font-semibold text-ink mb-4">{t("kb.settingsTitle")}</h2>
          <div className="space-y-4">
            <div><label className="block text-sm font-medium text-ink-soft mb-1.5">{t("common.name")}</label><input type="text" defaultValue={kb.name} className="w-full h-10 px-3.5 rounded-lg border border-hairline bg-canvas text-ink text-sm focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10" /></div>
            <div><label className="block text-sm font-medium text-ink-soft mb-1.5">{t("common.description")}</label><textarea defaultValue={kb.description || ""} rows={3} className="w-full px-3.5 py-2.5 rounded-lg border border-hairline bg-canvas text-ink text-sm focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10 resize-none" /></div>
            <Button variant="primary" size="sm">{t("kb.saveSettings")}</Button>
          </div>
        </Card>
      )}
    </div>
  );
}
