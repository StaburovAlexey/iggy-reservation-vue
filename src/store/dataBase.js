import { supabase } from "@/lib/supabaseClient";

export default {
  state: {
    reservation: [],
  },
  actions: {
    async fetchInfo({ dispatch, commit }, { date }) {
      const { data, error } = await supabase
        .from("tables")
        .select()
        .eq("date", date);
      if (error) throw error;
      // else commit("setReserve", data);

      else return data;
    },
  },
  mutations: {
    setReserve(state, reservation) {
      state.reservation = reservation;
    },
  },
  getters: {
    reservation: (s) => s.reservation,
  },
};
