<template>
  <main v-if="loading" class="main-loader grey darken-3">
    <PreloaderApp class="big" />
  </main>
  <main v-else class="grey darken-3 main">
    <svg
      width="100%"
      height="100%"
      viewBox="0 0 214 325"
      preserveAspectRatio="xMidYMid meet"
      xmlns="http://www.w3.org/2000/svg"
    >
      <!-- фон -->
      <rect x="0" y="0" width="100%" height="100%" fill="#3f3f3f" />

      <!-- линия между 1 и 2 -->
      <line
        x1="0"
        y1="120"
        x2="100%"
        y2="120"
        stroke="#bfbfbf"
        stroke-width="2"
      />

      <g id="pull" transform="translate(35,60)">
        <rect x="-20" y="-15" width="40" height="30" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          pull
        </text>
      </g>
      <!-- 8 -->
      <g id="8" transform="translate(107,40)">
        <rect x="-20" y="-15" width="40" height="30" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          8
        </text>
      </g>

      <!-- 9 -->
      <g id="9" transform="translate(170,60)">
        <rect x="-20" y="-15" width="40" height="30" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          9
        </text>
      </g>

      <!-- 10 -->
      <g id="10" transform="translate(107,90)">
        <rect x="-20" y="-15" width="40" height="30" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          10
        </text>
      </g>

      <!-- 1 -->
      <g id="1" transform="translate(35,140)">
        <rect x="-30" y="-15" width="60" height="30" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          1
        </text>
      </g>

      <!-- 2 -->
      <g id="2" transform="translate(190,140)">
        <circle r="16" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          2
        </text>
      </g>

      <!-- 3 -->
      <g id="3" transform="translate(35,210)">
        <rect x="-30" y="-15" width="60" height="30" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          3
        </text>
      </g>

      <!-- 4 -->
      <g id="4" transform="translate(90,210)">
        <circle r="16" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          4
        </text>
      </g>

      <!-- 5 -->
      <g id="5" transform="translate(140,210)">
        <rect x="-30" y="-15" width="60" height="30" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          5
        </text>
      </g>

      <!-- 6 -->
      <g id="6" transform="translate(190,210)">
        <circle r="16" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          6
        </text>
      </g>

      <!-- 7 -->
      <g id="7" transform="translate(35,280)">
        <circle r="16" fill="#31c550" />
        <text x="0" y="4" text-anchor="middle" font-size="12" fill="#000">
          7
        </text>
      </g>

      <g id="rent" transform="translate(0,0)">
        <rect id="rent-rect" x="" y="0" width="100%" height="120" />
        <text
          x="50%"
          y="60"
          text-anchor="middle"
          font-size="26"
          fill="#FF2400"
          style=""
        >
          Аренда!
        </text>
      </g>
      <style>
        #rent-rect {
          fill: #000;
          opacity: 0.5;
        }
      </style>
    </svg>
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
watch(reservations, () => populateTables(), { immediate: true, deep: true });
watch(
  storeReservations,
  (value) => {
    reservations.value = value;
  },
  { immediate: true, deep: true }
);
</script>

<style lang="scss" scoped></style>
