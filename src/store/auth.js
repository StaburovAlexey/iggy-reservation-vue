import { supabase } from "@/lib/supabaseClient";

export default {
  state: {
    user: {},
  },
  actions: {
    async login({ dispatch, commit }, { email, pass }) {
      const { data, error } = await supabase.auth.signInWithPassword({
        email: email,
        password: pass,
      });
      commit("setUser", data.user);
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
