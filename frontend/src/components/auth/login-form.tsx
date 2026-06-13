"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/auth-store";
import { useI18nStore } from "@/stores/i18n-store";
import Link from "next/link";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";

export function LoginForm() {
  const { t } = useI18nStore();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const login = useAuthStore((s) => s.login);
  const router = useRouter();

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault(); setError(""); setLoading(true);
    try { await login(email, password); router.push("/"); }
    catch (err: any) { setError(err.message || t("auth.loginFailed")); setLoading(false); }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-5">
      {error && <div className="rounded-lg bg-error-soft border border-error px-4 py-3 text-sm text-error">{error}</div>}
      <Input id="email" type="email" label={t("auth.email")} value={email} onChange={(e) => setEmail(e.target.value)} placeholder={t("auth.emailPlaceholder")} required />
      <Input id="password" type="password" label={t("auth.password")} value={password} onChange={(e) => setPassword(e.target.value)} placeholder={t("auth.passwordPlaceholder")} required minLength={8} />
      <Button type="submit" loading={loading} className="w-full">{loading ? t("auth.signingIn") : t("auth.signIn")}</Button>
      <p className="text-center text-sm text-ink-muted">{t("auth.noAccount")} <Link href="/register" className="text-link hover:text-link-deep hover:underline transition-colors">{t("auth.createOne")}</Link></p>
    </form>
  );
}
