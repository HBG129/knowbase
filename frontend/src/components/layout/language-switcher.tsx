"use client";

import { useI18nStore } from "@/stores/i18n-store";
import { Languages } from "lucide-react";

export function LanguageSwitcher() {
  const { lang, setLang, t } = useI18nStore();

  const toggle = () => setLang(lang === "zh" ? "en" : "zh");

  return (
    <button
      onClick={toggle}
      className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg text-xs font-medium text-ink-muted hover:text-ink hover:bg-canvas-soft transition-all active:scale-95"
      aria-label={lang === "zh" ? t("lang.switchToEnglish") : t("lang.switchToChinese")}
      title={lang === "zh" ? t("lang.switchToEnglish") : t("lang.switchToChinese")}
    >
      <Languages className="h-3.5 w-3.5" />
      <span>{lang === "zh" ? t("lang.shortEnglish") : t("lang.shortChinese")}</span>
    </button>
  );
}
