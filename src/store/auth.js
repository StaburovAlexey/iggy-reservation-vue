import { defineStore } from "pinia";
import { supabase } from "@/lib/supabaseClient";

export const useAuthStore = defineStore("auth", {
  state: () => ({
    user: {},
  }),
  actions: {
    async login({ email, pass }) {
      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password: pass,
      });
      if (error) throw error;
      this.user = data?.user || {};
      return data;
    },
    setUser(user) {
      this.user = user || {};
    },
    clearUser() {
      this.user = {};
    },
  },
  getters: {
    isAuthenticated: (state) => Boolean(state.user?.id),
  },
});
