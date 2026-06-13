"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/lib/utils";
import { useAuthStore } from "@/stores/auth-store";
import { useKBStore } from "@/stores/kb-store";
import { useEffect, useState } from "react";
import {
  LayoutDashboard, Library, LogOut,
  ChevronLeft, ChevronRight, Zap, Key, X, Sun, Moon,
} from "lucide-react";
import { Avatar } from "@/components/ui/avatar";
import { LanguageSwitcher } from "@/components/layout/language-switcher";
import { ApiKeyDialog } from "@/components/auth/api-key-dialog";
import { useThemeStore } from "@/stores/theme-store";

interface NavItem { href: string; label: string; icon: React.ElementType; }

const mainNav: NavItem[] = [
  { href: "/", label: "Knowledge Bases", icon: Library },
];

interface SidebarProps {
  mobileOpen?: boolean;
  onMobileClose?: () => void;
}

export function Sidebar({ mobileOpen = false, onMobileClose }: SidebarProps) {
  const pathname = usePathname();
  const [collapsed, setCollapsed] = useState(false);
  const [apiKeyOpen, setApiKeyOpen] = useState(false);
  const { user, logout } = useAuthStore();
  const { kbs, fetchKBs } = useKBStore();
  const { theme, toggle: toggleTheme } = useThemeStore();

  useEffect(() => { fetchKBs(); }, [fetchKBs]);

  const initials = user?.email?.slice(0, 2).toUpperCase() || "U";

  return (
    <>
    <aside className={cn(
      "fixed left-0 top-0 h-screen z-40 flex flex-col transition-all duration-300",
      "bg-canvas-soft border-r border-hairline",
      collapsed ? "w-[68px]" : "w-[240px]",
      mobileOpen ? "translate-x-0 shadow-2xl" : "-translate-x-full",
      "lg:translate-x-0 lg:shadow-none"
    )}>
      {/* Logo */}
      <div className={cn("flex items-center h-16 px-4 border-b border-hairline", collapsed ? "justify-center" : "gap-3")}>
        <div className="h-8 w-8 rounded-lg bg-ink flex items-center justify-center flex-shrink-0">
          <Zap className="h-4 w-4 text-canvas" />
        </div>
        {!collapsed && <span className="font-semibold text-ink text-base tracking-tight">KnowBase</span>}
        <button onClick={onMobileClose} className="lg:hidden h-8 w-8 rounded-lg flex items-center justify-center text-ink-muted hover:bg-canvas-softer hover:text-ink transition-colors ml-auto">
          <X className="h-4 w-4" />
        </button>
      </div>

      {/* Main Nav */}
      <nav className="flex-1 px-3 py-4 space-y-1 overflow-y-auto">
        {mainNav.map((item) => {
          const isActive = pathname === item.href || (item.href !== "/" && pathname.startsWith(item.href));
          return (
            <Link key={item.href} href={item.href} onClick={onMobileClose} className={cn(
              "flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-150",
              isActive ? "bg-ink text-canvas" : "text-ink-body hover:bg-canvas-softer hover:text-ink",
              collapsed && "justify-center px-2"
            )}>
              <item.icon className="h-4 w-4 flex-shrink-0" />
              {!collapsed && <span>{item.label}</span>}
            </Link>
          );
        })}

        {!collapsed && (
          <div className="pt-4">
            <div className="flex items-center justify-between px-3 mb-1">
              <span className="text-xs font-medium text-ink-muted uppercase tracking-wider">Knowledge Bases</span>
            </div>
            {kbs.slice(0, 8).map((kb) => (
              <Link key={kb.id} href={"/kb/" + kb.id} onClick={onMobileClose} className={cn(
                "flex items-center gap-2.5 px-3 py-2 rounded-lg text-sm transition-all duration-150",
                pathname.startsWith("/kb/" + kb.id) ? "bg-accent-soft text-accent font-medium" : "text-ink-body hover:bg-canvas-softer"
              )}>
                <Library className="h-3.5 w-3.5 flex-shrink-0" />
                <span className="truncate">{kb.name}</span>
              </Link>
            ))}
          </div>
        )}
      </nav>

      {/* Bottom */}
      <div className="border-t border-hairline p-3 space-y-2">
        <LanguageSwitcher />
        <button onClick={toggleTheme} className={cn(
          "flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all w-full",
          "text-ink-muted hover:bg-canvas-softer hover:text-ink",
          collapsed && "justify-center px-2"
        )}>
          {theme === "dark" ? <Sun className="h-4 w-4 flex-shrink-0" /> : <Moon className="h-4 w-4 flex-shrink-0" />}
          {!collapsed && <span>{theme === "dark" ? "Light" : "Dark"}</span>}
        </button>
        <button onClick={() => setApiKeyOpen(true)} className={cn(
          "flex items-center gap-3 px-3 py-2 rounded-lg text-sm transition-all w-full",
          user?.has_api_key ? "text-success hover:bg-success-soft/30" : "text-ink-muted hover:bg-canvas-softer hover:text-ink",
          collapsed && "justify-center px-2"
        )} title="API Key Settings">
          <Key className="h-4 w-4 flex-shrink-0" />
          {!collapsed && <span>{user?.has_api_key ? "API Key ✓" : "Set API Key"}</span>}
        </button>
        <button onClick={() => setCollapsed(!collapsed)} className="hidden lg:flex w-full items-center justify-center p-2 rounded-lg text-ink-muted hover:bg-canvas-softer hover:text-ink transition-all">
          {collapsed ? <ChevronRight className="h-4 w-4" /> : <ChevronLeft className="h-4 w-4" />}
        </button>
        <div className={cn("flex items-center gap-3 p-2 rounded-lg", collapsed && "justify-center")}>
          <Avatar fallback={initials} size="sm" />
          {!collapsed && <div className="flex-1 min-w-0"><p className="text-sm font-medium text-ink truncate">{user?.email || "User"}</p></div>}
        </div>
        <button onClick={logout} className={cn("flex items-center gap-3 px-3 py-2 rounded-lg text-sm text-ink-muted hover:text-error hover:bg-error-soft/50 transition-all w-full", collapsed && "justify-center px-2")}>
          <LogOut className="h-4 w-4 flex-shrink-0" />
          {!collapsed && <span>Sign Out</span>}
        </button>
      </div>
    </aside>
    <ApiKeyDialog open={apiKeyOpen} onClose={() => setApiKeyOpen(false)} />
    </>
  );
}
