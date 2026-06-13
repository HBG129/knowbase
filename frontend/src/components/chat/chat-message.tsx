"use client";

import { cn } from "@/lib/utils";
import ReactMarkdown from "react-markdown";
import { User, Bot, Quote } from "lucide-react";

interface ChatMessageProps {
  role: "user" | "assistant";
  content: string;
  citations?: { doc_id: string; chunk_index: number; snippet: string; doc_filename?: string }[];
  onCitationClick?: (docId: string, chunkIndex: number) => void;
  activeCitation?: { docId: string; chunkIndex: number } | null;
  messageId?: string;
}

export function ChatMessage({ role, content, citations, onCitationClick, activeCitation, messageId }: ChatMessageProps) {
  const isUser = role === "user";
  const isStreaming = role === "assistant" && !content;
  const hasActiveCite = activeCitation && citations?.some(c => c.doc_id === activeCitation.docId && c.chunk_index === activeCitation.chunkIndex);

  return (
    <div className={cn("flex gap-3 py-5 animate-slide-up", isUser ? "justify-end" : "justify-start", hasActiveCite && "animate-scale-in")} id={messageId ? `msg-${messageId}` : undefined}>
      {!isUser && (
        <div className="h-8 w-8 rounded-lg bg-ink flex items-center justify-center flex-shrink-0 mt-0.5">
          <Bot className="h-4 w-4 text-canvas" />
        </div>
      )}

      <div className={cn("max-w-[72%] space-y-2", isUser && "order-first")}>
        {/* Message Bubble */}
        <div
          className={cn(
            "rounded-2xl px-4 py-3",
            isUser
              ? "bg-ink text-canvas rounded-tr-md"
              : cn(
                  "bg-canvas-soft text-ink-body rounded-tl-md border transition-all duration-300",
                  hasActiveCite ? "border-accent shadow-lg shadow-accent/10 ring-2 ring-accent/20" : "border-hairline"
                )
          )}
        >
          {isUser ? (
            <p className="text-sm leading-relaxed whitespace-pre-wrap">{content}</p>
          ) : isStreaming ? (
            <div className="flex items-center gap-1.5 py-1">
              <span className="h-2 w-2 bg-ink-muted rounded-full animate-bounce [animation-delay:-0.3s]" />
              <span className="h-2 w-2 bg-ink-muted rounded-full animate-bounce [animation-delay:-0.15s]" />
              <span className="h-2 w-2 bg-ink-muted rounded-full animate-bounce" />
            </div>
          ) : (
            <div className="prose-custom text-sm">
              <ReactMarkdown>{content}</ReactMarkdown>
            </div>
          )}
        </div>

        {/* Citations */}
        {citations && citations.length > 0 && (
          <div className="space-y-1 pl-1">
            <p className="text-xs font-medium text-ink-muted flex items-center gap-1.5">
              <Quote className="h-3 w-3" />
              Sources
            </p>
            {citations.map((cite, i) => (
              <button
                key={`${cite.doc_id}-${cite.chunk_index}`}
                onClick={() => onCitationClick?.(cite.doc_id, cite.chunk_index)}
                className="block w-full text-left text-xs text-link hover:text-link-deep hover:underline transition-colors px-2 py-1 rounded-md hover:bg-accent-soft/50"
              >
                Chunk {cite.chunk_index} — {cite.snippet.slice(0, 80)}…
              </button>
            ))}
          </div>
        )}
      </div>

      {isUser && (
        <div className="h-8 w-8 rounded-lg bg-accent-soft flex items-center justify-center flex-shrink-0 mt-0.5">
          <User className="h-4 w-4 text-accent" />
        </div>
      )}
    </div>
  );
}
