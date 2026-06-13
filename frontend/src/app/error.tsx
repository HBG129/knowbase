"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import { AlertCircle, RefreshCw, Home } from "lucide-react";

export default function ErrorPage({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const router = useRouter();

  useEffect(() => {
    console.error("Page error:", error);
  }, [error]);

  return (
    <div className="min-h-screen flex items-center justify-center bg-canvas px-6">
      <div className="flex flex-col items-center text-center max-w-md">
        <div className="h-14 w-14 rounded-2xl bg-error-soft flex items-center justify-center mb-6">
          <AlertCircle className="h-7 w-7 text-error" />
        </div>
        <h1 className="h3 text-ink mb-2">Something went wrong</h1>
        <p className="body-sm text-ink-muted mb-8">
          {error.message || "An unexpected error occurred. Please try again."}
        </p>
        <div className="flex items-center gap-3">
          <button
            onClick={() => reset()}
            className="inline-flex items-center gap-2 h-10 px-5 rounded-lg bg-ink text-canvas text-sm font-medium hover:bg-ink-soft transition-all active:scale-[0.98]"
          >
            <RefreshCw className="h-4 w-4" />
            Try again
          </button>
          <button
            onClick={() => { window.location.href = "/"; }}
            className="inline-flex items-center gap-2 h-10 px-5 rounded-lg border border-hairline text-ink-body text-sm font-medium hover:bg-canvas-softer transition-all"
          >
            <Home className="h-4 w-4" />
            Go Home
          </button>
        </div>
      </div>
    </div>
  );
}
