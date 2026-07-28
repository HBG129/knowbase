"use client";

import { useState } from "react";
import { useAuthStore } from "@/stores/auth-store";
import { useI18nStore } from "@/stores/i18n-store";
import { Check, Eye, EyeOff, Key, Loader2, ShieldCheck, X } from "lucide-react";

interface Props {
  open: boolean;
  onClose: () => void;
}

interface StatusMessage {
  text: string;
  error: boolean;
}

export function ApiKeyDialog({ open, onClose }: Props) {
  const { user, setApiKey, clearApiKey } = useAuthStore();
  const { t } = useI18nStore();
  const [apiKey, setApiKeyValue] = useState("");
  const [provider, setProvider] = useState("zhipu");
  const [showKey, setShowKey] = useState(false);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<StatusMessage | null>(null);

  if (!open) return null;

  const providers = [
    { value: "zhipu", label: t("apiKey.zhipuLabel"), description: t("apiKey.zhipuDescription") },
    { value: "deepseek", label: "DeepSeek", description: t("apiKey.deepseekDescription") },
    { value: "openai", label: "OpenAI", description: t("apiKey.openaiDescription") },
  ];
  const visibilityLabel = showKey ? t("apiKey.hide") : t("apiKey.show");

  async function handleSave() {
    if (!apiKey.trim()) return;
    setSaving(true);
    setMessage(null);
    try {
      await setApiKey(apiKey.trim(), provider);
      setMessage({ text: t("apiKey.saved"), error: false });
      setApiKeyValue("");
    } catch (error: any) {
      setMessage({
        text: t("apiKey.saveFailed", { message: error.message || t("apiKey.unknownError") }),
        error: true,
      });
    } finally {
      setSaving(false);
    }
  }

  async function handleClear() {
    setSaving(true);
    setMessage(null);
    try {
      await clearApiKey();
      setApiKeyValue("");
      setMessage({ text: t("apiKey.cleared"), error: false });
    } catch (error: any) {
      setMessage({
        text: t("apiKey.clearFailed", { message: error.message || t("apiKey.unknownError") }),
        error: true,
      });
    } finally {
      setSaving(false);
    }
  }

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center pt-[15vh]">
      <div className="fixed inset-0 bg-ink/60 backdrop-blur-sm" onClick={onClose} />
      <div
        className="relative mx-4 w-full max-w-md overflow-hidden rounded-xl border border-hairline bg-canvas shadow-2xl"
        role="dialog"
        aria-modal="true"
        aria-labelledby="api-key-dialog-title"
      >
        <div className="flex items-center justify-between border-b border-hairline px-6 py-4">
          <div className="flex items-center gap-2.5">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-accent-soft">
              <Key className="h-4 w-4 text-accent" />
            </div>
            <div>
              <h2 id="api-key-dialog-title" className="text-sm font-semibold text-ink">{t("apiKey.title")}</h2>
              <p className="text-xs text-ink-muted">{t("apiKey.description")}</p>
            </div>
          </div>
          <button onClick={onClose} aria-label={t("common.close")} title={t("common.close")} className="flex h-8 w-8 items-center justify-center rounded-lg text-ink-muted transition-colors hover:bg-canvas-softer hover:text-ink">
            <X className="h-4 w-4" />
          </button>
        </div>

        <div className="space-y-5 px-6 py-5">
          {user?.has_api_key ? (
            <div className="flex items-center gap-2 rounded-lg border border-success/20 bg-success-soft/50 p-3">
              <Check className="h-4 w-4 flex-shrink-0 text-success" />
              <div>
                <p className="text-xs font-medium text-success">
                  {t("apiKey.configured", { provider: user.api_provider?.toUpperCase() || "LLM" })}
                </p>
                <p className="mt-0.5 text-[11px] text-ink-muted">{t("apiKey.configuredHint")}</p>
              </div>
            </div>
          ) : (
            <div className="rounded-lg border border-warning/20 bg-warning-soft/30 p-3">
              <p className="text-xs leading-5 text-ink-body">{t("apiKey.notConfigured")}</p>
            </div>
          )}

          <div>
            <p className="mb-2 text-xs font-medium text-ink-muted">{t("apiKey.provider")}</p>
            <div className="space-y-1.5">
              {providers.map((item) => (
                <button
                  key={item.value}
                  onClick={() => setProvider(item.value)}
                  className={
                    "w-full rounded-lg border px-3 py-2.5 text-left text-sm transition-all " +
                    (provider === item.value
                      ? "border-accent bg-accent-soft/50 text-accent"
                      : "border-hairline text-ink-body hover:border-hairline-strong")
                  }
                >
                  <span className="font-medium">{item.label}</span>
                  <span className="ml-2 text-xs text-ink-muted">{item.description}</span>
                </button>
              ))}
            </div>
          </div>

          <div>
            <label htmlFor="personal-api-key" className="mb-2 block text-xs font-medium text-ink-muted">API Key</label>
            <div className="relative">
              <input
                id="personal-api-key"
                type={showKey ? "text" : "password"}
                value={apiKey}
                onChange={(event) => setApiKeyValue(event.target.value)}
                placeholder={provider === "zhipu" ? t("apiKey.placeholderZhipu") : t("apiKey.placeholderDefault")}
                className="h-10 w-full rounded-lg border border-hairline bg-canvas px-3 pr-10 text-sm text-ink placeholder:text-ink-placeholder focus:border-accent focus:outline-none focus:ring-2 focus:ring-accent/10"
              />
              <button
                type="button"
                onClick={() => setShowKey((value) => !value)}
                aria-label={visibilityLabel}
                title={visibilityLabel}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-ink-muted transition-colors hover:text-ink"
              >
                {showKey ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
              </button>
            </div>
          </div>

          <div className="flex items-start gap-2.5 rounded-lg border border-hairline bg-canvas-soft/60 p-3">
            <ShieldCheck className="mt-0.5 h-4 w-4 flex-shrink-0 text-accent" />
            <p className="text-xs leading-5 text-ink-muted">{t("apiKey.providerDataNotice")}</p>
          </div>

          {message && (
            <p className={"rounded-lg px-3 py-2 text-xs " + (message.error ? "bg-error/10 text-error" : "bg-success/10 text-success")}>
              {message.text}
            </p>
          )}
        </div>

        <div className="flex items-center gap-3 border-t border-hairline bg-canvas-soft/50 px-6 py-4">
          {user?.has_api_key && (
            <button onClick={handleClear} disabled={saving} className="h-10 rounded-lg border border-error/30 px-4 text-sm font-medium text-error transition-colors hover:bg-error/5 disabled:opacity-50">
              {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : t("apiKey.clear")}
            </button>
          )}
          <div className="flex-1" />
          <button onClick={onClose} className="h-10 rounded-lg border border-hairline px-4 text-sm font-medium text-ink-body transition-colors hover:bg-canvas-softer">
            {t("common.cancel")}
          </button>
          <button onClick={handleSave} disabled={!apiKey.trim() || saving} className="h-10 rounded-lg bg-ink px-5 text-sm font-medium text-canvas transition-all hover:bg-ink-soft active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-50">
            {saving ? <Loader2 className="h-4 w-4 animate-spin" /> : t("common.save")}
          </button>
        </div>
      </div>
    </div>
  );
}
