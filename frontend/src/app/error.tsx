"use client";

import { useEffect } from "react";
import { AlertCircle, RefreshCw, Home } from "lucide-react";
import { useI18nStore } from "@/stores/i18n-store";

export default function ErrorPage({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const t = useI18nStore((state) => state.t);

  useEffect(() => {
    console.error("Page error:", error);
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-canvas px-6">
      <div className="flex flex-col items-center text-center max-w-md">
        <div className="h-14 w-14 rounded-2xl bg-error-soft flex items-center justify-center mb-6">
          <AlertCircle className="h-7 w-7 text-error" />
        </div>
        <h1 className="h3 text-ink mb-2">{t("error.pageTitle")}</h1>
        <p className="body-sm text-ink-muted mb-8">
          {error.message || t("error.pageHint")}
        </p>
        <div className="flex items-center gap-3">
          <button
            onClick={() => reset()}
            className="inline-flex items-center gap-2 h-10 px-5 rounded-lg bg-ink text-canvas text-sm font-medium hover:bg-ink-soft transition-all active:scale-[0.98]"
          >
            <RefreshCw className="h-4 w-4" />
            {t("error.tryAgain")}
          </button>
          <button
            onClick={() => { window.location.href = "/"; }}
            className="inline-flex items-center gap-2 h-10 px-5 rounded-lg border border-hairline text-ink-body text-sm font-medium hover:bg-canvas-softer transition-all"
          >
            <Home className="h-4 w-4" />
            {t("error.goHome")}
          </button>
        </div>
      </div>
    </div>
  );
}
