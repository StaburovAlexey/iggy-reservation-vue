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
            stroke="#111827"
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
        <h3 class="panel-title">Параметры стола</h3>
        <el-select v-model="selectedId" placeholder="Выберите стол" size="small">
          <el-option
            v-for="table in tables"
            :key="table.id"
            :label="`Стол ${table.label}`"
            :value="table.id"
          />
        </el-select>

        <div v-if="currentTable" class="panel-grid">
          <el-input-number v-model="currentTable.x" :min="0" :max="schemaSize.width" label="X" size="small" />
          <el-input-number v-model="currentTable.y" :min="0" :max="schemaSize.height" label="Y" size="small" />
          <el-color-picker v-model="currentTable.color" size="small" />

          <template v-if="currentTable.shape === 'rect'">
            <el-input-number v-model="currentTable.width" :min="10" label="Ширина" size="small" />
            <el-input-number v-model="currentTable.height" :min="10" label="Высота" size="small" />
            <el-input-number v-model="currentTable.rx" :min="0" :max="30" label="Скругление" size="small" />
          </template>

          <template v-else>
            <el-input-number v-model="currentTable.r" :min="8" :max="60" label="Радиус" size="small" />
          </template>
          <el-input-number v-model="currentTable.z" :min="0" label="Z" size="small" />
        </div>
        <div v-if="currentTable" class="schema-editor__actions schema-editor__actions--gap">
          <el-button type="danger" size="small" @click="deleteTable(currentTable.id)">Удалить стол</el-button>
        </div>
      </div>

      <div class="panel-block">
        <h3 class="panel-title">Сепараторы</h3>
        <el-select v-model="selectedSeparatorId" placeholder="Выберите линию" size="small">
          <el-option
            v-for="separator in separators"
            :key="separator.id"
            :label="`Линия ${separator.id}`"
            :value="separator.id"
          />
        </el-select>
        <div v-if="currentSeparator" class="panel-grid">
          <template v-if="currentSeparator.orientation === 'v'">
            <el-input-number v-model="currentSeparator.x" :min="0" :max="schemaSize.width" label="X" size="small" />
          </template>
          <template v-else>
            <el-input-number v-model="currentSeparator.y" :min="0" :max="schemaSize.height" label="Y" size="small" />
          </template>
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

      <div class="panel-block">
        <h3 class="panel-title">Создание</h3>
        <div class="panel-grid">
          <el-input v-model="newTable.label" placeholder="Название/номер стола" size="small" />
          <el-select v-model="newTable.shape" placeholder="Форма стола" size="small">
            <el-option label="Прямоугольник" value="rect" />
            <el-option label="Круг" value="circle" />
          </el-select>
          <el-color-picker v-model="newTable.color" size="small" />

          <template v-if="newTable.shape === 'rect'">
            <el-input-number v-model="newTable.width" :min="10" label="Ширина" size="small" />
            <el-input-number v-model="newTable.height" :min="10" label="Высота" size="small" />
            <el-input-number v-model="newTable.rx" :min="0" :max="30" label="Скругление" size="small" />
          </template>
          <template v-else>
            <el-input-number v-model="newTable.r" :min="8" :max="60" label="Радиус" size="small" />
          </template>
          <el-input-number v-model="newTable.z" :min="0" label="Z" size="small" />
        </div>

        <div class="schema-editor__actions schema-editor__actions--gap">
          <el-button type="primary" size="small" @click="addTable">Добавить стол</el-button>
        </div>

        <div class="panel-divider panel-divider--sub"></div>

        <div class="panel-grid">
          <el-input-number
            v-model="newSeparator.pos"
            :min="0"
            :max="newSeparator.orientation === 'v' ? schemaSize.width : schemaSize.height"
            :label="newSeparator.orientation === 'v' ? 'X новой линии' : 'Y новой линии'"
            size="small"
          />
          <el-select v-model="newSeparator.orientation" placeholder="Ориентация линии" size="small">
            <el-option label="Горизонтальная" value="h" />
            <el-option label="Вертикальная" value="v" />
          </el-select>
        </div>

        <div class="schema-editor__actions schema-editor__actions--gap">
          <el-button type="primary" size="small" @click="addSeparator">Добавить линию</el-button>
          <el-button size="small" @click="resetLayout">Сбросить схему</el-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onBeforeUnmount, reactive, ref } from "vue";

const schemaSize = { width: 214, height: 325 };

const initialTables = [
  { id: "11", label: "Pull", shape: "rect", x: 35, y: 60, width: 40, height: 30, rx: 6, z: 2, color: defaultTableColor },
  { id: "8", label: "8", shape: "rect", x: 107, y: 40, width: 40, height: 30, rx: 6, z: 2, color: defaultTableColor },
  { id: "9", label: "9", shape: "rect", x: 170, y: 60, width: 40, height: 30, rx: 6, z: 2, color: defaultTableColor },
  { id: "10", label: "10", shape: "rect", x: 107, y: 90, width: 40, height: 30, rx: 6, z: 2, color: defaultTableColor },
  { id: "1", label: "1", shape: "rect", x: 35, y: 140, width: 60, height: 30, rx: 6, z: 2, color: defaultTableColor },
  { id: "2", label: "2", shape: "circle", x: 190, y: 140, r: 16, z: 2, color: defaultTableColor },
  { id: "3", label: "3", shape: "rect", x: 35, y: 210, width: 60, height: 30, rx: 6, z: 2, color: defaultTableColor },
  { id: "4", label: "4", shape: "circle", x: 90, y: 210, r: 16, z: 2, color: defaultTableColor },
  { id: "5", label: "5", shape: "rect", x: 140, y: 210, width: 60, height: 30, rx: 6, z: 2, color: defaultTableColor },
  { id: "6", label: "6", shape: "circle", x: 190, y: 210, r: 16, z: 2, color: defaultTableColor },
  { id: "7", label: "7", shape: "circle", x: 35, y: 280, r: 16, z: 2, color: defaultTableColor },
  { id: "12", label: "Room", shape: "rect", x: 107, y: 60, width: 214, height: 120, rx: 12, z: 1, color: "#a78bfa" },
];

const defaultTableColor = "#38bdf8";
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
    const za = a.z ?? 0;
    const zb = b.z ?? 0;
    return za === zb ? a.id.localeCompare(b.id) : za - zb;
  })
);

const currentSeparator = computed(
  () => separators.value.find((item) => item.id === selectedSeparatorId.value) || null
);

const newTable = reactive({
  label: "",
  shape: "rect",
  width: 40,
  height: 30,
  rx: 6,
  r: 16,
  z: 2,
  color: defaultTableColor,
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

const tableFill = (id) => {
  const table = tables.value.find((item) => item.id === id);
  const color = table?.color || defaultTableColor;
  return color;
};

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
    table.x = clamp(lastMove.x - dragState.offsetX, 0, schemaSize.width);
    table.y = clamp(lastMove.y - dragState.offsetY, 0, schemaSize.height);
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
};

const addTable = () => {
  const label = newTable.label.trim() || String(tables.value.length + 1);
  const shape = newTable.shape === "circle" ? "circle" : "rect";
  const base = {
    id: `${Date.now()}`,
    label,
    shape,
    x: schemaSize.width / 2,
    y: schemaSize.height / 2,
    z: Number.isFinite(newTable.z) ? newTable.z : 2,
    color: newTable.color || defaultTableColor,
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
  newTable.label = "";
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

.schema-editor__actions {
  display: flex;
  justify-content: flex-end;
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
