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
        <el-empty v-if="!table.length" description="Записей пока нет" image="./parrot.webp" :image-size="120"/>
        <el-timeline v-else>
          <el-timeline-item
            v-for="res in table"
            :key="res.id"
            :timestamp="res.time"
            placement="top"
          >
            <div class="booking-card">
              
              <div class="booking-card__meta">
                <span>Имя: {{ res.name || "-" }}</span>
                <span>Гостей: {{ res.person || "-" }}</span>
                <span>Телефон: {{ res.phone || "-" }}</span>
              </div>
              <div class="booking-card__user">
                <el-avatar :size="32" :src="userAvatar(res)" class="booking-card__avatar">
                  {{ userInitial(res) }}
                </el-avatar>
                <div class="booking-card__user-info">
                  <div class="booking-card__user-name">{{ userName(res) }}</div>
                  <div class="booking-card__user-label">{{ userEmailMasked(res) }}</div>
                </div>
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
        <div class="dialog-grid__subtitle">Создать бронь</div>
        <el-form :model="form" label-position="top" class="dialog-form">
          <el-form-item label="Время брони">
            <el-time-picker
              v-model="form.timeRange"
              style="width: 200px;"
              is-range
              range-separator="-"
              start-placeholder="от"
              end-placeholder="до"
              format="HH:mm"
              value-format="HH:mm"
              size="small"
              :editable="false"
            />
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
        <el-button @click="visible = false">Отменить</el-button>
        <el-button type="primary" @click="emitCreate">Сохранить</el-button>
      </span>
    </template>
  </el-dialog>
</template>

<script setup>
import { computed, defineEmits, defineProps, reactive, ref, watch } from "vue";
import { ElMessage } from "element-plus";

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
  timeRange: [],
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
  form.timeRange = [];
  form.person = "";
  form.name = "";
  form.tel = "";
};

const emitCreate = () => {
  if (form.timeRange.length !== 2 || !form.timeRange[0] || !form.timeRange[1] || !form.tel) {
    ElMessage.warning("Укажите время и телефон");
    return;
  }
  const [timeFrom, timeTo] = form.timeRange;
  const time = `${timeFrom}-${timeTo}`;
  emit("creat", { time, person: form.person, name: form.name, tel: form.tel, numTable: numTable.value });
  visible.value = false;
};

const emitDelete = (id) => {
  deletingId.value = id;
  emit("del", { id });
};

const userName = (res) => res?.user?.full_name || "Без имени";
const userEmail = (res) => res?.user?.email || "Без email";
const userEmailMasked = (res) => {
  const email = res?.user?.email;
  if (!email) return "Нет почты";
  const prefix = email.slice(0, 5);
  return email.length > 5 ? `${prefix}...` : prefix;
};
const userAvatar = (res) => res?.user?.avatar_url || "";
const userInitial = (res) => userName(res).slice(0, 1).toUpperCase();

watch(
  () => props.table,
  () => {
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
  max-width: 100%;
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

.booking-card__user {
  display: flex;
  align-items: center;
  gap: 8px;
}

.booking-card__avatar {
  background: var(--bg-surface);
  color: var(--text-primary);
}

.booking-card__user-info {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.booking-card__user-name {
  font-weight: 600;
  color: var(--text-primary);
}

.booking-card__user-label {
  font-size: 12px;
  color: var(--text-secondary);
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
