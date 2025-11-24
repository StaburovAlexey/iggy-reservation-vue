<template>
  <main v-if="loading" class="main-loader grey darken-3">
    <PreloaderApp class="big" />
  </main>
  <main v-else class="grey darken-3 main">
    <h3 class="rent-main red-text center" v-if="tables.room.length">
      Зал уже забронирован!
    </h3>
    <div class="row">
      <div
        class="col s2 offset-s5 center modal-trigger"
        data-target="modal8"
        :class="{
          green: !tables.table_8.length,
          red: tables.table_8.length,
        }"
      >
        8
      </div>
    </div>
    <div class="row pull">
      <div
        class="col s2 offset-s1 center modal-trigger"
        data-target="modal11"
        :class="{
          green: !tables.pull.length,
          red: tables.pull.length,
        }"
      >
        Pull
      </div>

      <div
        class="col s2 offset-s7 center modal-trigger"
        data-target="modal9"
        :class="{
          green: !tables.table_9.length,
          red: tables.table_9.length,
        }"
      >
        9
      </div>
    </div>
    <div class="row">
      <div
        class="col s2 offset-s5 center modal-trigger"
        data-target="modal10"
        :class="{
          green: !tables.table_10.length,
          red: tables.table_10.length,
        }"
      >
        10
      </div>
    </div>
    <div class="divider"></div>

    <div class="row">
      <div
        class="col s3 center modal-trigger"
        data-target="modal1"
        :class="{
          green: !tables.table_1.length,
          red: tables.table_1.length,
        }"
      >
        1
      </div>
      <div
        class="col s2 offset-s7 center circle modal-trigger"
        data-target="modal2"
        :class="{
          green: !tables.table_2.length,
          red: tables.table_2.length,
        }"
      >
        2
      </div>
    </div>
    <div class="row"></div>
    <div class="row">
      <div
        class="col s3 center modal-trigger"
        data-target="modal3"
        :class="{
          green: !tables.table_3.length,
          red: tables.table_3.length,
        }"
      >
        3
      </div>
      <div
        class="col s2 offset-s1 center circle modal-trigger"
        data-target="modal4"
        :class="{
          green: !tables.table_4.length,
          red: tables.table_4.length,
        }"
      >
        4
      </div>
      <div
        class="col s4 center modal-trigger"
        data-target="modal5"
        :class="{
          green: !tables.table_5.length,
          red: tables.table_5.length,
        }"
      >
        5
      </div>
      <div
        class="col s2 center circle modal-trigger"
        data-target="modal6"
        :class="{
          green: !tables.table_6.length,
          red: tables.table_6.length,
        }"
      >
        6
      </div>
    </div>
    <div class="row"></div>
    <div class="row">
      <div
        class="col s2 center circle modal-trigger"
        data-target="modal7"
        :class="{
          green: !tables.table_7.length,
          red: tables.table_7.length,
        }"
      >
        7
      </div>
    </div>
    <ModalApp
      v-for="table in tablesList"
      :key="table.key"
      :table="table.items"
      :numberTable="table.number"
      @del="delReserve"
      @creat="creatReserve"
    />
  </main>
</template>

<script setup>
import { computed, reactive, ref, watch } from "vue";
import { useStore } from "vuex";
import ModalApp from "./ModalApp.vue";
import PreloaderApp from "./PreloaderApp.vue";
import { sendPushMessage } from "@/telegram/telegramSendMessage";

const store = useStore();
const loading = ref(false);
const reservations = ref([]);

const date = computed(() => store.getters.date);
const storeReservations = computed(() => store.getters.reservation || []);

const tables = reactive({
  table_1: [],
  table_2: [],
  table_3: [],
  table_4: [],
  table_5: [],
  table_6: [],
  table_7: [],
  table_8: [],
  table_9: [],
  table_10: [],
  pull: [],
  room: [],
});

const tablesList = computed(() => [
  { key: "table_1", number: 1, items: tables.table_1 },
  { key: "table_2", number: 2, items: tables.table_2 },
  { key: "table_3", number: 3, items: tables.table_3 },
  { key: "table_4", number: 4, items: tables.table_4 },
  { key: "table_5", number: 5, items: tables.table_5 },
  { key: "table_6", number: 6, items: tables.table_6 },
  { key: "table_7", number: 7, items: tables.table_7 },
  { key: "table_8", number: 8, items: tables.table_8 },
  { key: "table_9", number: 9, items: tables.table_9 },
  { key: "table_10", number: 10, items: tables.table_10 },
  { key: "pull", number: 11, items: tables.pull },
  { key: "room", number: 12, items: tables.room },
]);

const filterByTable = (tableId) =>
  reservations.value.filter((item) => item.table === tableId);

const populateTables = () => {
  tables.table_1 = filterByTable("1");
  tables.table_2 = filterByTable("2");
  tables.table_3 = filterByTable("3");
  tables.table_4 = filterByTable("4");
  tables.table_5 = filterByTable("5");
  tables.table_6 = filterByTable("6");
  tables.table_7 = filterByTable("7");
  tables.table_8 = filterByTable("8");
  tables.table_9 = filterByTable("9");
  tables.table_10 = filterByTable("10");
  tables.pull = filterByTable("11");
  tables.room = filterByTable("12");
};

const fetchReservations = async () => {
  if (!date.value) return;
  loading.value = true;
  try {
    const data = await store.dispatch("fetchInfo");
    reservations.value = data || [];
  } catch (error) {
    console.log(error);
  } finally {
    loading.value = false;
  }
};

const delReserve = async ({ id }) => {
  if (!id) return;
  loading.value = true;
  try {
    const status = await store.dispatch("delInfo", { id });
    if (status === 204 || status === "204") {
      await fetchReservations();
      alert("Бронь удалена");
    } else {
      alert(status);
    }
  } finally {
    loading.value = false;
  }
};

const creatReserve = async (data) => {
  if (!data.time || !data.person) {
    alert("Укажите время и количество гостей");
    return;
  }
  loading.value = true;
  try {
    const status = await store.dispatch("creatInfo", { data });
    if (status === 201 || status === "201") {
      await fetchReservations();
      alert("Бронь создана");
      sendPushMessage(data, date.value).catch((error) => console.log(error));
    } else {
      alert(status);
    }
  } finally {
    loading.value = false;
  }
};

watch(date, () => fetchReservations(), { immediate: true });
watch(
  reservations,
  () => populateTables(),
  { immediate: true, deep: true }
);
watch(
  storeReservations,
  (value) => {
    reservations.value = value;
  },
  { immediate: true, deep: true }
);
</script>

<style lang="scss" scoped></style>
