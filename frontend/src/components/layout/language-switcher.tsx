"use client";

import { useI18nStore } from "@/stores/i18n-store";
import { Languages } from "lucide-react";

export function LanguageSwitcher() {
  const { lang, setLang } = useI18nStore();

  const toggle = () => setLang(lang === "zh" ? "en" : "zh");

  return (
    <button
      onClick={toggle}
      className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium text-ink-muted hover:text-ink hover:bg-canvas-soft transition-all active:scale-95"
      title={lang === "zh" ? "Switch to English" : "切换到中文"}
    >
      <Languages className="h-3.5 w-3.5" />
      <span>{lang === "zh" ? "EN" : "中文"}</span>
    </button>
  );
}
