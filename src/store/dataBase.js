import { defineStore } from "pinia";
import { supabase } from "@/lib/supabaseClient";

export const useDataStore = defineStore("dataBase", {
  state: () => ({
    reservation: [],
    date: "",
  }),
  actions: {
    setReserve(reservation) {
      this.reservation = reservation || [];
    },
    setDate(date) {
      this.date = date || "";
    },
    async fetchInfo() {
      const { data, error } = await supabase
        .from("tables")
        .select()
        .eq("date", this.date);
      if (error) {
        throw error;
      }
      this.setReserve(data || []);
      return data;
    },
    async delInfo({ id }) {
      const { error, status } = await supabase
        .from("tables")
        .delete()
        .eq("id", id);
      if (error) {
        console.log("del", error);
      }
      return status;
    },
    async creatInfo({ data }) {
      const { error, status } = await supabase.from("tables").insert({
        table: `${data.numTable}`,
        name: data.name,
        person: data.person,
        time: data.time,
        phone: data.tel,
        date: this.date,
      });
      if (error) {
        console.log(error);
      }
      return status;
    },
  },
});
