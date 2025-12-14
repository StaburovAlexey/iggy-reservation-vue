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
        <line
          v-for="line in separatorLines"
          :key="line.id"
          :x1="line.orientation === 'v' ? line.x : 0"
          :y1="line.orientation === 'v' ? 0 : line.y"
          :x2="line.orientation === 'v' ? line.x : SCHEMA_WIDTH"
          :y2="line.orientation === 'v' ? SCHEMA_HEIGHT : line.y"
          :stroke-width="line.thickness || 2"
          stroke="var(--border-color)"
        />

        <!-- Зал (12) -->

        <g
          v-for="table in tablesWithFill.tables"
          :key="table.id"
          :transform="table.transform"
          class="table-node"
          @click="openTable(table.id)"
        >
          <component
            :is="table.shape"
            v-bind="table.shapeProps"
            :fill="table.fill"
            :fill-opacity="table.fillOpacity"
            stroke="#111827"
            :stroke-opacity="table.fillOpacity"
            stroke-width="2"
          />
          <text x="0" y="4" text-anchor="middle" font-size="12" fill="#0b1220" font-weight="700">
            {{ table.label }}
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
import { computed, reactive, ref, watch, onMounted, onUnmounted } from "vue";
import { storeToRefs } from "pinia";
import { ElMessage } from "element-plus";
import ModalApp from "./ModalApp.vue";
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

const STORAGE_KEY = "schema-config";
const SCHEMA_WIDTH = 214;
const SCHEMA_HEIGHT = 325;

const normalizeOpacity = (value) => {
  const num = Number(value);
  if (!Number.isFinite(num)) return 1;
  return Math.max(0, Math.min(1, num));
};

const defaultTables = [
  { id: "11", label: "Pull", shape: "rect", x: 35, y: 60, width: 40, height: 30, rx: 6, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "8", label: "8", shape: "rect", x: 107, y: 40, width: 40, height: 30, rx: 6, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "9", label: "9", shape: "rect", x: 170, y: 60, width: 40, height: 30, rx: 6, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "10", label: "10", shape: "rect", x: 107, y: 90, width: 40, height: 30, rx: 6, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "1", label: "1", shape: "rect", x: 35, y: 140, width: 60, height: 30, rx: 6, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "2", label: "2", shape: "circle", x: 190, y: 140, r: 16, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "3", label: "3", shape: "rect", x: 35, y: 210, width: 60, height: 30, rx: 6, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "4", label: "4", shape: "circle", x: 90, y: 210, r: 16, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "5", label: "5", shape: "rect", x: 140, y: 210, width: 60, height: 30, rx: 6, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "6", label: "6", shape: "circle", x: 190, y: 210, r: 16, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "7", label: "7", shape: "circle", x: 35, y: 280, r: 16, z: 2, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
  { id: "12", label: "12", shape: "rect", x: SCHEMA_WIDTH / 2, y: 60, width: SCHEMA_WIDTH, height: 120, rx: 12, z: 1, zBooked: null, colorBase: "#38bdf8", colorBooked: "#ef4444", opacityBase: 1, opacityBooked: 1 },
];

const schemaConfig = ref(null);
const defaultSeparators = [{ id: "sep-1", orientation: "h", y: 120, x: SCHEMA_WIDTH / 2, thickness: 2 }];

const tablesWithFill = computed(() => {
  const source = schemaConfig.value?.tables;
  const globals = schemaConfig.value?.colors || {};
  const baseDefault = globals.base || "#38bdf8";
  const bookedDefault = globals.booked || "#ef4444";

  const mapTable = (table) => {
    const shape = table.shape === "circle" ? "circle" : "rect";
    const z = table.z ?? 0;
    const zBooked = table.zBooked;
    const isBooked = filterByTable(String(table.id)).length > 0;
    const effectiveZ = isBooked && Number.isFinite(zBooked) ? zBooked : z;

    const baseColor = table.colorBase || baseDefault;
    const bookedColor = table.colorBooked || bookedDefault;
    const baseOpacity = normalizeOpacity(table.opacityBase);
    const bookedOpacity = normalizeOpacity(table.opacityBooked);

    const primaryColor = isBooked ? bookedColor : baseColor;
    const opacity = isBooked ? bookedOpacity : baseOpacity;
    const fill = primaryColor;

    if (shape === "circle") {
      return {
        id: String(table.id),
        label: table.label || String(table.id),
        shape,
        z: effectiveZ,
        fill,
        fillOpacity: opacity,
        transform: `translate(${table.x ?? 0},${table.y ?? 0})`,
        shapeProps: { r: table.r ?? 16 },
      };
    }
    const width = table.width ?? 40;
    const height = table.height ?? 30;
    return {
      id: String(table.id),
      label: table.label || String(table.id),
      shape,
      z: effectiveZ,
      fill,
      fillOpacity: opacity,
      transform: `translate(${table.x ?? 0},${table.y ?? 0})`,
      shapeProps: { x: -width / 2, y: -height / 2, width, height, rx: table.rx ?? 6 },
    };
  };

  const tablesSource = Array.isArray(source) && source.length ? source : defaultTables;
  const normalized = tablesSource
    .map((item) => mapTable(item))
    .sort((a, b) => (a.z ?? 0) - (b.z ?? 0) || a.id.localeCompare(b.id));

  return { tables: normalized, gradients: [] };
});

const separatorLines = computed(() => {
  const source = schemaConfig.value?.separators;
  const lines = Array.isArray(source) && source.length ? source : defaultSeparators;
  return lines.map((line) => ({
    id: line.id || `sep-${line.orientation || "h"}-${line.y ?? line.x ?? 0}`,
    orientation: line.orientation === "v" ? "v" : "h",
    x: line.x ?? SCHEMA_WIDTH / 2,
    y: line.y ?? SCHEMA_HEIGHT / 2,
    thickness: line.thickness || 2,
  }));
});

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
    } else {
      ElMessage.error(status);
    }
  } finally {
    loading.value = false;
  }
};

const tableColor = (tableId) => {
  const has = filterByTable(tableId).length > 0;
  const baseColor = schemaConfig.value?.colors?.base || "#38bdf8";
  const bookedColor = schemaConfig.value?.colors?.booked || "#ef4444";
  if (tableId === "12") return has ? bookedColor : "#22c55e";
  return has ? bookedColor : baseColor;
};

const openTable = (tableId) => {
  selectedTable.value = String(tableId);
  dialogVisible.value = true;
};

const openRoom = () => openTable("12");

defineExpose({ openRoom });

const loadSchema = () => {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return;
    schemaConfig.value = JSON.parse(raw);
  } catch (error) {
    console.log(error);
  }
};

onMounted(() => {
  loadSchema();
  window.addEventListener("storage", loadSchema);
});

onUnmounted(() => {
  window.removeEventListener("storage", loadSchema);
});

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
