<template>
  <div :id="modalId" class="modal">
    <ul class="collection with-header list-pull">
      <li class="collection-item" v-for="res in table" :key="res.id">
        <span>Время: {{ res.time }}</span><br />
        <span>Телефон: {{ res.phone }}</span><br />
        <span>Гости: {{ res.name }}</span>
        <a class="secondary-content" @click="emitDelete(res.id)">
          <i class="material-icons">delete</i>
        </a>
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
        <p class="col s6">Количество гостей:</p>
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
      <button
        type="button"
        class="waves-effect waves-green btn-flat"
        @click="emitCreate"
      >
        Сохранить
      </button>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref, watch } from "vue";

const props = defineProps({
  table: {
    type: Array,
    default: () => [],
  },
  numberTable: {
    type: [Number, String],
    default: "",
  },
});

const emit = defineEmits(["del", "creat"]);

const time = ref("");
const person = ref("");
const name = ref("");
const tel = ref("");

const modalId = computed(() => `modal${props.numberTable}`);
const numTable = computed(() => String(props.numberTable));

const fillForm = (tableData) => {
  const first = tableData?.[0];
  time.value = first?.time || "";
  person.value = first?.person || "";
  name.value = first?.name || "";
  tel.value = first?.phone || "";
};

const emitCreate = () =>
  emit("creat", {
    time: time.value,
    person: person.value,
    name: name.value,
    tel: tel.value,
    numTable: numTable.value,
  });

const emitDelete = (id) => emit("del", { id });

onMounted(() => {
  const modals = document.querySelectorAll(".modal");
  if (window.M?.Modal) {
    window.M.Modal.init(modals);
  }
});

watch(
  () => props.table,
  (value) => fillForm(value),
  { deep: true, immediate: true }
);
</script>

<style lang="scss" scoped></style>
