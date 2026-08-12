import { create } from "zustand";
import { Lang, TranslationKey, TranslationValues, t as translate } from "@/lib/i18n";

interface I18nState {
  lang: Lang;
  setLang: (lang: Lang) => void;
  hydrateLanguage: () => void;
  t: (key: TranslationKey, values?: TranslationValues) => string;
}

export const useI18nStore = create<I18nState>((set, get) => ({
  lang: "zh",
  setLang: (lang: Lang) => {
    if (typeof window !== "undefined") localStorage.setItem("knowbase-lang", lang);
    set({ lang });
  },
  hydrateLanguage: () => {
    if (typeof window === "undefined") return;
    set({ lang: localStorage.getItem("knowbase-lang") === "en" ? "en" : "zh" });
  },
  t: (key: TranslationKey, values?: TranslationValues) => translate(get().lang, key, values),
}));
