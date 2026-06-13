import { cn } from "@/lib/utils";

interface SkeletonProps {
  className?: string;
  variant?: "text" | "circular" | "rectangular";
}

export function Skeleton({ className, variant = "rectangular" }: SkeletonProps) {
  const variants = {
    text: "h-4 rounded",
    circular: "rounded-full",
    rectangular: "rounded-lg",
  };

  return (
    <div className={cn("animate-shimmer bg-canvas-soft", variants[variant], className)} />
  );
}

export function SkeletonCard() {
  return (
    <div className="space-y-4 p-6 rounded-xl border border-hairline">
      <Skeleton className="h-6 w-2/3" variant="text" />
      <Skeleton className="h-4 w-full" variant="text" />
      <Skeleton className="h-4 w-4/5" variant="text" />
      <Skeleton className="h-32 w-full" />
    </div>
  );
}
