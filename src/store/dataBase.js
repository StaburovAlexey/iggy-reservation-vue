import { defineStore } from "pinia";
import { api } from "@/api/client";

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
      const resp = await api.getTables(this.date || undefined);
      const items = resp?.items || resp || [];
      this.setReserve(items);
      return items;
    },

    async delInfo({ id }) {
      const cleanId = typeof id === "string" ? id.replace(/^eq\./, "") : id;
      try {
        const resp = await api.deleteTable(cleanId);
        return resp?.success ? 204 : resp?.status || resp;
      } catch (error) {
        console.log("del", error);
        throw error;
      }
    },
    async creatInfo({ data }) {
      const payload = {
        table: `${data.numTable}`,
        name: data.name,
        person: data.person,
        time: data.time,
        phone: data.tel,
        date: this.date,
      };
      try {
        await api.createTable(payload);
        return 201;
      } catch (error) {
        console.log(error);
        throw error;
      }
    },
  },
});
