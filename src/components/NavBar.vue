<template>
  <header>
    <ul id="dropdown1" class="dropdown-content">
      <li class="dropdown-li" v-for="(item, index) in reserve" :key="index">
        Имя: {{ item.name }}<br />Время: {{ item.time }}<br />Номер:
        {{ item.phone }}<br />Гостей: {{ item.person }}<br />
        Стол: {{ item.table }}
      </li>
    </ul>
    <nav>
      <div class="nav-wrapper indigo darken-3">
        <a href="#!" class="brand-logo left logo white"></a>
        <ul class="right">
          <li>
            <a
              class="dropdown-trigger"
              ref="dropdown"
              href="#!"
              data-target="dropdown1"
              >Список броней<i class="material-icons right"
                >arrow_drop_down</i
              ></a
            >
          </li>
        </ul>
      </div>
    </nav>
  </header>
</template>

<script>
import M from "materialize-css/dist/js/materialize.min";
export default {
  data() {
    return {
      reserve: {},
    };
  },
  mounted() {
    M.Dropdown.init(this.$refs.dropdown, {
      constrainWidth: false,
    });
  },
  computed: {
    date() {
      return this.$store.getters.date;
    },
  },
  methods: {
    async open() {
      const day = await this.$store.dispatch("fetchInfo");
      this.reserve = day;
      console.log("open nav", day);
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
