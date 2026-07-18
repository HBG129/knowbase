"use client";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/auth-store";
import { BookOpen, LogOut } from "lucide-react";
import { useI18nStore } from "@/stores/i18n-store";

export function TopNav() {
  const router = useRouter();
  const user = useAuthStore((s) => s.user);
  const t = useI18nStore((s) => s.t);

  return (
    <nav className="sticky top-0 z-40 border-b border-border bg-surface/80 backdrop-blur-md">
      <div className="mx-auto flex h-14 max-w-5xl items-center justify-between px-8">
        <button onClick={() => router.push("/")} className="flex items-center gap-2 font-semibold text-fg-primary hover:text-accent transition-colors">
          <BookOpen className="h-5 w-5 text-accent" />
          <span className="text-lg">KnowBase</span>
        </button>
        <div className="flex items-center gap-4">
          <span className="text-sm text-fg-muted">{user?.email}</span>
          <button
            onClick={() => useAuthStore.getState().logout()}
            className="inline-flex items-center gap-1.5 rounded-lg border border-border px-3 py-1.5 text-sm text-fg-secondary hover:border-danger hover:text-danger transition-colors"
          >
            <LogOut className="h-3.5 w-3.5" /> {t("nav.signOut")}
          </button>
        </div>
      </div>
    </nav>
  );
}
