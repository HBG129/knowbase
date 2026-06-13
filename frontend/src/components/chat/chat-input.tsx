"use client";

import { useState, useRef, useEffect } from "react";
import { Send, Loader2, Square } from "lucide-react";
import { cn } from "@/lib/utils";

interface ChatInputProps {
  onSend: (message: string) => void;
  disabled?: boolean;
  placeholder?: string;
  onStop?: () => void;
  isStreaming?: boolean;
}

export function ChatInput({
  onSend, disabled, placeholder = "Ask anything about your knowledge base\u2026",
  onStop, isStreaming,
}: ChatInputProps) {
  const [value, setValue] = useState("");
  const textareaRef = useRef<HTMLTextAreaElement>(null);

  useEffect(() => {
    if (textareaRef.current) {
      textareaRef.current.style.height = "auto";
      textareaRef.current.style.height = `${Math.min(textareaRef.current.scrollHeight, 160)}px`;
    }
  }, [value]);

  const handleSend = () => {
    const trimmed = value.trim();
    if (!trimmed || disabled) return;
    onSend(trimmed);
    setValue("");
  };

  const handleKeyDown = (e: React.KeyboardEvent) => {
    if (e.key === "Enter" && !e.shiftKey) {
      e.preventDefault();
      handleSend();
    }
  };

  return (
    <div className="border-t border-hairline bg-canvas p-4">
      <div className={cn(
        "flex items-end gap-3 p-3 rounded-2xl bg-canvas-soft border transition-all duration-200",
        disabled
          ? "border-hairline opacity-60"
          : "border-hairline hover:border-hairline-strong focus-within:border-hairline-focus focus-within:ring-2 focus-within:ring-accent/10"
      )}>
        <textarea
          ref={textareaRef}
          value={value}
          onChange={(e) => setValue(e.target.value)}
          onKeyDown={handleKeyDown}
          placeholder={placeholder}
          disabled={disabled && !isStreaming}
          rows={1}
          className="flex-1 bg-transparent border-0 outline-none resize-none text-sm text-ink placeholder:text-ink-placeholder py-1 max-h-40"
        />
        {isStreaming ? (
          <button
            onClick={onStop}
            className="h-9 w-9 rounded-xl flex items-center justify-center transition-all duration-150 flex-shrink-0 bg-error text-canvas hover:bg-error/90 active:scale-95"
            title="Stop generating"
          >
            <Square className="h-3.5 w-3.5" />
          </button>
        ) : (
          <button
            onClick={handleSend}
            disabled={!value.trim() || disabled}
            className={cn(
              "h-9 w-9 rounded-xl flex items-center justify-center transition-all duration-150 flex-shrink-0",
              value.trim() && !disabled
                ? "bg-ink text-canvas hover:bg-ink-soft active:scale-95"
                : "bg-canvas-softer text-ink-muted cursor-not-allowed"
            )}
          >
            {disabled ? (
              <Loader2 className="h-4 w-4 animate-spin" />
            ) : (
              <Send className="h-4 w-4" />
            )}
          </button>
        )}
      </div>
      <p className="text-[11px] text-ink-muted text-center mt-2">
        Press Enter to send, Shift+Enter for new line
      </p>
    </div>
  );
}
