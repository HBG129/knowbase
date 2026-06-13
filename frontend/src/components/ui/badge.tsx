import { cn } from "@/lib/utils";

interface BadgeProps {
  children: React.ReactNode;
  variant?: "default" | "accent" | "success" | "warning" | "error";
  className?: string;
}

export function Badge({ children, variant = "default", className }: BadgeProps) {
  const variants = {
    default: "bg-canvas-soft text-ink-muted",
    accent: "bg-accent-soft text-accent-deep",
    success: "bg-success-soft text-link",
    warning: "bg-warning-soft text-warning",
    error: "bg-error-soft text-error",
  };

  return (
    <span className={cn("inline-flex items-center px-2 py-0.5 text-xs font-medium rounded-full", variants[variant], className)}>
      {children}
    </span>
  );
}
