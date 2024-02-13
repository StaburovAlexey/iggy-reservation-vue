import { supabase } from "@/lib/supabaseClient";

export default {
  state: {
    reservation: [],
    date: "",
  },
  actions: {
    async fetchInfo({ dispatch, commit, state }) {
      const { data, error } = await supabase
        .from("tables")
        .select()
        .eq("date", state.date);
      if (error) throw error;
      // else commit("setReserve", data);
      else return data;
    },
  },
  mutations: {
    setReserve(state, reservation) {
      state.reservation = reservation;
    },
    setDate(state, date) {
      state.date = date;
    },
  },
  getters: {
    reservation: (s) => s.reservation,
    date: (s) => s.date,
  },
};
