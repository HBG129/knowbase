"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/auth-store";
import { useI18nStore } from "@/stores/i18n-store";
import Link from "next/link";
import { Eye, EyeOff } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export function RegisterForm() {
  const { t } = useI18nStore();
  const [email, setEmail] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");
  const [showPassword, setShowPassword] = useState(false);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const register = useAuthStore((s) => s.register);
  const login = useAuthStore((s) => s.login);
  const router = useRouter();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    try {
      await register(email, username, password);
      await login(email, password);
      router.push("/");
    } catch (err: any) {
      setError(err.message || t("auth.registerFailed"));
      setLoading(false);
    }
  }

  const passwordLabel = showPassword ? t("auth.hidePassword") : t("auth.showPassword");

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      {error && <div className="rounded-lg bg-error-soft border border-error px-4 py-3 text-sm text-error">{error}</div>}
      <Input id="username" type="text" label={t("auth.username")} value={username} onChange={(e) => setUsername(e.target.value)} placeholder={t("auth.usernamePlaceholder")} required minLength={2} />
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
      <Button type="submit" loading={loading} className="w-full">{loading ? t("auth.creatingAccount") : t("auth.signUp")}</Button>
      <p className="text-center text-sm text-ink-muted">{t("auth.hasAccount")} <Link href="/login" className="text-link hover:text-link-deep hover:underline transition-colors">{t("auth.signIn")}</Link></p>
    </form>
  );
}
