"use client";
import { RegisterForm } from "@/components/auth/register-form";
import { useI18nStore } from "@/stores/i18n-store";
import { Zap } from "lucide-react";

export default function RegisterPage() {
  const { t } = useI18nStore();
  return (
    <div className="min-h-screen bg-gradient-mesh flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        <div className="text-center mb-8 animate-slide-up">
          <div className="h-12 w-12 rounded-xl bg-ink flex items-center justify-center mx-auto mb-4"><Zap className="h-6 w-6 text-canvas" /></div>
          <h1 className="h2 text-ink">{t("auth.createAccount")}</h1>
          <p className="body-sm text-ink-muted mt-2">{t("auth.createAccountDesc")}</p>
        </div>
        <div className="glass p-8 rounded-2xl animate-scale-in"><RegisterForm /></div>
      </div>
    </div>
  );
}
