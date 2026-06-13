import * as React from "react";
import { cn } from "@/lib/utils";

interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "default" | "glass" | "gradient" | "ghost";
  hover?: boolean;
  padding?: "none" | "sm" | "md" | "lg";
}

const Card = React.forwardRef<HTMLDivElement, CardProps>(
  ({ className, variant = "default", hover = false, padding = "md", children, ...props }, ref) => {
    const variants = {
      default: "bg-canvas border border-hairline shadow-sm",
      glass: "glass",
      gradient: "bg-gradient-card border border-hairline shadow-sm",
      ghost: "bg-transparent",
    };

    const paddings = {
      none: "p-0",
      sm: "p-4",
      md: "p-6",
      lg: "p-8",
    };

    const hoverEffect = hover
      ? "transition-all duration-200 hover:shadow-md hover:-translate-y-0.5 hover:border-hairline-strong"
      : "";

    return (
      <div
        ref={ref}
        className={cn("rounded-xl", variants[variant], paddings[padding], hoverEffect, className)}
        {...props}
      >
        {children}
      </div>
    );
  }
);
Card.displayName = "Card";

export { Card };
export type { CardProps };
