"use client";

import { useEffect, useRef } from "react";
import { X, CheckCircle, AlertCircle, AlertTriangle, Info } from "lucide-react";
import { useToastStore, Toast } from "@/stores/toast-store";
import { cn } from "@/lib/utils";

const icons = {
  success: CheckCircle,
  error: AlertCircle,
  warning: AlertTriangle,
  info: Info,
};

const styles = {
  success: "border-success bg-success-soft/80",
  error: "border-error bg-error-soft/80",
  warning: "border-warning bg-warning-soft/80",
  info: "border-accent bg-accent-soft/80",
};

const iconColors = {
  success: "text-success",
  error: "text-error",
  warning: "text-warning",
  info: "text-accent",
};

function ToastItem({ toast, onRemove }: { toast: Toast; onRemove: () => void }) {
  const Icon = icons[toast.type];
  const progressRef = useRef<HTMLDivElement>(null);
  const duration = toast.duration ?? 4000;

  useEffect(() => {
    if (progressRef.current) {
      progressRef.current.style.transitionDuration = `${duration}ms`;
      requestAnimationFrame(() => {
        if (progressRef.current) progressRef.current.style.width = "0%";
      });
    }
  }, [duration]);

  return (
    <div
      className={cn(
        "pointer-events-auto flex items-start gap-3 w-full max-w-sm p-4 rounded-xl border backdrop-blur-xl shadow-lg animate-slide-up",
        styles[toast.type]
      )}
    >
      <Icon className={cn("h-5 w-5 flex-shrink-0 mt-0.5", iconColors[toast.type])} />
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-ink">{toast.title}</p>
        {toast.message && (
          <p className="text-xs text-ink-body mt-0.5">{toast.message}</p>
        )}
      </div>
      <button
        onClick={onRemove}
        className="h-6 w-6 rounded-md flex items-center justify-center text-ink-muted hover:text-ink hover:bg-black/5 transition-colors flex-shrink-0"
      >
        <X className="h-3.5 w-3.5" />
      </button>
      {/* Progress bar */}
      <div className="absolute bottom-0 left-0 right-0 h-0.5 bg-black/5 rounded-b-xl overflow-hidden">
        <div
          ref={progressRef}
          className="h-full bg-current opacity-30 transition-[width] ease-linear"
          style={{ width: "100%" }}
        />
      </div>
    </div>
  );
}

export function ToastProvider() {
  const toasts = useToastStore((s) => s.toasts);
  const removeToast = useToastStore((s) => s.removeToast);

  if (toasts.length === 0) return null;

  return (
    <div className="fixed bottom-6 right-6 z-50 flex flex-col gap-2 pointer-events-none">
      {toasts.map((t) => (
        <ToastItem key={t.id} toast={t} onRemove={() => removeToast(t.id)} />
      ))}
    </div>
  );
}
