import * as React from "react";
import { cn } from "@/lib/utils";

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
}

const Input = React.forwardRef<HTMLInputElement, InputProps>(
  ({ className, label, error, id, ...props }, ref) => {
    return (
      <div className="space-y-1.5">
        {label && (
          <label htmlFor={id} className="block text-sm font-medium text-ink-soft">
            {label}
          </label>
        )}
        <input
          ref={ref}
          id={id}
          className={cn(
            "w-full h-10 px-3.5 rounded-lg border bg-canvas text-ink text-sm placeholder:text-ink-placeholder",
            "transition-all duration-150",
            "focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10",
            error ? "border-error focus:border-error focus:ring-error/10" : "border-hairline",
            "disabled:opacity-50 disabled:bg-canvas-soft",
            className
          )}
          {...props}
        />
        {error && <p className="text-xs text-error">{error}</p>}
      </div>
    );
  }
);
Input.displayName = "Input";

export { Input };
export type { InputProps };
