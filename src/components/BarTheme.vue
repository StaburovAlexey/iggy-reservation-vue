<template>
  <!-- <p>{{ date }}</p>
  <p @click="open">{{ tables }}</p> -->
  <main class="grey darken-3">
    <div class="row">
      <div class="col s2 offset-s5 green center modal-trigger" data-target="modal8" :class="{
        'green': tables.table_8 === false,
        'red': tables.table_8
      }">8</div>
    </div>
    <div class="row pull">
      <div class="col s2 offset-s1 center modal-trigger" data-target="modalPull" :class="{
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
    <div id="modal1" class="modal" ref="modal">
      <div class="modal-content">
        <p class="number-table">1</p>
        <div class="row row-modal">
          <p class="col s6">Время:</p>
          <div class="input-field col s6">
            <textarea class="materialize-textarea" v-model="time"></textarea>
          </div>
        </div>
        <div class="row row-modal">
          <p class="col s6">Количество человек:</p>
          <div class="input-field col s6">
            <textarea class="materialize-textarea" v-model="person"></textarea>
          </div>
        </div>
        <div class="row row-modal">
          <p class="col s6">Имя:</p>
          <div class="input-field col s6">
            <textarea class="materialize-textarea" v-model="name"></textarea>
          </div>
        </div>
        <div class="row row-modal">
          <p class="col s6">Телефон:</p>
          <div class="input-field col s6">
            <textarea class="materialize-textarea" v-model="tel"></textarea>
          </div>
        </div>
      </div>
      <div class="modal-footer">
        <button type="button" class="waves-effect waves-green btn-flat">Редактировать</button>
        <button type="button" class="waves-effect waves-green btn-flat">Удалить</button>
      </div>
    </div>
    <div id="modal2" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal3" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal4" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal5" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal6" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal7" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal8" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal9" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modal10" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
    <div id="modalPull" class="modal" ref="modal">
      <div class="modal-content">
        <h4>Modal Header pull</h4>
        <p>A bunch of text</p>
      </div>
      <div class="modal-footer">
        <a href="#!" class="modal-close waves-effect waves-green btn-flat">Agree</a>
      </div>
    </div>
  </main>
</template>

<script>
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
    }
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
        return reserve
      } else {
        console.log('не нашел стол', reserve)
        return false
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
  }


}
</script>

<style lang="scss" scoped></style>
