"use client";

import { useEffect, useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/auth-store";
import { useI18nStore } from "@/stores/i18n-store";
import Link from "next/link";
import { Eye, EyeOff } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

const REMEMBERED_EMAIL_KEY = "knowbase.rememberedEmail";
const LEGACY_REMEMBER_LOGIN_KEY = "knowbase.rememberedLogin";

export function LoginForm() {
  const { t } = useI18nStore();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [rememberEmail, setRememberEmail] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const login = useAuthStore((s) => s.login);
  const router = useRouter();

  useEffect(() => {
    try {
      const savedEmail = localStorage.getItem(REMEMBERED_EMAIL_KEY);
      if (savedEmail) {
        setEmail(savedEmail);
        setRememberEmail(true);
      }

      const legacyLogin = localStorage.getItem(LEGACY_REMEMBER_LOGIN_KEY);
      if (legacyLogin) {
        const parsed = JSON.parse(legacyLogin) as { email?: string };
        if (!savedEmail && parsed.email) {
          setEmail(parsed.email);
          setRememberEmail(true);
          localStorage.setItem(REMEMBERED_EMAIL_KEY, parsed.email);
        }
        localStorage.removeItem(LEGACY_REMEMBER_LOGIN_KEY);
      }
    } catch {
      localStorage.removeItem(LEGACY_REMEMBER_LOGIN_KEY);
    }
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await login(email, password);
      if (rememberEmail) {
        localStorage.setItem(REMEMBERED_EMAIL_KEY, email);
      } else {
        localStorage.removeItem(REMEMBERED_EMAIL_KEY);
      }
      router.push("/");
    } catch (err: any) {
      setError(err.message || t("auth.loginFailed"));
      setLoading(false);
    }
  }

  const passwordLabel = showPassword ? t("auth.hidePassword") : t("auth.showPassword");

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      {error && <div className="rounded-lg bg-error-soft border border-error px-4 py-3 text-sm text-error">{error}</div>}
      <Input id="email" type="email" label={t("auth.email")} value={email} onChange={(e) => setEmail(e.target.value)} placeholder={t("auth.emailPlaceholder")} required />
      <div className="space-y-1.5">
        <label htmlFor="password" className="block text-sm font-medium text-ink-soft">
          {t("auth.password")}
        </label>
        <div className="relative">
          <input
            id="password"
            type={showPassword ? "text" : "password"}
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            placeholder={t("auth.passwordPlaceholder")}
            required
            minLength={8}
            className="w-full h-10 px-3.5 pr-11 rounded-lg border border-hairline bg-canvas text-ink text-sm placeholder:text-ink-placeholder transition-all duration-150 focus:outline-none focus:border-hairline-focus focus:ring-2 focus:ring-accent/10"
          />
          <button
            type="button"
            onClick={() => setShowPassword((value) => !value)}
            aria-label={passwordLabel}
            title={passwordLabel}
            className="absolute right-2.5 top-1/2 flex h-7 w-7 -translate-y-1/2 items-center justify-center rounded-md text-ink-muted transition-colors hover:bg-canvas-softer hover:text-ink"
          >
            {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
          </button>
        </div>
      </div>
      <label className="flex items-start gap-2.5 text-sm text-ink-body">
        <input
          type="checkbox"
          checked={rememberEmail}
          onChange={(e) => setRememberEmail(e.target.checked)}
          className="mt-0.5 h-4 w-4 rounded border-hairline accent-[rgb(var(--accent))]"
        />
        <span>
          {t("auth.rememberEmail")}
          <span className="block text-xs text-ink-muted">{t("auth.rememberEmailHint")}</span>
        </span>
      </label>
      <Button type="submit" loading={loading} className="w-full">{loading ? t("auth.signingIn") : t("auth.signIn")}</Button>
      <p className="text-center text-sm text-ink-muted">{t("auth.noAccount")} <Link href="/register" className="text-link hover:text-link-deep hover:underline transition-colors">{t("auth.createOne")}</Link></p>
    </form>
  );
}
