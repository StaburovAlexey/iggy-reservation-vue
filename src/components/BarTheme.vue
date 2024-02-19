<template>
  <!-- <p>{{ date }}</p>
  <p @click="open">{{ tables }}</p> -->
  <main class="grey darken-3">
    <div class="row">
      <div class="col s2 offset-s5 center modal-trigger" data-target="modal8" :class="{
        'green': tables.table_8 === false,
        'red': tables.table_8
      }">8</div>
    </div>
    <div class="row pull">
      <div class="col s2 offset-s1 center modal-trigger" data-target="modal11" :class="{
        'green': tables.pull === false,
        'red': tables.pull
      }">Pull</div>

      <div class="col s2 offset-s7 center modal-trigger" data-target="modal9" :class="{
        'green': tables.table_9 === false,
        'red': tables.table_9
      }">9</div>
    </div>
    <div class="row">
      <div class="col s2 offset-s5 center modal-trigger" data-target="modal10" :class="{
        'green': tables.table_10 === false,
        'red': tables.table_10
      }">10</div>
    </div>
    <div class="divider"></div>
    <div class="row">
      <div class="col s3 center modal-trigger" data-target="modal1" :class="{
        'green': tables.table_1 === false,
        'red': tables.table_1
      }">1</div>
      <div class="col s2 offset-s7 center circle modal-trigger" data-target="modal2" :class="{
        'green': tables.table_2 === false,
        'red': tables.table_2
      }">2</div>
    </div>
    <div class="row"></div>
    <div class="row">
      <div class="col s3 center modal-trigger" data-target="modal3" :class="{
        'green': tables.table_3 === false,
        'red': tables.table_3
      }">3
      </div>
      <div class="col s2 offset-s1 center circle modal-trigger" data-target="modal4" :class="{
        'green': tables.table_4 === false,
        'red': tables.table_4
      }">4</div>
      <div class="col s4 center modal-trigger" data-target="modal5" :class="{
        'green': tables.table_5 === false,
        'red': tables.table_5
      }">5</div>
      <div class="col s2 center circle modal-trigger" data-target="modal6" :class="{
        'green': tables.table_6 === false,
        'red': tables.table_6
      }">6</div>
    </div>
    <div class="row"></div>
    <div class="row">
      <div class="col s2 center circle modal-trigger" data-target="modal7" :class="{
        'green': tables.table_7 === false,
        'red': tables.table_7
      }">7</div>
    </div>
    <ModalApp v-for="(table, name, index) in tables" :key="index" :table="table" :numberTable="index + 1"></ModalApp>
  </main>
</template>

<script>
import ModalApp from './ModalApp.vue';

export default {
  data() {
    return {
      reserve: {},
      tables: {
        table_1: {},
        table_2: {},
        table_3: {},
        table_4: {},
        table_5: {},
        table_6: {},
        table_7: {},
        table_8: {},
        table_9: {},
        table_10: {},
        pull: {},
      }
    };
  },
  mounted() {
    M.AutoInit();
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
      // console.log(day)
    },
    async findReserveByTable(table) {
      const reserve = this.reserve.find(item => item.table === table);
      if (reserve) {
        return reserve;
      }
      else {
        // console.log('не нашел стол', reserve);
        return false;
      }
    }
  },
  watch: {
    date() {
      this.open();
    },
    async reserve() {
      this.tables.table_1 = await this.findReserveByTable('1');
      this.tables.table_2 = await this.findReserveByTable('2');
      this.tables.table_3 = await this.findReserveByTable('3');
      this.tables.table_4 = await this.findReserveByTable('4');
      this.tables.table_5 = await this.findReserveByTable('5');
      this.tables.table_6 = await this.findReserveByTable('6');
      this.tables.table_7 = await this.findReserveByTable('7');
      this.tables.table_8 = await this.findReserveByTable('8');
      this.tables.table_9 = await this.findReserveByTable('9');
      this.tables.table_10 = await this.findReserveByTable('10');
      this.tables.pull = await this.findReserveByTable('pull');
    }
  },
  components: { ModalApp }
}
</script>

<style lang="scss" scoped></style>
