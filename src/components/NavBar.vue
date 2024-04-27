<template>
  <header>
    <nav>
      <div class="nav-wrapper indigo darken-3">
        <a href="#!" class="brand-logo left logo white" @click="close"></a>
        <button
          class="btn right btn-nav modal-trigger"
          data-target="modal12"
          :class="{
            red: reserve.room == true,
          }"
        >
          Аренда комнаты
        </button>
      </div>
    </nav>
    <ModalApp
      :table="reserve.room"
      :numberTable="12"
      @del="delReserve"
      @creat="creatReserve"
    >
    </ModalApp>
  </header>
</template>

<script>
export default {
  data() {
    return {
      reserve: {},
    };
  },
  mounted() {},
  computed: {
    date() {
      return this.$store.getters.date;
    },
  },
  methods: {
    async open() {
      const day = await this.$store.dispatch("fetchInfo");
      this.reserve = day;
    },
    async delReserve(id) {
      console.log("delreserve", id.id);
      this.loading = true;
      const status = await this.$store.dispatch("delInfo", { id: id.id });
      if (status == "204") {
        await this.open();
        alert("Запись удалена");
        this.loading = false;
      } else {
        alert(status);
        this.loading = false;
      }
    },
    async creatReserve(data) {
      this.loading = true;
      const status = await this.$store.dispatch("creatInfo", { data });
      if (status == "201") {
        await this.open();
        alert("Запись добавлена");
        this.loading = false;
      } else {
        alert(status);
        this.loading = false;
      }
    },
  },
  watch: {
    date() {
      this.open();
    },
  },
};
</script>

<style lang="scss"></style>
