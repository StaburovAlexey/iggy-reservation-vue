<template>
  <footer class="page-footer indigo darken-3">
    <div class="container black-text row">
      <p class="col s6 white-text">Выбери дату:</p>
      <div class="input-field col s6">
        <i class="material-icons prefix white-text">event</i>
        <input
          id="icon_prefix"
          ref="datepicker"
          class="datepicker white-text center"
          v-model="date"
          type="text"
          @change="updateDate"
        />
      </div>
    </div>
  </footer>
</template>

<script>
import M from "materialize-css/dist/js/materialize.min";
export default {
  data() {
    return {
      date: "",
    };
  },
  watch: {},
  async mounted() {
    const inst = await M.Datepicker.init(this.$refs.datepicker, {
      format: "dd.mm.yy",
      autoClose: true,
      firstDay: 1,
    });
    inst.setDate(new Date());
    this.date = this.formatDate(new Date());
    this.$store.commit("setDate", this.date);
    try {
      await this.$store.dispatch("fetchInfo");
    } catch (e) {
      console.log(e);
    }
  },
  methods: {
    async updateDate() {
      this.date = this.$refs.datepicker.value;
      try {
        this.$store.commit("setDate", this.date);
        await this.$store.dispatch("fetchInfo");
      } catch (e) {
        console.log(e);
      }
    },
    formatDate(date) {
      const options = {
        day: "2-digit",
        month: "2-digit",
        year: "2-digit",
      };
      return new Intl.DateTimeFormat("ru-RU", options).format(date);
    },
  },
};
</script>

<style lang="scss"></style>
