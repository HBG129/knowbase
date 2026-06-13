"use client";

import { useEffect, useState, useCallback } from "react";
import { usePathname, useRouter } from "next/navigation";
import { useAuthStore } from "@/stores/auth-store";
import { useI18nStore } from "@/stores/i18n-store";
import { useThemeStore } from "@/stores/theme-store";
import { Sidebar } from "@/components/layout/sidebar";
import { ToastProvider } from "@/components/ui/toast-provider";
import { Menu } from "lucide-react";
import "./globals.css";

function AuthInit({ children }: { children: React.ReactNode }) {
  const fetchMe = useAuthStore((s) => s.fetchMe);
  const token = useAuthStore((s) => s.token);
  const pathname = usePathname();
  const router = useRouter();
  const [ready, setReady] = useState(false);
  const isAuthPage = pathname === "/login" || pathname === "/register";

  useEffect(() => { fetchMe().finally(() => setReady(true)); }, [fetchMe]);
  useEffect(() => { if (ready && !token && !isAuthPage) router.push("/login"); }, [ready, token, isAuthPage, router]);

  if (!ready && !isAuthPage) {
    return (
      <div className="flex min-h-screen items-center justify-center bg-canvas">
        <div className="flex flex-col items-center gap-4">
          <div className="h-10 w-10 rounded-xl bg-ink flex items-center justify-center">
            <svg className="h-5 w-5 text-canvas animate-pulse" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><path d="M13 2L3 14h9l-1 8 10-12h-9l1-8z" /></svg>
          </div>
          <p className="text-sm text-ink-muted">Loading KnowBase…</p>
        </div>
      </div>
    );
  }
  return <>{children}</>;
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const pathname = usePathname();
  const token = useAuthStore((s) => s.token);
  const lang = useI18nStore((s) => s.lang);
  const isAuthPage = pathname === "/login" || pathname === "/register";
  const [mobileOpen, setMobileOpen] = useState(false);
  const closeMobile = useCallback(() => setMobileOpen(false), []);
  const { theme, setTheme } = useThemeStore();

  // Init theme from localStorage / system preference
  useEffect(() => {
    const stored = localStorage.getItem("knowbase-theme");
    if (stored === "dark" || stored === "light") {
      setTheme(stored);
    } else if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      setTheme("dark");
    }
  }, []);

  return (
    <html lang={lang === "zh" ? "zh-CN" : "en"} suppressHydrationWarning>
      <head>
        <script dangerouslySetInnerHTML={{ __html: `try{var t=localStorage.getItem("knowbase-theme");if(t==="dark"||(!t&&matchMedia("(prefers-color-scheme:dark)").matches))document.documentElement.classList.add("dark")}catch(e){}` }} />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
      </head>
      <body className="bg-canvas">
        <AuthInit>
          {isAuthPage ? children : token ? (
            <>
              {mobileOpen && (
                <div className="fixed inset-0 z-30 bg-ink/40 backdrop-blur-sm lg:hidden" onClick={closeMobile} />
              )}
              <Sidebar mobileOpen={mobileOpen} onMobileClose={closeMobile} />
              <button
                onClick={() => setMobileOpen(true)}
                className="fixed top-3 left-3 z-20 h-10 w-10 rounded-xl bg-canvas border border-hairline flex items-center justify-center shadow-sm lg:hidden"
              >
                <Menu className="h-5 w-5 text-ink" />
              </button>
              <main className="flex-1 lg:ml-[240px] min-h-screen pt-14 lg:pt-0">
                {children}
              </main>
            </>
          ) : children}
          <ToastProvider />
        </AuthInit>
      </body>
    </html>
  );
}
