<template>
  <div :id="`modal${numberTable}`" class="modal">
    <div class="modal-content">
      <p class="number-table">{{ numberTable }}</p>
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
    <div class="modal-footer" v-if="table">
      <button type="button" class="waves-effect waves-green btn-flat"
        @click="$emit('del', { id: table.id })">Удалить</button>
    </div>
    <div class="modal-footer" v-else>
      <button type="button" class="waves-effect waves-green btn-flat" @click="$emit('del')">Записать</button>
    </div>

  </div>
</template>

<script>
var elem = document.querySelectorAll('.modal');
var instance = M.Modal.getInstance(elem);
export default {
  props: ['table', "numberTable"],
  emits: ['del', 'creat'],
  data() {
    return {
      time: "",
      person: "",
      name: "",
      tel: "",
    }
  },
  watch: {
    table() {
      this.time = this.table.time
      this.person = this.table.person
      this.name = this.table.name
      this.tel = this.table.phone
    }
  },
  methods: {

  }

}
</script>

<style lang="scss" scoped></style>
