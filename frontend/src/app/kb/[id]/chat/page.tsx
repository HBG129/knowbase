"use client";

import { useEffect, useState, useRef, useCallback } from "react";
import { useParams, useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/auth-store";
import { ChatMessage } from "@/components/chat/chat-message";
import { ChatInput } from "@/components/chat/chat-input";
import { CitationPanel } from "@/components/chat/citation-panel";
import { ApiKeyDialog } from "@/components/auth/api-key-dialog";
import { ArrowLeft, Plus, MessageSquare, Bot, PanelRightClose, PanelRightOpen, Trash2, Eraser, Upload, AlertTriangle, Key } from "lucide-react";
import { api, apiStream } from "@/lib/api";

interface Citation { doc_id: string; chunk_index: number; snippet: string; }
interface Message {
  id: string; role: string; content: string; citations_json?: string; created_at: string;
}
interface Conversation { id: string; kb_id: string; title: string; created_at: string; updated_at: string; }
interface Document { id: string; status: string; }
type PendingAction =
  | { type: "delete-conversation"; conversationId: string; title: string }
  | { type: "clear-messages" };

function isApiKeyError(message: string) {
  const value = message.toLowerCase();
  return value.includes("api key") && (
    value.includes("no llm") ||
    value.includes("no embedding") ||
    value.includes("configured")
  );
}

function formatChatError(message: string) {
  if (isApiKeyError(message)) {
    return "I cannot answer yet because no model API key is configured. Open API Key Settings, add a provider key, then try again.";
  }
  return "Error: " + message;
}

export default function ChatPage() {
  const { id } = useParams<{ id: string }>();
  const router = useRouter();
  const { user } = useAuthStore();
  const [conversations, setConversations] = useState<Conversation[]>([]);
  const [activeConvId, setActiveConvId] = useState<string | null>(null);
  const [messages, setMessages] = useState<Message[]>([]);
  const [sending, setSending] = useState(false);
  const [streaming, setStreaming] = useState(false);
  const [streamingContent, setStreamingContent] = useState("");
  const [loading, setLoading] = useState(true);
  const [docs, setDocs] = useState<Document[]>([]);
  const [docsLoading, setDocsLoading] = useState(true);
  const [showCitations, setShowCitations] = useState(true);
  const [activeCitation, setActiveCitation] = useState<{ docId: string; chunkIndex: number } | null>(null);
  const [mobilePanel, setMobilePanel] = useState<"chat" | "citations">("chat");
  const [pendingAction, setPendingAction] = useState<PendingAction | null>(null);
  const [apiKeyOpen, setApiKeyOpen] = useState(false);
  const [showApiKeyPrompt, setShowApiKeyPrompt] = useState(false);
  const chatEndRef = useRef<HTMLDivElement>(null);
  const msgRefs = useRef<Map<string, HTMLDivElement>>(new Map());
  const abortRef = useRef<AbortController | null>(null);

  // When citation clicked, scroll to the message that contains it
  function handleCitationClick(docId: string, chunkIndex: number) {
    setActiveCitation({ docId, chunkIndex });
    setMobilePanel("chat"); // switch back to chat on mobile
    // Scroll to message that has this citation
    const targetMsg = messages.find(m => {
      if (!m.citations_json) return false;
      try { return JSON.parse(m.citations_json).some((c: any) => c.doc_id === docId && c.chunk_index === chunkIndex); } catch { return false; }
    });
    if (targetMsg) {
      setTimeout(() => {
        const el = msgRefs.current.get(targetMsg.id);
        el?.scrollIntoView({ behavior: "smooth", block: "center" });
      }, 100);
    } else {
      // scroll to most recent AI message
      const lastAi = [...messages].reverse().find(m => m.role === "assistant");
      if (lastAi) {
        setTimeout(() => {
          const el = msgRefs.current.get(lastAi.id);
          el?.scrollIntoView({ behavior: "smooth", block: "center" });
        }, 100);
      }
    }
    // auto-dismiss highlight after 3s
    setTimeout(() => setActiveCitation(null), 3000);
  }

  const fetchConversations = useCallback(async () => {
    try {
      const data = await api.get<Conversation[]>(`/api/kb/${id}/conversations`);
      setConversations(data);
    } catch { /* ignore */ }
  }, [id]);

  const fetchMessages = useCallback(async (convId: string) => {
    try {
      const data = await api.get<Message[]>(`/api/kb/${id}/conversations/${convId}/messages`);
      setMessages(data);
    } catch { setMessages([]); }
  }, [id]);

  const fetchDocs = useCallback(async () => {
    try {
      const data = await api.get<Document[]>(`/api/kb/${id}/documents`);
      setDocs(data);
    } catch {
      setDocs([]);
    } finally {
      setDocsLoading(false);
    }
  }, [id]);

  useEffect(() => { if (user && loading) { fetchConversations().finally(() => setLoading(false)); } }, [user, loading, fetchConversations]);
  useEffect(() => { if (user) fetchDocs(); }, [user, fetchDocs]);
  useEffect(() => { if (activeConvId) fetchMessages(activeConvId); else setMessages([]); }, [activeConvId, fetchMessages]);
  useEffect(() => { chatEndRef.current?.scrollIntoView({ behavior: "smooth" }); }, [messages, streamingContent]);

  const readyDocCount = docs.filter((doc) => doc.status === "completed").length;
  const chatPlaceholder = docsLoading
    ? "Checking document readiness..."
    : readyDocCount === 0
      ? "Upload a completed document before asking questions"
      : `Ask across ${readyDocCount} ready document${readyDocCount === 1 ? "" : "s"}...`;

  // SSE streaming send
  async function handleSend(msg: string) {
    if (sending || streaming) return;
    setSending(true);
    setShowApiKeyPrompt(false);

    const tempId = "temp-" + Date.now();
    setMessages((prev) => [...prev, {
      id: tempId, role: "user", content: msg,
      created_at: new Date().toISOString(),
    }]);

    // Start streaming placeholder
    setStreaming(true);
    setStreamingContent("");

    const controller = new AbortController();
    abortRef.current = controller;

    try {
      const res = await apiStream(
        `/api/kb/${id}/chat`,
        { message: msg, conversation_id: activeConvId },
        controller.signal
      );

      if (!res.ok) {
        const errData = await res.json().catch(() => ({}));
        throw new Error(errData.detail || `Chat failed (${res.status})`);
      }

      const reader = res.body?.getReader();
      if (!reader) throw new Error("No response stream");

      const decoder = new TextDecoder();
      let buffer = "";
      let finalConvId = activeConvId;
      let finalCitations: Citation[] = [];

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        buffer += decoder.decode(value, { stream: true });
        const lines = buffer.split("\n");
        buffer = lines.pop() || "";

        for (const line of lines) {
          if (!line.startsWith("data: ")) continue;
          const jsonStr = line.slice(6);
          try {
            const data = JSON.parse(jsonStr);
            if (data.type === "chunk") {
              setStreamingContent((prev) => prev + data.content);
            } else if (data.type === "done") {
              finalConvId = data.conversation_id;
              finalCitations = data.citations || [];
              // Save completed message
              const fullText = data.full_text || streamingContent;
              setMessages((prev) => [...prev, {
                id: "ai-" + Date.now(),
                role: "assistant",
                content: fullText,
                citations_json: JSON.stringify(finalCitations),
                created_at: new Date().toISOString(),
              }]);
              setStreaming(false);
              setStreamingContent("");
              if (finalConvId) {
                setActiveConvId(finalConvId);
                fetchConversations();
              }
            } else if (data.type === "error") {
              const message = data.message || "Request failed";
              if (isApiKeyError(message)) setShowApiKeyPrompt(true);
              setStreaming(false);
              setStreamingContent("");
              setMessages((prev) => [...prev, {
                id: "err-" + Date.now(),
                role: "assistant",
                content: formatChatError(message),
                created_at: new Date().toISOString(),
              }]);
            }
          } catch { /* skip malformed JSON */ }
        }
      }
    } catch (err: any) {
      if (err.name === "AbortError") {
        // User cancelled — save partial content
        if (streamingContent) {
          setMessages((prev) => [...prev, {
            id: "ai-" + Date.now(),
            role: "assistant",
            content: streamingContent + "\n\n*[Response cancelled]*",
            created_at: new Date().toISOString(),
          }]);
        }
      } else {
        const message = err.message || "Request failed";
        if (isApiKeyError(message)) setShowApiKeyPrompt(true);
        setMessages((prev) => [...prev, {
          id: "err-" + Date.now(),
          role: "assistant",
          content: formatChatError(message),
          created_at: new Date().toISOString(),
        }]);
      }
      setStreaming(false);
      setStreamingContent("");
    } finally {
      setSending(false);
      abortRef.current = null;
    }
  }

  function handleStopStreaming() {
    abortRef.current?.abort();
  }

  function handleNewChat() {
    setActiveConvId(null);
    setMessages([]);
    setActiveCitation(null);
    setStreamingContent("");
    setStreaming(false);
  }

  async function handleDeleteConv(convId: string, e: React.MouseEvent) {
    e.stopPropagation();
    const conversation = conversations.find((conv) => conv.id === convId);
    setPendingAction({
      type: "delete-conversation",
      conversationId: convId,
      title: conversation?.title || "this conversation",
    });
  }

  async function confirmDeleteConversation(convId: string) {
    try {
      await api.delete("/api/kb/" + id + "/conversations/" + convId);
      if (activeConvId === convId) { setActiveConvId(null); setMessages([]); }
      fetchConversations();
    } catch { /* ignore */ }
  }

  async function handleClearMessages() {
    if (!activeConvId) return;
    setPendingAction({ type: "clear-messages" });
  }

  async function confirmClearMessages() {
    if (!activeConvId) return;
    try {
      await api.delete("/api/kb/" + id + "/conversations/" + activeConvId + "/messages");
      setMessages([]);
    } catch { /* ignore */ }
  }

  async function confirmPendingAction() {
    const action = pendingAction;
    setPendingAction(null);
    if (!action) return;
    if (action.type === "delete-conversation") {
      await confirmDeleteConversation(action.conversationId);
    } else {
      await confirmClearMessages();
    }
  }

  // Build citation list from all messages
  const allCitations: Citation[] = messages
    .filter((m) => m.role === "assistant" && m.citations_json)
    .flatMap((m) => {
      try { return JSON.parse(m.citations_json!); } catch { return []; }
    });

  return (
    <div className="flex h-[calc(100vh-0px)]">
      {/* Left: Conversation List */}
      <div className="w-64 shrink-0 border-r border-hairline bg-canvas-soft flex flex-col">
        <div className="p-4 border-b border-hairline space-y-2">
          <button
            onClick={() => router.push("/kb/" + id)}
            className="inline-flex items-center gap-1.5 text-sm text-ink-muted hover:text-ink transition-colors"
          >
            <ArrowLeft className="h-3.5 w-3.5" /> KB Details
          </button>
          <button
            onClick={handleNewChat}
            className="w-full inline-flex items-center justify-center gap-2 h-9 rounded-lg bg-ink text-canvas text-sm font-medium hover:bg-ink-soft transition-all active:scale-[0.98]"
          >
            <Plus className="h-4 w-4" /> New Chat
          </button>
          {activeConvId && messages.length > 0 && (
            <button
              onClick={handleClearMessages}
              className="w-full inline-flex items-center justify-center gap-2 h-8 rounded-lg text-xs text-ink-muted hover:text-error hover:bg-error-soft/30 transition-all"
            >
              <Eraser className="h-3 w-3" /> Clear Messages
            </button>
          )}
          {pendingAction && (
            <div className="rounded-lg border border-error/30 bg-error-soft/40 p-3">
              <div className="flex items-start gap-2">
                <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-error" />
                <div className="min-w-0">
                  <p className="text-xs font-semibold text-ink">
                    {pendingAction.type === "delete-conversation"
                      ? "Delete conversation?"
                      : "Clear messages?"}
                  </p>
                  <p className="mt-1 text-xs leading-4 text-ink-muted">
                    {pendingAction.type === "delete-conversation"
                      ? pendingAction.title
                      : "This keeps the conversation but removes every message."}
                  </p>
                </div>
              </div>
              <div className="mt-3 grid grid-cols-2 gap-2">
                <button
                  onClick={() => setPendingAction(null)}
                  className="h-8 rounded-md border border-hairline bg-canvas text-xs font-medium text-ink-muted transition-colors hover:text-ink"
                >
                  Cancel
                </button>
                <button
                  onClick={confirmPendingAction}
                  className="h-8 rounded-md bg-error text-xs font-medium text-white transition-opacity hover:opacity-90"
                >
                  Confirm
                </button>
              </div>
            </div>
          )}
        </div>
        <div className="flex-1 overflow-y-auto p-2 space-y-0.5">
          <button
            onClick={handleNewChat}
            className={
              "w-full text-left px-3 py-2 rounded-lg text-sm transition-colors " +
              (!activeConvId && messages.length === 0
                ? "bg-accent-soft text-accent font-medium"
                : "text-ink-body hover:bg-canvas-softer")
            }
          >
            <div className="flex items-center gap-2">
              <MessageSquare className="h-3.5 w-3.5 shrink-0" />
              <span className="truncate">New Chat</span>
            </div>
          </button>
          {conversations.map((conv) => (
            <button
              key={conv.id}
              onClick={() => {
                setActiveConvId(conv.id);
                setStreamingContent("");
                setStreaming(false);
              }}
              className={
                "group w-full text-left px-3 py-2 rounded-lg text-sm transition-colors " +
                (activeConvId === conv.id
                  ? "bg-accent-soft text-accent font-medium"
                  : "text-ink-body hover:bg-canvas-softer")
              }
            >
              <div className="flex items-center gap-2">
                <MessageSquare className="h-3.5 w-3.5 shrink-0" />
                <span className="truncate flex-1">{conv.title}</span>
                <span
                  onClick={(e) => handleDeleteConv(conv.id, e)}
                  className="opacity-0 group-hover:opacity-100 p-0.5 rounded hover:bg-error-soft/50 text-ink-muted hover:text-error transition-all"
                >
                  <Trash2 className="h-3.5 w-3.5" />
                </span>
              </div>
            </button>
          ))}
        </div>
        <div className="p-3 border-t border-hairline">
          <button
            onClick={() => setShowCitations(!showCitations)}
            className="w-full inline-flex items-center justify-center gap-2 h-8 text-xs text-ink-muted hover:text-ink transition-colors"
          >
            {showCitations ? (
              <PanelRightClose className="h-3.5 w-3.5" />
            ) : (
              <PanelRightOpen className="h-3.5 w-3.5" />
            )}{" "}
            {showCitations ? "Hide Sources" : "Show Sources"}
          </button>
        </div>
      </div>

      {/* Center: Chat */}
      <div className="flex-1 flex flex-col bg-canvas min-w-0">
        {messages.length === 0 && !streaming ? (
          <div className="flex-1 flex flex-col items-center justify-center text-center px-8">
            <div className="h-16 w-16 rounded-2xl bg-accent-soft flex items-center justify-center mb-6">
              {readyDocCount === 0 ? (
                <Upload className="h-8 w-8 text-accent" />
              ) : (
                <Bot className="h-8 w-8 text-accent" />
              )}
            </div>
            <h2 className="h3 text-ink mb-2">
              {readyDocCount === 0 ? "Upload documents first" : "Ask your knowledge base"}
            </h2>
            <p className="body-sm text-ink-body max-w-md">
              {readyDocCount === 0
                ? "Chat becomes available after at least one document finishes processing."
                : "Ask questions and get answers with source citations from your documents."}
            </p>
            {readyDocCount === 0 && (
              <button
                onClick={() => router.push("/kb/" + id)}
                className="mt-6 inline-flex h-10 items-center gap-2 rounded-lg bg-ink px-4 text-sm font-medium text-canvas transition-all hover:bg-ink-soft active:scale-[0.98]"
              >
                <Upload className="h-4 w-4" />
                Upload documents
              </button>
            )}
          </div>
        ) : (
          <div className="flex-1 overflow-y-auto px-4">
            {messages.map((msg) => {
              const citations = msg.citations_json
                ? (() => {
                    try { return JSON.parse(msg.citations_json); } catch { return undefined; }
                  })()
                : undefined;
              return (
                <ChatMessage
                  key={msg.id}
                  messageId={msg.id}
                  role={msg.role as "user" | "assistant"}
                  content={msg.content}
                  citations={citations}
                  activeCitation={activeCitation}
                  onCitationClick={handleCitationClick}
                />
              );
            })}
            {/* Streaming indicator */}
            {streaming && (
              <ChatMessage
                key="streaming"
                role="assistant"
                content={streamingContent}
              />
            )}
            <div ref={chatEndRef} />
          </div>
        )}
        {showApiKeyPrompt && (
          <div className="border-t border-warning/20 bg-warning-soft/30 px-4 py-3">
            <div className="mx-auto flex max-w-3xl flex-col gap-3 rounded-xl border border-warning/25 bg-canvas px-4 py-3 shadow-sm sm:flex-row sm:items-center">
              <AlertTriangle className="h-5 w-5 shrink-0 text-warning" />
              <div className="min-w-0 flex-1">
                <p className="text-sm font-semibold text-ink">Model API key required</p>
                <p className="mt-0.5 text-xs leading-5 text-ink-muted">
                  Add your LLM provider key before asking questions. This is required on customer installs that do not ship with a system fallback key.
                </p>
              </div>
              <button
                onClick={() => setApiKeyOpen(true)}
                className="inline-flex h-9 items-center justify-center gap-2 rounded-lg bg-ink px-3 text-xs font-medium text-canvas transition-all hover:bg-ink-soft active:scale-[0.98]"
              >
                <Key className="h-3.5 w-3.5" />
                Set API Key
              </button>
            </div>
          </div>
        )}
        <ChatInput
          onSend={handleSend}
          disabled={sending || readyDocCount === 0}
          placeholder={chatPlaceholder}
          onStop={streaming ? handleStopStreaming : undefined}
          isStreaming={streaming}
        />
      </div>

      {/* Right: Citation Panel — hidden on mobile, shown as overlay */}
      {showCitations && (
        <>
          {/* Mobile: overlay panel */}
          <div className="lg:hidden fixed inset-0 z-50 bg-canvas" style={{ display: mobilePanel === "citations" ? "flex" : "none" }}>
            <div className="flex flex-col h-full w-full">
              <div className="flex items-center justify-between p-4 border-b border-hairline">
                <h3 className="text-sm font-semibold text-ink">Sources</h3>
                <button onClick={() => setMobilePanel("chat")} className="p-2 rounded-lg text-ink-muted hover:bg-canvas-softer">✕</button>
              </div>
              <div className="flex-1 overflow-y-auto">
                <CitationPanel
                  citations={allCitations}
                  activeCitation={activeCitation}
                  onCitationClick={handleCitationClick}
                />
              </div>
            </div>
          </div>
          {/* Desktop: side panel */}
          <div className="hidden lg:block w-80 shrink-0 border-l border-hairline bg-canvas-soft">
            <CitationPanel
              citations={allCitations}
              activeCitation={activeCitation}
              onCitationClick={handleCitationClick}
            />
          </div>
        </>
      )}

      {/* Mobile: sources button floating above input */}
      {showCitations && allCitations.length > 0 && (
        <div className="lg:hidden fixed bottom-20 right-4 z-10">
          <button
            onClick={() => setMobilePanel(mobilePanel === "citations" ? "chat" : "citations")}
            className="h-10 px-4 rounded-full bg-ink text-canvas text-xs font-medium shadow-lg flex items-center gap-2"
          >
            <PanelRightOpen className="h-3.5 w-3.5" />
            {allCitations.length} Sources
          </button>
        </div>
      )}
      <ApiKeyDialog open={apiKeyOpen} onClose={() => setApiKeyOpen(false)} />
    </div>
  );
}
