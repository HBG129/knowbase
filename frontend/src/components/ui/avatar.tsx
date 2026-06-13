import { cn } from "@/lib/utils";

interface AvatarProps {
  src?: string;
  fallback: string;
  size?: "sm" | "md" | "lg";
  className?: string;
}

export function Avatar({ src, fallback, size = "md", className }: AvatarProps) {
  const sizes = {
    sm: "h-7 w-7 text-xs",
    md: "h-9 w-9 text-sm",
    lg: "h-12 w-12 text-base",
  };

  if (src) {
    return (
      <img
        src={src}
        alt={fallback}
        className={cn("rounded-full object-cover ring-2 ring-canvas", sizes[size], className)}
      />
    );
  }

  return (
    <div className={cn(
      "rounded-full bg-accent-soft text-accent font-medium flex items-center justify-center",
      sizes[size],
      className
    )}>
      {fallback.slice(0, 2).toUpperCase()}
    </div>
  );
}
