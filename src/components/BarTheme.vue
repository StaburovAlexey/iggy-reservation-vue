<template>
  <div class="plan" v-loading="loading">
    <div class="plan__header">
      <p class="plan__title">План зала</p>
      <el-button
        class="room-button"
        :type="isRoomReserved ? 'danger' : 'success'"
        @click="openRoom"
      >
        Бронь комнаты
      </el-button>
      <p class="plan__subtitle">Нажмите на стол или зал, чтобы открыть бронь</p>
    </div>

    <div class="plan__canvas">
      <svg
        width="100%"
        viewBox="0 0 214 325"
        preserveAspectRatio="xMidYMid meet"
        xmlns="http://www.w3.org/2000/svg"
      >
        <rect x="0" y="0" width="100%" fill="var(--canvas-bg)" />
        <line x1="0" y1="120" x2="100%" y2="120" stroke="var(--border-color)" stroke-width="2" />

        <!-- Зал (12) -->
        <g class="hall" @click="openRoom" v-if="!isRoomReserved">
          <rect x="0" y="0" width="100%" height="120" fill="url(#hallGradient)" />
        </g>

        <g
          v-for="table in svgTables"
          :key="table.id"
          :transform="table.transform"
          class="table-node"
          @click="openTable(table.id)"
        >
          <component
            :is="table.shape"
            v-bind="table.shapeProps"
            :fill="tableColor(table.id)"
            stroke="#111827"
            stroke-width="2"
          />
          <text x="0" y="4" text-anchor="middle" font-size="12" fill="#0b1220" font-weight="700">
            {{ table.label }}
          </text>
        </g>
        <g class="hall" @click="openRoom" v-if="isRoomReserved">
          <rect x="0" y="0" width="100%" height="120" fill="url(#hallGradient)" />
          <text x="50%" y="60" text-anchor="middle" font-size="22" fill="#fff" font-weight="700">
            Комната занята
          </text>
        </g>
        <defs>
          <linearGradient id="hallGradient" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" :stop-color="isRoomReserved ? '#ef4444' : '#22c55e'" stop-opacity="0.65" />
            <stop offset="100%" stop-color="#0b1220" stop-opacity="0.6" />
          </linearGradient>
        </defs>
      </svg>
    </div>

    <ModalApp
      v-if="selectedTable"
      v-model="dialogVisible"
      :table="selectedTableReservations"
      :numberTable="selectedTable"
      @del="delReserve"
      @creat="creatReserve"
    />
  </div>
</template>

<script setup>
import { computed, reactive, ref, watch, defineExpose } from "vue";
import { storeToRefs } from "pinia";
import { ElMessage } from "element-plus";
import ModalApp from "./ModalApp.vue";
import { sendPushMessage } from "@/telegram/telegramSendMessage";
import { useDataStore } from "@/store/dataBase";
import { useAuthStore } from "@/store/auth";

const dataStore = useDataStore();
const authStore = useAuthStore();
const { date, reservation: storeReservation } = storeToRefs(dataStore);
const { user } = storeToRefs(authStore);
const loading = ref(false);
const dialogVisible = ref(false);
const selectedTable = ref("");
const reservations = ref([]);
const userId = computed(() => user.value?.uuid);

const storeReservations = computed(() => storeReservation.value || []);

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

const svgTables = [
  { id: "11", label: "Pull", shape: "rect", transform: "translate(35,60)", shapeProps: { x: -20, y: -15, width: 40, height: 30, rx: 6 } },
  { id: "8", label: "8", shape: "rect", transform: "translate(107,40)", shapeProps: { x: -20, y: -15, width: 40, height: 30, rx: 6 } },
  { id: "9", label: "9", shape: "rect", transform: "translate(170,60)", shapeProps: { x: -20, y: -15, width: 40, height: 30, rx: 6 } },
  { id: "10", label: "10", shape: "rect", transform: "translate(107,90)", shapeProps: { x: -20, y: -15, width: 40, height: 30, rx: 6 } },
  { id: "1", label: "1", shape: "rect", transform: "translate(35,140)", shapeProps: { x: -30, y: -15, width: 60, height: 30, rx: 6 } },
  { id: "2", label: "2", shape: "circle", transform: "translate(190,140)", shapeProps: { r: 16 } },
  { id: "3", label: "3", shape: "rect", transform: "translate(35,210)", shapeProps: { x: -30, y: -15, width: 60, height: 30, rx: 6 } },
  { id: "4", label: "4", shape: "circle", transform: "translate(90,210)", shapeProps: { r: 16 } },
  { id: "5", label: "5", shape: "rect", transform: "translate(140,210)", shapeProps: { x: -30, y: -15, width: 60, height: 30, rx: 6 } },
  { id: "6", label: "6", shape: "circle", transform: "translate(190,210)", shapeProps: { r: 16 } },
  { id: "7", label: "7", shape: "circle", transform: "translate(35,280)", shapeProps: { r: 16 } },
];

