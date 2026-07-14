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

interface KBInfo { id: string; name: string; description: string | null; owner_id: string; created_at: string; updated_at: string; }

export default function KBDetailPage() {
  const router = useRouter();
  const { user } = useAuthStore();
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
  if (!id) return <div className="max-w-5xl mx-auto px-8 py-8"><button onClick={() => router.push("/")} className="inline-flex items-center gap-1.5 text-sm text-ink-muted hover:text-ink transition-colors"><ArrowLeft className="h-3.5 w-3.5" /> Back to Knowledge Bases</button></div>;
  if (loading) return <div className="flex items-center justify-center h-full py-32"><div className="h-8 w-8 animate-spin rounded-full border-2 border-ink border-t-transparent" /></div>;
  if (!kb) return null;

  return (
    <div className="max-w-5xl mx-auto px-8 py-8 space-y-6 animate-fade-in">
      <button onClick={() => router.push("/")} className="inline-flex items-center gap-1.5 text-sm text-ink-muted hover:text-ink transition-colors mb-4"><ArrowLeft className="h-3.5 w-3.5" /> Back to Knowledge Bases</button>

      <div className="flex items-start justify-between">
        <div className="flex items-start gap-4">
          <div className="h-12 w-12 rounded-xl bg-accent-soft flex items-center justify-center"><BookOpen className="h-6 w-6 text-accent" /></div>
          <div>
            <h1 className="h3 text-ink">{kb.name}</h1>
            {kb.description && <p className="body-sm text-ink-body mt-1">{kb.description}</p>}
            <p className="caption text-ink-muted mt-1.5">Created {new Date(kb.created_at).toLocaleDateString()}</p>
          </div>
        </div>
        <div className="flex items-center gap-2.5">
          <Button variant="primary" onClick={() => router.push(kbChatPath(id))}><MessageSquare className="h-4 w-4" /> Chat</Button>
          <Button variant="secondary" onClick={() => setTab("settings")}><Settings className="h-4 w-4" /></Button>
        </div>
      </div>

      <div className="flex gap-1 p-1 bg-canvas-soft rounded-xl w-fit">
        {[{ id: "documents" as const, label: "Documents", icon: FileText }, { id: "analysis" as const, label: "Analysis", icon: BarChart3 }, { id: "settings" as const, label: "Settings", icon: Settings }].map((t) => (
          <button key={t.id} onClick={() => setTab(t.id)} className={"inline-flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all " + (tab === t.id ? "bg-canvas text-ink shadow-sm" : "text-ink-muted hover:text-ink")}><t.icon className="h-4 w-4" /> {t.label}</button>
        ))}
      </div>

      {tab === "documents" && (
        <div className="space-y-6">
          <Card variant="default" padding="none">
            <div className="p-6"><h2 className="text-base font-semibold text-ink flex items-center gap-2 mb-4"><Upload className="h-4 w-4 text-ink-muted" /> Upload Documents</h2><DocumentUpload kbId={id} onUploadComplete={fetchKB} /></div>
          </Card>
          <Card variant="default" padding="none">
            <div className="p-6 pb-4 border-b border-hairline"><h2 className="text-base font-semibold text-ink flex items-center gap-2"><FileText className="h-4 w-4 text-ink-muted" /> All Documents</h2></div>
            <div className="p-3"><DocumentList kbId={id} /></div>
          </Card>
        </div>
      )}

      {tab === "analysis" && <AnalysisPanel kbId={id} />}

      {tab === "settings" && (
        <Card variant="default" padding="lg">
          <h2 className="text-base font-semibold text-ink mb-4">Knowledge Base Settings</h2>
          <div className="space-y-4">
            <div><label className="block text-sm font-medium text-ink-soft mb-1.5">Name</label><input type="text" defaultValue={kb.name} className="w-full h-10 px-3.5 rounded-lg border border-hairline bg-canvas text-ink text-sm focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10" /></div>
            <div><label className="block text-sm font-medium text-ink-soft mb-1.5">Description</label><textarea defaultValue={kb.description || ""} rows={3} className="w-full px-3.5 py-2.5 rounded-lg border border-hairline bg-canvas text-ink text-sm focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10 resize-none" /></div>
            <Button variant="primary" size="sm">Save Changes</Button>
          </div>
        </Card>
      )}
    </div>
  );
}
