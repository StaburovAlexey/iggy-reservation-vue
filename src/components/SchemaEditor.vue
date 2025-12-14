<template>
  <div class="schema-editor">
    <div
      class="schema-editor__canvas"
      @pointermove="onPointerMove"
      @pointerup="stopDrag"
      @pointerleave="stopDrag"
    >
      <svg
        ref="svgRef"
        viewBox="0 0 214 325"
        xmlns="http://www.w3.org/2000/svg"
        class="schema-editor__svg"
      >
        <rect x="0" y="0" width="214" height="325" class="schema-editor__bg" />
        <line
          v-for="separator in separators"
          :key="separator.id"
          :x1="separator.orientation === 'v' ? separator.x : 0"
          :y1="separator.orientation === 'v' ? 0 : separator.y"
          :x2="separator.orientation === 'v' ? separator.x : schemaSize.width"
          :y2="separator.orientation === 'v' ? schemaSize.height : separator.y"
          :stroke-width="separator.thickness || 2"
          class="schema-editor__separator"
          @pointerdown.prevent.stop="startDragSeparator(separator, $event)"
        />
        <g
          v-for="table in sortedTables"
          :key="table.id"
          :transform="`translate(${table.x}, ${table.y})`"
          class="table-node"
          :class="{ 'table-node--selected': table.id === selectedId }"
          @pointerdown.prevent.stop="startDrag(table, $event)"
        >
          <component
            :is="table.shape"
            v-bind="shapeAttrs(table)"
            :fill="tableFill(table.id)"
            :fill-opacity="tableOpacity(table)"
            stroke="#111827"
            :stroke-opacity="tableOpacity(table)"
            stroke-width="2"
          />
          <text x="0" y="4" text-anchor="middle" font-size="12" fill="#0b1220" font-weight="700">
            {{ table.label }}
          </text>
        </g>
      </svg>
    </div>
    <div class="schema-editor__panel">
      <div class="panel-block">
        <h3 class="panel-title">Цвета столов</h3>
        <div class="color-row">
          <span>Обычный</span>
          <el-color-picker v-model="colors.base" size="small" />
        </div>
        <div class="color-row">
          <span>Забронирован</span>
          <el-color-picker v-model="colors.booked" size="small" />
        </div>
      </div>

      <div class="panel-block">
        <h3 class="panel-title">Управление схемой</h3>
        <div class="schema-editor__actions schema-editor__actions--gap">
          <el-button size="small" @click="emitSaveSchema">Сохранить схему</el-button>
          <el-button type="warning" size="small" @click="resetLayout">Сбросить схему</el-button>
        </div>
      </div>

      <div class="panel-block">
        <h3 class="panel-title">Параметры стола</h3>
        <div class="field">
          <span class="field-label">Выберите стол</span>
          <el-select v-model="selectedId" placeholder="Стол" size="small">
            <el-option
              v-for="table in tables"
              :key="table.id"
              :label="`Стол ${table.label}`"
              :value="table.id"
            />
          </el-select>
        </div>

        <div v-if="currentTable" class="panel-grid">
          <div class="field">
            <span class="field-label">ID стола</span>
            <el-input v-model="currentTable.id" size="small" @input="onTableIdChange" />
          </div>
          <div class="field">
            <span class="field-label">Название/номер</span>
            <el-input v-model="currentTable.label" size="small" />
          </div>
          <div class="field">
            <span class="field-label">X</span>
            <el-input-number v-model="currentTable.x" :min="0" :max="schemaSize.width" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Y</span>
            <el-input-number v-model="currentTable.y" :min="0" :max="schemaSize.height" size="small" />
          </div>

          <template v-if="currentTable.shape === 'rect'">
            <div class="field">
              <span class="field-label">Ширина</span>
              <el-input-number v-model="currentTable.width" :min="10" size="small" />
            </div>
            <div class="field">
              <span class="field-label">Высота</span>
              <el-input-number v-model="currentTable.height" :min="10" size="small" />
            </div>
            <div class="field">
              <span class="field-label">Скругление</span>
              <el-input-number v-model="currentTable.rx" :min="0" :max="30" size="small" />
            </div>
          </template>

          <template v-else>
            <div class="field">
              <span class="field-label">Радиус</span>
              <el-input-number v-model="currentTable.r" :min="8" :max="60" size="small" />
            </div>
          </template>
          <div class="field">
            <span class="field-label">Z-слой</span>
            <el-input-number v-model="currentTable.z" :min="0" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Z при брони</span>
            <el-input-number v-model="currentTable.zBooked" :min="0" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Цвет (обычный)</span>
            <el-color-picker v-model="currentTable.colorBase" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Прозрачность (обычный)</span>
            <el-input-number v-model="currentTable.opacityBase" :min="0" :max="1" :step="0.05" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Цвет (бронирован)</span>
            <el-color-picker v-model="currentTable.colorBooked" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Прозрачность (бронирован)</span>
            <el-input-number v-model="currentTable.opacityBooked" :min="0" :max="1" :step="0.05" size="small" />
          </div>
        </div>
        <div v-if="currentTable" class="schema-editor__actions schema-editor__actions--gap">
          <el-checkbox v-model="currentTable.booked">Забронирован (превью)</el-checkbox>
          <el-button type="danger" size="small" @click="deleteTable(currentTable.id)">Удалить стол</el-button>
        </div>
      </div>

      <div class="panel-block">
        <h3 class="panel-title">Сепараторы</h3>
        <div class="field">
          <span class="field-label">Выберите линию</span>
          <el-select v-model="selectedSeparatorId" placeholder="Линия" size="small">
            <el-option
              v-for="separator in separators"
              :key="separator.id"
              :label="`Линия ${separator.id}`"
              :value="separator.id"
            />
          </el-select>
        </div>
        <div v-if="currentSeparator" class="panel-grid">
          <template v-if="currentSeparator.orientation === 'v'">
            <div class="field">
              <span class="field-label">X линии</span>
              <el-input-number v-model="currentSeparator.x" :min="0" :max="schemaSize.width" size="small" />
            </div>
          </template>
          <template v-else>
            <div class="field">
              <span class="field-label">Y линии</span>
              <el-input-number v-model="currentSeparator.y" :min="0" :max="schemaSize.height" size="small" />
            </div>
          </template>
          <div class="field">
            <span class="field-label">Ориентация</span>
            <el-select
              v-model="currentSeparator.orientation"
              placeholder="Ориентация"
              size="small"
              @change="onSeparatorOrientationChange"
            >
              <el-option label="Горизонтальная" value="h" />
              <el-option label="Вертикальная" value="v" />
            </el-select>
          </div>
        </div>
      </div>

      <div class="panel-block">
        <h3 class="panel-title">Создание</h3>
        <div class="panel-grid">
          <div class="field">
            <span class="field-label">ID стола</span>
            <el-input v-model="newTable.id" placeholder="Оставьте пустым для авто" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Название/номер стола</span>
            <el-input v-model="newTable.label" placeholder="Например, 5" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Форма стола</span>
            <el-select v-model="newTable.shape" placeholder="Форма" size="small">
              <el-option label="Прямоугольник" value="rect" />
              <el-option label="Круг" value="circle" />
            </el-select>
          </div>

          <template v-if="newTable.shape === 'rect'">
            <div class="field">
              <span class="field-label">Ширина</span>
              <el-input-number v-model="newTable.width" :min="10" size="small" />
            </div>
            <div class="field">
              <span class="field-label">Высота</span>
              <el-input-number v-model="newTable.height" :min="10" size="small" />
            </div>
            <div class="field">
              <span class="field-label">Скругление</span>
              <el-input-number v-model="newTable.rx" :min="0" :max="30" size="small" />
            </div>
          </template>
          <template v-else>
            <div class="field">
              <span class="field-label">Радиус</span>
              <el-input-number v-model="newTable.r" :min="8" :max="60" size="small" />
            </div>
          </template>
          <div class="field">
            <span class="field-label">Z-слой</span>
            <el-input-number v-model="newTable.z" :min="0" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Z при брони</span>
            <el-input-number v-model="newTable.zBooked" :min="0" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Цвет (обычный)</span>
            <el-color-picker v-model="newTable.colorBase" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Прозрачность (обычный)</span>
            <el-input-number v-model="newTable.opacityBase" :min="0" :max="1" :step="0.05" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Цвет (бронирован)</span>
            <el-color-picker v-model="newTable.colorBooked" size="small" />
          </div>
          <div class="field">
            <span class="field-label">Прозрачность (бронирован)</span>
            <el-input-number v-model="newTable.opacityBooked" :min="0" :max="1" :step="0.05" size="small" />
          </div>
        </div>

        <div class="schema-editor__actions schema-editor__actions--gap">
          <el-button type="primary" size="small" @click="addTable">Добавить стол</el-button>
        </div>

        <div class="panel-divider panel-divider--sub"></div>

        <div class="panel-grid">
          <div class="field">
            <span class="field-label">{{ newSeparator.orientation === 'v' ? 'X новой линии' : 'Y новой линии' }}</span>
            <el-input-number
              v-model="newSeparator.pos"
              :min="0"
              :max="newSeparator.orientation === 'v' ? schemaSize.width : schemaSize.height"
              size="small"
            />
          </div>
          <div class="field">
            <span class="field-label">Ориентация линии</span>
            <el-select v-model="newSeparator.orientation" placeholder="Ориентация" size="small">
              <el-option label="Горизонтальная" value="h" />
              <el-option label="Вертикальная" value="v" />
            </el-select>
          </div>
        </div>

        <div class="schema-editor__actions schema-editor__actions--gap">
          <el-button type="primary" size="small" @click="addSeparator">Добавить линию</el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from "vue";

