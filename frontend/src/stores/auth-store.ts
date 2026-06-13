import { create } from "zustand";
import { api } from "@/lib/api";

interface User {
  id: string; email: string; username: string;
  avatar_url: string | null; role: string;
  api_provider: string | null; has_api_key: boolean;
}

interface AuthState {
  user: User | null;
  isLoading: boolean;
  token: string | null;
  login: (email: string, password: string) => Promise<void>;
  register: (email: string, username: string, password: string) => Promise<void>;
  logout: () => void;
  fetchMe: () => Promise<void>;
  setApiKey: (apiKey: string, provider: string) => Promise<User>;
  clearApiKey: () => Promise<User>;
}

export const useAuthStore = create<AuthState>((set) => ({
  user: null,
  isLoading: true,
  token: null,
  login: async (email, password) => {
    const res = await api.post<{ access_token: string; refresh_token: string }>(
      "/api/auth/login", { email, password }
    );
    localStorage.setItem("access_token", res.access_token);
    localStorage.setItem("refresh_token", res.refresh_token);
    set({ token: res.access_token });
    await useAuthStore.getState().fetchMe();
  },
  register: async (email, username, password) => {
    await api.post("/api/auth/register", { email, username, password });
  },
  logout: () => {
    localStorage.removeItem("access_token");
    localStorage.removeItem("refresh_token");
    set({ user: null, isLoading: false, token: null });
  },
  fetchMe: async () => {
    try {
      const t = localStorage.getItem("access_token");
      set({ token: t });
      const user = await api.get<User>("/api/auth/me");
      set({ user, isLoading: false });
    } catch {
      localStorage.removeItem("access_token");
      localStorage.removeItem("refresh_token");
      set({ user: null, isLoading: false, token: null });
    }
  },
  setApiKey: async (apiKey: string, provider: string) => {
    const user = await api.put<User>("/api/auth/me/api-key", {
      api_key: apiKey, api_provider: provider,
    });
    set({ user });
    return user;
  },
  clearApiKey: async () => {
    const user = await api.delete<User>("/api/auth/me/api-key");
    set({ user });
    return user;
  },
}));
