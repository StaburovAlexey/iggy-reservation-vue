import { supabase } from "@/lib/supabaseClient";

export default {
  state: {
    reservation: [],
    date: "",
  },
  actions: {
    async fetchInfo({ commit, state }) {
      const { data, error } = await supabase
        .from("tables")
        .select()
        .eq("date", state.date);
      if (error) {
        throw error;
      } else {
        commit("setReserve", data);
        return data;
      }
    },
    async delInfo({},{ id }) {
      console.log('del', id)
      const { error, status } = await supabase
        .from("tables")
        .delete()
        .eq("id", id);
      if (error) {
        console.log('del', error);
      }
      return status;
    },
    async creatInfo({ state }, { data }) {
      const { error, status } = await supabase.from("tables").insert({
        table: `${data.numTable}`,
        name: data.name,
        person: data.person,
        time: data.time,
        phone: data.tel,
        date: state.date,
      });
      if (error) {
        console.log(error);
      }
      return status;
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