const selectedTableReservations = computed(() =>
  selectedTable.value ? filterByTable(selectedTable.value) : []
);

const isRoomReserved = computed(() => tables.room.length > 0);

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
    const data = await dataStore.fetchInfo();
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
    const status = await dataStore.delInfo({ id });
    if (status === 204 || status === "204") {
      await fetchReservations();
      ElMessage.success("Бронь удалена");
    } else {
      ElMessage.error(status);
    }
  } finally {
    loading.value = false;
  }
};

const creatReserve = async (data) => {
  const targetTable = data.numTable || selectedTable.value;
  if (!data.time || !data.tel) {
    ElMessage.warning("Заполните время и телефон");
    return;
  }
  if (!userId?.value) {
    ElMessage.error("Не удалось определить пользователя и передать id");
    return;
  }
  loading.value = true;
  try {
    const status = await dataStore.creatInfo({
      data: { ...data, numTable: targetTable, user_id: userId.value },
    });
    if (status === 201 || status === "201") {
      await fetchReservations();
      ElMessage.success("Бронь добавлена");
      // sendPushMessage({ ...data, numTable: targetTable }, date.value).catch(
      //   (error) => console.log(error)
      // );
    } else {
      ElMessage.error(status);
    }
  } finally {
    loading.value = false;
  }
};

const tableColor = (tableId) => {
  const has = filterByTable(tableId).length > 0;
  if (tableId === "12") return has ? "#ef4444" : "#22c55e";
  return has ? "#ef4444" : "#38bdf8";
};

const openTable = (tableId) => {
  selectedTable.value = String(tableId);
  dialogVisible.value = true;
};

const openRoom = () => openTable("12");

defineExpose({ openRoom });

watch(date, () => fetchReservations(), { immediate: true });
watch(reservations, () => populateTables(), { immediate: true, deep: true });
watch(
  storeReservations,
  (value) => {
    reservations.value = value || [];
  },
  { immediate: true, deep: true }
);
</script>

<style lang="scss" scoped>
.plan {
  background: linear-gradient(180deg, var(--gradient-start) 0%, var(--gradient-end) 100%);
  padding: 0 16px;
  flex: 1;
  color: var(--text-primary);
  box-shadow: 0 12px 32px rgba(0, 0, 0, 0.25);
}

.plan__header {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 5px;
  align-items: center;
  justify-content: space-between;
  margin: 10px;
}

.room-button {
  justify-self: end;
}

.plan__title {
  font-size: 20px;
  font-weight: 700;
  margin: 0;
}

.plan__subtitle {
  grid-column: 1/3;
  color: var(--text-secondary);
  font-size: 10px;
  margin: 0;
}

.plan__canvas {
  max-height: 70vh;
}

.plan__canvas svg {
  width: 100%;
  height: auto;
  max-height: 100%;
  aspect-ratio: 214 / 325;
}

.plan__canvas {
  display: flex;
  flex-direction: column;
  justify-items: center;
  align-items: center;
  position: relative;
  border: 1px solid var(--border-color);
  border-radius: 12px;
  overflow: hidden;
  height: auto;
  background: var(--canvas-bg);
}

svg {
  width: 100%;
  height: 100%;
}

.table-node {
  cursor: pointer;
  transition: transform 0.2s ease, filter 0.2s ease;
}

// .table-node:hover {
//   transform: scale(1.05);
//   filter: drop-shadow(0 0 6px rgba(59, 130, 246, 0.35));
// }

.hall {
  cursor: pointer;
}
</style>
