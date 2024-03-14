<template>
  <div :id="`modal${numberTable}`" class="modal">
    <ul class="collection with-header list-pull" v-if="numberTable == 11">
      <li class="collection-item" v-for="res in table" :key="res.id">
        <span>Время: {{ res.time }}</span
        ><br />
        <span>Телефон: {{ res.phone }}</span
        ><br />
        <span>Имя: {{ res.name }}</span>
        <a class="secondary-content" @click="$emit('del', { id: res.id })"
          ><i class="material-icons">delete</i></a
        >
      </li>
    </ul>
    <div class="modal-content">
      <p class="number-table">{{ numberTable }}</p>
      <div class="row row-modal">
        <p class="col s6">Время:</p>
        <div class="input-field col s6">
          <input class="materialize-textarea" v-model="time" />
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
    <div v-if="numberTable !== 11">
      <div class="modal-footer" v-if="table">
        <button
          type="button"
          class="waves-effect waves-green btn-flat"
          @click="$emit('del', { id: table.id })"
        >
          Удалить
        </button>
      </div>
      <div class="modal-footer" v-else>
        <button
          type="button"
          class="waves-effect waves-green btn-flat"
          @click="$emit('creat', { time, person, name, tel, numTable })"
        >
          Записать
        </button>
      </div>
    </div>
    <div class="modal-footer" v-else="numberTable == 11">
      <button
        type="button"
        class="waves-effect waves-green btn-flat"
        @click="$emit('creat', { time, person, name, tel, numTable })"
      >
        Записать
      </button>
    </div>
  </div>
</template>

<script>
export default {
  props: ["table", "numberTable"],
  emits: ["del", "creat"],
  data() {
    return {
      time: "",
      person: "",
      name: "",
      tel: "",
      numTable: `${this.numberTable}`, // передаем строку из числа в Number
      loading: false,
    };
  },
  mounted() {
    var elems = document.querySelectorAll(".modal");
  },
  watch: {
    table() {
      this.time = this.table.time;
      this.person = this.table.person;
      this.name = this.table.name;
      this.tel = this.table.phone;
      console.log("table", this.table);
    },
  },
  methods: {
    click() {
      console.log("click");
    },
  },
};
</script>

<style lang="scss" scoped></style>
