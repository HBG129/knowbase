"use client";

import { useI18nStore } from "@/stores/i18n-store";

export default function GlobalError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  const { lang, t } = useI18nStore();

  return (
    <html lang={lang === "zh" ? "zh-CN" : "en"}>
      <body style={{ margin: 0, fontFamily: "Inter, system-ui, sans-serif", background: "#fafafa" }}>
        <div style={{ display: "flex", minHeight: "100vh", alignItems: "center", justifyContent: "center", padding: "24px" }}>
          <div style={{ textAlign: "center", maxWidth: "400px" }}>
            <div style={{ width: "56px", height: "56px", borderRadius: "16px", background: "#f7d4d6", display: "flex", alignItems: "center", justifyContent: "center", margin: "0 auto 24px", color: "#9f1239", fontSize: "28px", fontWeight: 700 }}>
              !
            </div>
            <h1 style={{ fontSize: "24px", fontWeight: 600, color: "#0a0a0e", margin: "0 0 8px" }}>{t("error.pageTitle")}</h1>
            <p style={{ fontSize: "14px", color: "#666", margin: "0 0 24px" }}>{t("error.criticalHint")}</p>
            <button onClick={() => reset()} style={{ height: "40px", padding: "0 20px", borderRadius: "8px", border: "none", background: "#0a0a0e", color: "#fff", fontSize: "14px", fontWeight: 500, cursor: "pointer" }}>
              {t("error.tryAgain")}
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
