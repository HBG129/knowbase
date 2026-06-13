import { create } from "zustand";
import { Lang, t as translate } from "@/lib/i18n";

interface I18nState {
  lang: Lang;
  setLang: (lang: Lang) => void;
  t: (key: string) => string;
}

export const useI18nStore = create<I18nState>((set, get) => ({
  lang: (typeof window !== "undefined" && (localStorage.getItem("knowbase-lang") as Lang)) || "zh",
  setLang: (lang: Lang) => {
    localStorage.setItem("knowbase-lang", lang);
    set({ lang });
  },
  t: (key: string) => translate(get().lang, key),
}));
