import { supabase } from "@/lib/supabaseClient";

export default {
  state: {
    user: {},
  },
  actions: {
    async login({}, { email, pass }) {
      const { error } = await supabase.auth.signInWithPassword({
        email: email,
        password: pass,
      });
      if (error) throw error;
    },
  },
  mutations: {
    setUser(state, user) {
      state.user = user;
    },
    clearUser(state) {
      state.user = {};
    },
  },
  getters: {
    user: (s) => s.user,
  },
};
