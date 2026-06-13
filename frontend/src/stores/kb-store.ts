import { create } from "zustand";
import { api } from "@/lib/api";

interface KB { id: string; name: string; description: string | null; owner_id: string; created_at: string; updated_at: string; doc_count?: number; conversation_count?: number; }

interface KBState {
  kbs: KB[]; isLoading: boolean;
  fetchKBs: () => Promise<void>;
  createKB: (name: string, description?: string) => Promise<KB>;
  deleteKB: (id: string) => Promise<void>;
}

export const useKBStore = create<KBState>((set) => ({
  kbs: [], isLoading: false,
  fetchKBs: async () => {
    set({ isLoading: true });
    const data = await api.get<KB[]>("/api/kb");
    set({ kbs: data, isLoading: false });
  },
  createKB: async (name, description) => {
    const kb = await api.post<KB>("/api/kb", { name, description });
    set((s) => ({ kbs: [kb, ...s.kbs] }));
    return kb;
  },
  deleteKB: async (id) => {
    await api.delete("/api/kb/" + id);
    set((s) => ({ kbs: s.kbs.filter((k) => k.id !== id) }));
  },
}));
