<template>
  <el-dialog
    v-model="visible"
    :title="`Стол ${numberTable}`"
    width="min(520px, 95vw)"
    destroy-on-close
  >
    <div class="dialog-grid">
      <div class="dialog-grid__left">
        <div class="dialog-grid__subtitle">Текущие брони</div>
        <el-empty v-if="!table.length" description="Пока нет броней" />
        <el-timeline v-else>
          <el-timeline-item
            v-for="res in table"
            :key="res.id"
            :timestamp="res.time"
            placement="top"
          >
            <div class="booking-card">
              <div class="booking-card__name">{{ res.name || "Без имени" }}</div>
              <div class="booking-card__meta">
                <span>Гостей: {{ res.person || "-" }}</span>
                <span>Телефон: {{ res.phone || "-" }}</span>
              </div>
              <el-button
                type="danger"
                size="small"
                :loading="deletingId === res.id"
                :disabled="deletingId === res.id"
                @click="emitDelete(res.id)"
              >
                Удалить
              </el-button>
            </div>
          </el-timeline-item>
        </el-timeline>
      </div>
      <div class="dialog-grid__right">
        <div class="dialog-grid__subtitle">Новая бронь</div>
        <el-form :model="form" label-position="top" class="dialog-form">
          <el-form-item label="Время">
            <el-input v-model="form.time" placeholder="Например, 20:00" />
          </el-form-item>
          <el-form-item label="Количество гостей">
            <el-input v-model="form.person" placeholder="Например, 4" />
          </el-form-item>
          <el-form-item label="Имя">
            <el-input v-model="form.name" placeholder="Имя гостя" />
          </el-form-item>
          <el-form-item label="Телефон">
            <el-input v-model="form.tel" placeholder="+7..." />
          </el-form-item>
        </el-form>
      </div>
    </div>
    <template #footer>
      <span class="dialog-footer">
        <el-button @click="visible = false">Отмена</el-button>
        <el-button type="primary" @click="emitCreate">Сохранить</el-button>
      </span>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed, defineEmits, defineProps, reactive, ref, watch } from "vue";

const props = defineProps({
  modelValue: {
    type: Boolean,
    default: false,
  },
  table: {
    type: Array,
    default: () => [],
  },
  numberTable: {
    type: [Number, String],
    default: "",
  },
});

const emit = defineEmits(["update:modelValue", "del", "creat"]);

const form = reactive({
  time: "",
  person: "",
  name: "",
  tel: "",
});

const deletingId = ref(null);

const visible = computed({
  get: () => props.modelValue,
  set: (value) => emit("update:modelValue", value),
});

const numTable = computed(() => String(props.numberTable));

const resetForm = () => {
  form.time = "";
  form.person = "";
  form.name = "";
  form.tel = "";
};

const emitCreate = () => {
  emit("creat", { ...form, numTable: numTable.value });
  visible.value = false;
};

const emitDelete = (id) => {
  deletingId.value = id;
  emit("del", { id });
};

watch(
  () => props.table,
  (value) => {
    // keep form empty even if there are existing bookings
    resetForm();
    deletingId.value = null;
  },
  { deep: true, immediate: true }
);

watch(
  () => props.modelValue,
  (isOpen) => {
    if (!isOpen) {
      deletingId.value = null;
    } else {
      resetForm();
    }
  }
);
</script>

<style lang="scss" scoped>
.dialog-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 16px;
  min-height: 320px;
}

.dialog-grid__left,
.dialog-grid__right {
  background: var(--bg-surface);
  padding: 12px;
  border-radius: 8px;
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}

.dialog-grid__subtitle {
  font-weight: 700;
  margin-bottom: 8px;
}

.booking-card {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.booking-card__name {
  font-weight: 600;
  color: var(--text-primary);
}

.booking-card__meta {
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 12px;
  color: var(--text-secondary);
}

.dialog-form {
  background: var(--bg-surface);
}

.dialog-footer {
  display: inline-flex;
  gap: 8px;
}

@media (max-width: 640px) {
  .dialog-grid {
    grid-template-columns: 1fr;
  }

  .dialog-grid__left,
  .dialog-grid__right {
    padding: 10px;
  }

  :deep(.el-dialog__header),
  :deep(.el-dialog__body) {
    padding: 12px;
  }

  .dialog-footer {
    width: 100%;
    justify-content: space-between;
    flex-wrap: wrap;
  }
}
</style>
