"use client";

import { useState } from "react";
import { useAuthStore } from "@/stores/auth-store";
import { Key, X, Eye, EyeOff, Check, Loader2 } from "lucide-react";

interface Props {
  open: boolean;
  onClose: () => void;
}

export function ApiKeyDialog({ open, onClose }: Props) {
  const { user, setApiKey, clearApiKey, fetchMe } = useAuthStore();
  const [apiKey, setApiKeyVal] = useState("");
  const [provider, setProvider] = useState("zhipu");
  const [showKey, setShowKey] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState("");

  if (!open) return null;

  const providers = [
    { value: "zhipu", label: "智谱 GLM (推荐)", desc: "免费/便宜，中文能力强" },
    { value: "deepseek", label: "DeepSeek", desc: "高性价比，1M上下文" },
    { value: "openai", label: "OpenAI", desc: "GPT-4o / GPT-4o-mini" },
  ];

  async function handleSave() {
    if (!apiKey.trim()) return;
    setSaving(true);
    setMessage("");
    try {
      await setApiKey(apiKey.trim(), provider);
      setMessage("API Key 已保存！");
      setApiKeyVal("");
    } catch (err: any) {
      setMessage("保存失败: " + (err.message || "Unknown error"));
    } finally {
      setSaving(false);
    }
  }

  async function handleClear() {
    setSaving(true);
    setMessage("");
    try {
      await clearApiKey();
      setApiKeyVal("");
      setMessage("API Key 已清除，将使用系统默认 Key。");
    } catch (err: any) {
      setMessage("清除失败: " + (err.message || "Unknown error"));
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[15vh]">
      {/* Backdrop */}
      <div className="fixed inset-0 bg-ink/60 backdrop-blur-sm" onClick={onClose} />

      {/* Dialog */}
      <div className="relative bg-canvas border border-hairline rounded-2xl shadow-2xl w-full max-w-md mx-4 overflow-hidden">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-hairline">
          <div className="flex items-center gap-2.5">
            <div className="h-8 w-8 rounded-lg bg-accent-soft flex items-center justify-center">
              <Key className="h-4 w-4 text-accent" />
            </div>
            <div>
              <h2 className="text-sm font-semibold text-ink">API Key 设置</h2>
              <p className="text-xs text-ink-muted">配置你自己的 LLM API Key</p>
            </div>
          </div>
          <button onClick={onClose} className="h-8 w-8 rounded-lg flex items-center justify-center text-ink-muted hover:bg-canvas-softer hover:text-ink transition-colors">
            <X className="h-4 w-4" />
          </button>
        </div>

        {/* Body */}
        <div className="px-6 py-5 space-y-5">
          {/* Current status */}
          {user?.has_api_key && (
            <div className="flex items-center gap-2 p-3 rounded-xl bg-success-soft/50 border border-success/20">
              <Check className="h-4 w-4 text-success flex-shrink-0" />
              <div>
                <p className="text-xs font-medium text-success">
                  已配置 {user.api_provider?.toUpperCase()} API Key
                </p>
                <p className="text-[11px] text-ink-muted mt-0.5">
                  你的 Key 将优先于系统默认 Key
                </p>
              </div>
            </div>
          )}

          {!user?.has_api_key && (
            <div className="p-3 rounded-xl bg-warning-soft/30 border border-warning/20">
              <p className="text-xs text-ink-body">
                未配置个人 API Key，将使用<strong>系统默认的智谱AI</strong>（免费额度有限）。
                建议配置你自己的 Key 以获得更稳定的服务。
              </p>
            </div>
          )}

          {/* Provider selector */}
          <div>
            <label className="block text-xs font-medium text-ink-muted mb-2">选择 Provider</label>
            <div className="space-y-1.5">
              {providers.map((p) => (
                <button
                  key={p.value}
                  onClick={() => setProvider(p.value)}
                  className={
                    "w-full text-left px-3 py-2.5 rounded-lg border text-sm transition-all " +
                    (provider === p.value
                      ? "border-accent bg-accent-soft/50 text-accent"
                      : "border-hairline text-ink-body hover:border-hairline-strong")
                  }
                >
                  <span className="font-medium">{p.label}</span>
                  <span className="text-xs text-ink-muted ml-2">{p.desc}</span>
                </button>
              ))}
            </div>
          </div>

          {/* API Key input */}
          <div>
            <label className="block text-xs font-medium text-ink-muted mb-2">API Key</label>
            <div className="relative">
              <input
                type={showKey ? "text" : "password"}
                value={apiKey}
                onChange={(e) => setApiKeyVal(e.target.value)}
                placeholder={provider === "zhipu" ? "例如: 49ae4535..." : "sk-..."}
                className="w-full h-10 px-3 pr-10 rounded-lg border border-hairline bg-canvas text-sm text-ink placeholder:text-ink-placeholder focus:outline-none focus:border-accent focus:ring-2 focus:ring-accent/10"
              />
              <button
                type="button"
                onClick={() => setShowKey(!showKey)}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-ink-muted hover:text-ink transition-colors"
              >
                {showKey ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
          </div>

          {/* Message */}
          {message && (
            <p className={
              "text-xs px-3 py-2 rounded-lg " +
              (message.includes("失败") ? "bg-error/10 text-error" : "bg-success/10 text-success")
            }>
              {message}
            </p>
          )}
        </div>

        {/* Footer */}
        <div className="flex items-center gap-3 px-6 py-4 border-t border-hairline bg-canvas-soft/50">
          {user?.has_api_key && (
            <button
              onClick={handleClear}
              disabled={saving}
              className="h-10 px-4 rounded-lg border border-error/30 text-error text-sm font-medium hover:bg-error/5 transition-colors disabled:opacity-50"
            >
              {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : "清除 Key"}
            </button>
          )}
          <div className="flex-1" />
          <button
            onClick={onClose}
            className="h-10 px-4 rounded-lg border border-hairline text-ink-body text-sm font-medium hover:bg-canvas-softer transition-colors"
          >
            取消
          </button>
          <button
            onClick={handleSave}
            disabled={!apiKey.trim() || saving}
            className="h-10 px-5 rounded-lg bg-ink text-canvas text-sm font-medium hover:bg-ink-soft transition-all active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed"
          >
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : "保存"}
          </button>
        </div>
      </div>
    </div>
  );
}