const props = defineProps({
  schemaData: {
    type: Object,
    default: () => null,
  },
});

const emit = defineEmits(["save-schema"]);

const schemaSize = { width: 214, height: 325 };

const normalizeOpacity = (value) => {
  const num = Number(value);
  if (!Number.isFinite(num)) return 1;
  return Math.max(0, Math.min(1, num));
};

const initialTables = [
  { id: "11", label: "Pull", shape: "rect", x: 35, y: 60, width: 40, height: 30, rx: 6, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "8", label: "8", shape: "rect", x: 107, y: 40, width: 40, height: 30, rx: 6, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "9", label: "9", shape: "rect", x: 170, y: 60, width: 40, height: 30, rx: 6, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "10", label: "10", shape: "rect", x: 107, y: 90, width: 40, height: 30, rx: 6, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "1", label: "1", shape: "rect", x: 35, y: 140, width: 60, height: 30, rx: 6, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "2", label: "2", shape: "circle", x: 190, y: 140, r: 16, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "3", label: "3", shape: "rect", x: 35, y: 210, width: 60, height: 30, rx: 6, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "4", label: "4", shape: "circle", x: 90, y: 210, r: 16, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "5", label: "5", shape: "rect", x: 140, y: 210, width: 60, height: 30, rx: 6, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "6", label: "6", shape: "circle", x: 190, y: 210, r: 16, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "7", label: "7", shape: "circle", x: 35, y: 280, r: 16, z: 2, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
  { id: "12", label: "Room", shape: "rect", x: 107, y: 60, width: 214, height: 120, rx: 12, z: 1, zBooked: null, colorBase: defaultBaseColor, opacityBase: 1, colorBooked: defaultBookedColor, opacityBooked: 1, booked: false },
];

const defaultBaseColor = "#38bdf8";
const defaultBookedColor = "#ef4444";
const defaultSeparatorThickness = 2;
const initialSeparators = [
  { id: "sep-1", y: 120, x: schemaSize.width / 2, orientation: "h", thickness: defaultSeparatorThickness },
];

const tables = ref(initialTables.map((item) => ({ ...item })));
const selectedId = ref(tables.value[0]?.id || "");
const svgRef = ref(null);
const rafId = ref(0);
const separators = ref(initialSeparators.map((item) => ({ ...item })));
const selectedSeparatorId = ref(separators.value[0]?.id || "");
const colors = reactive({
  base: defaultBaseColor,
  booked: defaultBookedColor,
});

const dragState = reactive({
  active: false,
  id: null,
  type: null,
  pointerId: null,
  offsetX: 0,
  offsetY: 0,
});

const lastMove = reactive({
  x: 0,
  y: 0,
});

const currentTable = computed(() => tables.value.find((table) => table.id === selectedId.value) || null);
const sortedTables = computed(() =>
  [...tables.value].sort((a, b) => {
    const za = tableZ(a);
    const zb = tableZ(b);
    return za === zb ? String(a.id).localeCompare(String(b.id)) : za - zb;
  })
);

const currentSeparator = computed(
  () => separators.value.find((item) => item.id === selectedSeparatorId.value) || null
);

const newTable = reactive({
  id: "",
  label: "",
  shape: "rect",
  width: 40,
  height: 30,
  rx: 6,
  r: 16,
  z: 2,
  zBooked: null,
  colorBase: defaultBaseColor,
  opacityBase: 1,
  colorBooked: defaultBookedColor,
  opacityBooked: 1,
  booked: false,
});
const newSeparator = reactive({
  orientation: "h",
  pos: Math.round(schemaSize.height / 2),
});

const shapeAttrs = (table) => {
  if (table.shape === "circle") {
    return { r: table.r ?? 16, cx: 0, cy: 0 };
  }
  const width = table.width ?? 40;
  const height = table.height ?? 30;
  return { x: -width / 2, y: -height / 2, width, height, rx: table.rx ?? 6 };
};

const tableHalfSize = (table) => {
  if (!table) return { hx: 0, hy: 0 };
  if (table.shape === "circle") {
    const r = Math.max(1, table.r ?? 16);
    return { hx: r, hy: r };
  }
  const width = Math.max(1, table.width ?? 40);
  const height = Math.max(1, table.height ?? 30);
  return { hx: width / 2, hy: height / 2 };
};

const tableBounds = (table) => {
  const { hx, hy } = tableHalfSize(table);
  const minX = hx;
  const maxX = Math.max(hx, schemaSize.width - hx);
  const minY = hy;
  const maxY = Math.max(hy, schemaSize.height - hy);
  return { minX, maxX, minY, maxY };
};

const tableFill = (id) => {
  const table = tables.value.find((item) => item.id === id);
  if (!table) return colors.base;
  const primary = table.booked ? table.colorBooked || colors.booked : table.colorBase || colors.base;
  return primary;
};

const tableOpacity = (table) => {
  const base = normalizeOpacity(table.opacityBase);
  const booked = normalizeOpacity(table.opacityBooked);
  return table.booked ? booked : base;
};

const tableZ = (table) => {
  if (!table) return 0;
  if (table.booked && Number.isFinite(table.zBooked)) return table.zBooked;
  return table.z ?? 0;
};

const schemaPayload = computed(() => ({
  tables: tables.value.map((table) => ({
    id: table.id,
    label: table.label,
    shape: table.shape,
    x: table.x,
    y: table.y,
    width: table.width,
    height: table.height,
    rx: table.rx,
    r: table.r,
    z: table.z,
    zBooked: table.zBooked,
    colorBase: table.colorBase,
    opacityBase: table.opacityBase,
    colorBooked: table.colorBooked,
    opacityBooked: table.opacityBooked,
    booked: table.booked,
  })),
  separators: separators.value.map((item) => ({ ...item })),
  colors: { ...colors },
}));

const clamp = (value, min, max) => Math.max(min, Math.min(max, value));

const clientToSvg = (event) => {
  const rect = svgRef.value?.getBoundingClientRect();
  if (!rect) return { x: 0, y: 0 };
  return {
    x: ((event.clientX - rect.left) / rect.width) * schemaSize.width,
    y: ((event.clientY - rect.top) / rect.height) * schemaSize.height,
  };
};

const startDrag = (table, event) => {
  selectedId.value = table.id;
  const point = clientToSvg(event);
  dragState.active = true;
  dragState.id = table.id;
  dragState.type = "table";
  dragState.pointerId = event.pointerId;
  dragState.offsetX = point.x - table.x;
  dragState.offsetY = point.y - table.y;
  event.currentTarget?.setPointerCapture?.(event.pointerId);
  window.addEventListener("pointermove", onPointerMove);
  window.addEventListener("pointerup", stopDrag);
};

const startDragSeparator = (separator, event) => {
  selectedSeparatorId.value = separator.id;
  const point = clientToSvg(event);
  dragState.active = true;
  dragState.id = separator.id;
  dragState.type = "separator";
  dragState.pointerId = event.pointerId;
  if (separator.orientation === "v") {
    dragState.offsetX = point.x - separator.x;
    dragState.offsetY = 0;
  } else {
    dragState.offsetX = 0;
    dragState.offsetY = point.y - separator.y;
  }
  event.currentTarget?.setPointerCapture?.(event.pointerId);
  window.addEventListener("pointermove", onPointerMove);
  window.addEventListener("pointerup", stopDrag);
};

const onPointerMove = (event) => {
  if (!dragState.active) return;
  const point = clientToSvg(event);
  lastMove.x = point.x;
  lastMove.y = point.y;
  if (rafId.value) return;
  rafId.value = requestAnimationFrame(applyDragPosition);
};

const applyDragPosition = () => {
  rafId.value = 0;
  if (!dragState.active) return;
  if (dragState.type === "table") {
    const table = tables.value.find((item) => item.id === dragState.id);
    if (!table) return;
    const { minX, maxX, minY, maxY } = tableBounds(table);
    table.x = clamp(lastMove.x - dragState.offsetX, minX, maxX);
    table.y = clamp(lastMove.y - dragState.offsetY, minY, maxY);
  } else if (dragState.type === "separator") {
    const separator = separators.value.find((item) => item.id === dragState.id);
    if (!separator) return;
    if (separator.orientation === "v") {
      separator.x = clamp(lastMove.x - dragState.offsetX, 0, schemaSize.width);
    } else {
      separator.y = clamp(lastMove.y - dragState.offsetY, 0, schemaSize.height);
    }
  }
};

const stopDrag = () => {
  dragState.active = false;
  dragState.id = null;
  dragState.type = null;
  dragState.pointerId = null;
  window.removeEventListener("pointermove", onPointerMove);
  window.removeEventListener("pointerup", stopDrag);
  if (rafId.value) {
    cancelAnimationFrame(rafId.value);
    rafId.value = 0;
  }
};

const resetLayout = () => {
  tables.value = initialTables.map((item) => ({ ...item }));
  selectedId.value = tables.value[0]?.id || "";
  separators.value = initialSeparators.map((item) => ({ ...item }));
  selectedSeparatorId.value = separators.value[0]?.id || "";
  newSeparator.orientation = "h";
  newSeparator.pos = Math.round(schemaSize.height / 2);
  newTable.id = "";
  newTable.label = "";
  newTable.shape = "rect";
  newTable.width = 40;
  newTable.height = 30;
  newTable.rx = 6;
  newTable.r = 16;
  newTable.z = 2;
  newTable.zBooked = null;
  newTable.colorBase = defaultBaseColor;
  newTable.opacityBase = 1;
  newTable.colorBooked = defaultBookedColor;
  newTable.opacityBooked = 1;
  colors.base = defaultBaseColor;
  colors.booked = defaultBookedColor;
};

const addTable = () => {
  const customId = (newTable.id || "").trim();
  const label = (newTable.label || "").trim();
  const shape = newTable.shape === "circle" ? "circle" : "rect";
  const base = {
    id: customId || `${Date.now()}`,
    label,
    shape,
    x: schemaSize.width / 2,
    y: schemaSize.height / 2,
    z: Number.isFinite(newTable.z) ? newTable.z : 2,
    zBooked: Number.isFinite(newTable.zBooked) ? newTable.zBooked : null,
    colorBase: newTable.colorBase || defaultBaseColor,
    opacityBase: Number.isFinite(newTable.opacityBase) ? newTable.opacityBase : 1,
    colorBooked: newTable.colorBooked || defaultBookedColor,
    opacityBooked: Number.isFinite(newTable.opacityBooked) ? newTable.opacityBooked : 1,
    booked: false,
  };
  const size =
    shape === "circle"
      ? { r: newTable.r || 16 }
      : {
          width: newTable.width || 40,
          height: newTable.height || 30,
          rx: newTable.rx || 6,
        };
  tables.value.push({ ...base, ...size });
  selectedId.value = base.id;
  newTable.id = "";
  newTable.label = "";
  newTable.shape = "rect";
  newTable.width = 40;
  newTable.height = 30;
  newTable.rx = 6;
  newTable.r = 16;
  newTable.z = 2;
  newTable.zBooked = null;
  newTable.colorBase = defaultBaseColor;
  newTable.opacityBase = 1;
  newTable.colorBooked = defaultBookedColor;
  newTable.opacityBooked = 1;
  colors.base = colors.base || defaultBaseColor;
  colors.booked = colors.booked || defaultBookedColor;
};

const deleteTable = (id) => {
  tables.value = tables.value.filter((table) => table.id !== id);
  if (selectedId.value === id) {
    selectedId.value = tables.value[0]?.id || "";
  }
};

const addSeparator = () => {
  const orientation = newSeparator.orientation === "v" ? "v" : "h";
  const pos =
    orientation === "v"
      ? clamp(newSeparator.pos ?? schemaSize.width / 2, 0, schemaSize.width)
      : clamp(newSeparator.pos ?? schemaSize.height / 2, 0, schemaSize.height);
  const id = `sep-${Date.now()}`;
  const base = {
    id,
    orientation,
    thickness: defaultSeparatorThickness,
    x: schemaSize.width / 2,
    y: Math.round(schemaSize.height / 2),
  };
  if (orientation === "v") {
    base.x = pos;
  } else {
    base.y = pos;
  }
  separators.value.push(base);
  selectedSeparatorId.value = id;
};

const onTableIdChange = (value) => {
  if (!currentTable.value) return;
  const newId = String(value || "").trim();
  if (!newId) {
    // Если поле пустое, не меняем id и возвращаем отображаемое значение
    currentTable.value.id = selectedId.value;
    return;
  }
  selectedId.value = newId;
  currentTable.value.id = newId;
};

const onSeparatorOrientationChange = (value) => {
  const sep = separators.value.find((item) => item.id === selectedSeparatorId.value);
  if (!sep) return;
  const next = value === "v" ? "v" : "h";
  sep.orientation = next;
  if (next === "v" && (sep.x === undefined || sep.x === null)) {
    sep.x = schemaSize.width / 2;
  }
  if (next === "h" && (sep.y === undefined || sep.y === null)) {
    sep.y = schemaSize.height / 2;
  }
};

const emitSaveSchema = () => {
  emit("save-schema", schemaPayload.value);
};

const applySchema = (schema) => {
  if (!schema || typeof schema !== "object") return;
  if (Array.isArray(schema.tables)) {
    tables.value = schema.tables.map((table) => ({ ...table }));
    selectedId.value = tables.value[0]?.id || "";
  }
  if (Array.isArray(schema.separators)) {
    separators.value = schema.separators.map((item) => ({ ...item }));
    selectedSeparatorId.value = separators.value[0]?.id || "";
  }
  if (schema.colors) {
    colors.base = schema.colors.base || defaultBaseColor;
    colors.booked = schema.colors.booked || defaultBookedColor;
  }
};

watch(
  () => props.schemaData,
  (val) => applySchema(val),
  { immediate: true, deep: true }
);

onBeforeUnmount(() => {
  window.removeEventListener("pointermove", onPointerMove);
  window.removeEventListener("pointerup", stopDrag);
  if (rafId.value) cancelAnimationFrame(rafId.value);
});
</script>

<style scoped lang="scss">
.schema-editor {
  display: grid;
  grid-template-columns: 2fr 1fr;
  gap: 16px;
  align-items: start;
}

.schema-editor__canvas {
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: 12px;
  overflow: hidden;
  min-height: 360px;
}

.schema-editor__svg {
  width: 100%;
  height: 100%;
  display: block;
  touch-action: none;
}

.schema-editor__bg {
  fill: var(--canvas-bg, #0b1220);
}

.schema-editor__separator {
  stroke: var(--border-color, #1f2937);
  stroke-width: 2;
}

.table-node {
  cursor: grab;
  transition: transform 0.15s ease, filter 0.15s ease;
}

.table-node--selected {
  filter: drop-shadow(0 0 8px rgba(56, 189, 248, 0.35));
}

.schema-editor__panel {
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: 12px;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  color: var(--text-primary);
}

.panel-title {
  margin: 0;
  font-size: 16px;
}

.panel-block {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 8px;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  background: var(--bg-surface-2);
}

.panel-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 8px;
}

.field {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.field-label {
  font-size: 12px;
  color: var(--text-secondary);
}

.schema-editor__actions {
  display: flex;
  justify-content: flex-end;
}

.color-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.schema-editor__actions--gap {
  gap: 8px;
  flex-wrap: wrap;
}

.panel-divider {
  height: 1px;
  width: 100%;
  background: var(--border-color);
  opacity: 0.6;
}

.panel-divider--sub {
  margin: 4px 0;
  opacity: 0.35;
}

@media (max-width: 720px) {
  .schema-editor {
    grid-template-columns: 1fr;
  }
}
</style>



