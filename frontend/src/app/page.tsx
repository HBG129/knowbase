"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useAuthStore } from "@/stores/auth-store";
import { useKBStore } from "@/stores/kb-store";
import { useI18nStore } from "@/stores/i18n-store";
import { KBCard } from "@/components/kb/kb-card";
import { KBCreateDialog } from "@/components/kb/kb-create-dialog";
import { Card } from "@/components/ui/card";
import { Skeleton } from "@/components/ui/skeleton";
import { api } from "@/lib/api";
import { kbChatPath } from "@/lib/routes";
import {
  ArrowRight,
  CircleDot,
  Clock3,
  Database,
  FileText,
  Library,
  MessageSquare,
  Plus,
  Sparkles,
  Upload,
} from "lucide-react";

interface Conversation {
  id: string;
  kb_id: string;
  title: string;
  updated_at: string;
}

interface RecentConversation extends Conversation {
  kb_name: string;
}

export default function Home() {
  const { user } = useAuthStore();
  const { kbs, isLoading: kbsLoading, fetchKBs } = useKBStore();
  const { t } = useI18nStore();
  const [recent, setRecent] = useState<RecentConversation[]>([]);
  const [recentLoading, setRecentLoading] = useState(false);

  useEffect(() => {
    if (user) fetchKBs();
  }, [user, fetchKBs]);

  useEffect(() => {
    let mounted = true;

    async function fetchRecent() {
      if (!user || kbs.length === 0) {
        setRecent([]);
        return;
      }

      setRecentLoading(true);
      try {
        const batches = await Promise.all(
          kbs.slice(0, 6).map(async (kb) => {
            try {
              const conversations = await api.get<Conversation[]>(
                `/api/kb/${kb.id}/conversations`
              );
              return conversations.map((conversation) => ({
                ...conversation,
                kb_name: kb.name,
              }));
            } catch {
              return [];
            }
          })
        );

        if (!mounted) return;
        setRecent(
          batches
            .flat()
            .sort(
              (a, b) =>
                new Date(b.updated_at).getTime() -
                new Date(a.updated_at).getTime()
            )
            .slice(0, 5)
        );
      } finally {
        if (mounted) setRecentLoading(false);
      }
    }

    fetchRecent();
    return () => {
      mounted = false;
    };
  }, [user, kbs]);

  const totals = useMemo(
    () => ({
      kbs: kbs.length,
      docs: kbs.reduce((sum, kb) => sum + (kb.doc_count ?? 0), 0),
      chats: kbs.reduce((sum, kb) => sum + (kb.conversation_count ?? 0), 0),
    }),
    [kbs]
  );

  const nextStep =
    totals.kbs === 0
      ? "Create your first knowledge base"
      : totals.docs === 0
        ? "Upload source documents"
        : totals.chats === 0
          ? "Start your first cited conversation"
          : "Continue from recent conversations";

  return (
    <div className="min-h-screen bg-canvas">
      <section className="relative overflow-hidden border-b border-hairline bg-canvas-soft">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_12%_10%,rgba(var(--accent),0.18),transparent_28%),radial-gradient(circle_at_86%_6%,rgba(0,223,216,0.10),transparent_24%)]" />
        <div className="absolute inset-0 bg-dots opacity-35" />
        <div className="relative mx-auto max-w-6xl px-6 py-8 lg:px-8 lg:py-10">
          <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div className="max-w-2xl">
              <div className="mb-4 inline-flex items-center gap-2 rounded-lg border border-hairline bg-canvas/70 px-3 py-1.5 text-xs font-medium text-ink-muted backdrop-blur">
                <CircleDot className="h-3.5 w-3.5 text-success" />
                Knowledge workspace online
              </div>
              <h1 className="text-4xl font-semibold leading-tight tracking-[-0.035em] text-ink md:text-5xl">
                Build, search, and question your private knowledge base.
              </h1>
              <p className="mt-4 max-w-xl text-sm leading-6 text-ink-body md:text-base">
                A focused workspace for document ingestion, cited answers, and
                reusable knowledge operations.
              </p>
            </div>

            <KBCreateDialog>
              <button className="inline-flex h-11 items-center justify-center gap-2 rounded-lg bg-ink px-5 text-sm font-medium text-canvas transition-all hover:bg-ink-soft active:scale-[0.98]">
                <Plus className="h-4 w-4" />
                {t("home.hero.cta")}
              </button>
            </KBCreateDialog>
          </div>

          <div className="mt-8 grid gap-3 md:grid-cols-3">
            {[
              { label: t("home.stats.kbs"), value: totals.kbs, icon: Library },
              { label: t("home.stats.docs"), value: totals.docs, icon: FileText },
              { label: t("home.stats.chats"), value: totals.chats, icon: MessageSquare },
            ].map((item) => (
              <div
                key={item.label}
                className="rounded-xl border border-hairline bg-canvas/70 p-4 backdrop-blur"
              >
                <div className="flex items-center justify-between">
                  <p className="text-sm text-ink-muted">{item.label}</p>
                  <item.icon className="h-4 w-4 text-accent" />
                </div>
                <p className="mt-3 font-mono text-3xl font-semibold tabular-nums text-ink">
                  {item.value}
                </p>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="mx-auto grid max-w-6xl gap-6 px-6 py-8 lg:grid-cols-[1fr_320px] lg:px-8">
        <div className="min-w-0">
          <div className="mb-5 flex items-center justify-between gap-4">
            <div>
              <h2 className="text-xl font-semibold tracking-[-0.02em] text-ink">
                {t("home.yourKbs")}
              </h2>
              <p className="mt-1 text-sm text-ink-muted">{nextStep}</p>
            </div>
            <KBCreateDialog>
              <button className="inline-flex h-10 items-center gap-2 rounded-lg border border-hairline bg-canvas px-4 text-sm font-medium text-ink-soft transition-all hover:border-hairline-strong hover:bg-canvas-soft active:scale-[0.98]">
                <Plus className="h-4 w-4" />
                {t("home.newKb")}
              </button>
            </KBCreateDialog>
          </div>

          {kbsLoading ? (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              {[1, 2, 3].map((i) => (
                <div
                  key={i}
                  className="space-y-3 rounded-xl border border-hairline p-6"
                >
                  <Skeleton className="h-5 w-3/4" variant="text" />
                  <Skeleton className="h-4 w-full" variant="text" />
                  <Skeleton className="h-4 w-1/2" variant="text" />
                </div>
              ))}
            </div>
          ) : kbs.length === 0 ? (
            <Card
              variant="ghost"
              padding="none"
              className="overflow-hidden border border-dashed border-hairline-strong bg-canvas-soft/60"
            >
              <div className="grid gap-6 p-6 md:grid-cols-[1fr_240px] md:p-8">
                <div>
                  <div className="mb-4 flex h-12 w-12 items-center justify-center rounded-xl border border-hairline bg-canvas">
                    <Database className="h-6 w-6 text-accent" />
                  </div>
                  <h3 className="text-xl font-semibold tracking-[-0.02em] text-ink">
                    {t("home.noKbs")}
                  </h3>
                  <p className="mt-2 max-w-lg text-sm leading-6 text-ink-body">
                    Create a workspace, upload source files, then ask questions
                    with traceable citations. The first knowledge base usually
                    takes less than a minute to set up.
                  </p>
                  <KBCreateDialog>
                    <button className="mt-6 inline-flex h-10 items-center gap-2 rounded-lg bg-ink px-4 text-sm font-medium text-canvas transition-all hover:bg-ink-soft active:scale-[0.98]">
                      <Plus className="h-4 w-4" />
                      {t("home.createFirst")}
                    </button>
                  </KBCreateDialog>
                </div>

                <div className="space-y-3 rounded-xl border border-hairline bg-canvas p-4">
                  {[
                    { icon: Library, label: "Create KB" },
                    { icon: Upload, label: "Upload files" },
                    { icon: MessageSquare, label: "Ask with sources" },
                  ].map((step, index) => (
                    <div key={step.label} className="flex items-center gap-3">
                      <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-canvas-soft">
                        <step.icon className="h-4 w-4 text-accent" />
                      </div>
                      <div>
                        <p className="text-sm font-medium text-ink">{step.label}</p>
                        <p className="text-xs text-ink-muted">Step {index + 1}</p>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            </Card>
          ) : (
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-3">
              {kbs.map((kb) => (
                <KBCard
                  key={kb.id}
                  id={kb.id}
                  name={kb.name}
                  description={kb.description}
                  doc_count={kb.doc_count ?? 0}
                  conversation_count={kb.conversation_count ?? 0}
                />
              ))}
            </div>
          )}
        </div>

        <aside className="space-y-4">
          <Card variant="default" padding="md" className="bg-canvas-soft/70">
            <div className="flex items-center gap-2">
              <Sparkles className="h-4 w-4 text-accent" />
              <h2 className="text-sm font-semibold text-ink">Activation path</h2>
            </div>
            <div className="mt-4 space-y-3">
              {[
                {
                  done: totals.kbs > 0,
                  label: "Create a knowledge base",
                  helper: "Group documents by project or team.",
                },
                {
                  done: totals.docs > 0,
                  label: "Upload source documents",
                  helper: "PDF, Word, Markdown, TXT, and CSV.",
                },
                {
                  done: totals.chats > 0,
                  label: "Start a cited conversation",
                  helper: "Answers stay connected to sources.",
                },
              ].map((step) => (
                <div key={step.label} className="flex gap-3">
                  <div
                    className={
                      "mt-0.5 h-2.5 w-2.5 rounded-full border " +
                      (step.done
                        ? "border-success bg-success"
                        : "border-hairline-strong bg-canvas")
                    }
                  />
                  <div>
                    <p className="text-sm font-medium text-ink">{step.label}</p>
                    <p className="text-xs leading-5 text-ink-muted">{step.helper}</p>
                  </div>
                </div>
              ))}
            </div>
          </Card>

          <Card variant="default" padding="none" className="overflow-hidden">
            <div className="flex items-center justify-between border-b border-hairline p-4">
              <div className="flex items-center gap-2">
                <Clock3 className="h-4 w-4 text-accent" />
                <h2 className="text-sm font-semibold text-ink">Recent conversations</h2>
              </div>
            </div>
            <div className="p-2">
              {recentLoading ? (
                <div className="space-y-2 p-2">
                  {[1, 2, 3].map((i) => (
                    <Skeleton key={i} className="h-11 w-full" />
                  ))}
                </div>
              ) : recent.length === 0 ? (
                <div className="p-4 text-sm leading-6 text-ink-muted">
                  Conversations will appear here after you ask your first
                  question.
                </div>
              ) : (
                <div className="space-y-1">
                  {recent.map((conversation) => (
                    <Link
                      key={conversation.id}
                      href={kbChatPath(conversation.kb_id)}
                      className="group flex items-center gap-3 rounded-lg px-3 py-2.5 transition-colors hover:bg-canvas-soft"
                    >
                      <MessageSquare className="h-4 w-4 shrink-0 text-ink-muted group-hover:text-accent" />
                      <div className="min-w-0 flex-1">
                        <p className="truncate text-sm font-medium text-ink">
                          {conversation.title}
                        </p>
                        <p className="truncate text-xs text-ink-muted">
                          {conversation.kb_name}
                        </p>
                      </div>
                      <ArrowRight className="h-3.5 w-3.5 text-ink-muted opacity-0 transition-opacity group-hover:opacity-100" />
                    </Link>
                  ))}
                </div>
              )}
            </div>
          </Card>
        </aside>
      </section>
    </div>
  );
}
