<template>
  <footer class="page-footer indigo darken-3">
    <div class="container black-text row">
      <p class="col s6 white-text">Выберите дату:</p>
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

<script setup>
import { onMounted, ref } from "vue";
import { useStore } from "vuex";
import M from "materialize-css/dist/js/materialize.min";

const store = useStore();
const datepicker = ref(null);
const date = ref("");
let pickerInstance = null;

const formatDate = (value) => {
  const options = { day: "2-digit", month: "2-digit", year: "2-digit" };
  return new Intl.DateTimeFormat("ru-RU", options).format(value);
};

const syncDate = async () => {
  date.value = datepicker.value?.value || "";
  if (!date.value) return;
  try {
    store.commit("setDate", date.value);
    await store.dispatch("fetchInfo");
  } catch (error) {
    console.log(error);
  }
};

onMounted(() => {
  pickerInstance = M.Datepicker.init(datepicker.value, {
    format: "dd.mm.yy",
    autoClose: true,
    firstDay: 1,
  });
  pickerInstance.setDate(new Date());
  date.value = formatDate(new Date());
  store.commit("setDate", date.value);
  store.dispatch("fetchInfo").catch((error) => console.log(error));
});

const updateDate = () => syncDate();
</script>

<style lang="scss"></style>
