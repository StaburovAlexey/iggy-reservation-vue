<template>
  <div class="edit-schema">
    <NavBar />
    <div class="edit-schema__body">
      <el-card class="edit-schema__card" shadow="hover">
        <div class="edit-schema__header">
          <div>
            <h2 class="edit-schema__title">Редактирование план-схемы</h2>
            <p class="edit-schema__subtitle">
              Перетаскивайте столы на схеме или меняйте координаты вручную в панели справа.
            </p>
          </div>
          <el-button size="small" @click="goBack">Назад</el-button>
        </div>
        <SchemaEditor :schemaData="schemaData" @save-schema="handleSaveSchema" />
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { ref } from "vue";
import { useRouter } from "vue-router";
import { ElMessage } from "element-plus";
import NavBar from "@/components/NavBar.vue";
import SchemaEditor from "@/components/SchemaEditor.vue";

const router = useRouter();
const schemaData = ref(null);

const STORAGE_KEY = "schema-config";

const goBack = () => router.push("/profile");

const loadSchema = () => {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return;
  try {
    schemaData.value = JSON.parse(raw);
  } catch (error) {
    console.log(error);
  }
};

const handleSaveSchema = (payload) => {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(payload));
    ElMessage.success("Схема сохранена (локально)");
    schemaData.value = payload;
  } catch (error) {
    console.log(error);
    ElMessage.error("Не удалось сохранить схему");
  }
};

loadSchema();
</script>

<style scoped lang="scss">
.edit-schema {
  min-height: 100vh;
  background: radial-gradient(circle at 10% 20%, rgba(255, 255, 255, 0.08), transparent 30%),
    radial-gradient(circle at 90% 10%, rgba(255, 255, 255, 0.05), transparent 25%),
    linear-gradient(180deg, var(--gradient-start) 0%, var(--gradient-end) 100%);
}

.edit-schema__body {
  max-width: 960px;
  margin: 24px auto 48px;
  padding: 0 16px;
}

.edit-schema__card {
  background: var(--bg-surface-2);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}

.edit-schema__header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  gap: 8px;
  margin-bottom: 12px;
}

.edit-schema__title {
  margin: 0;
  font-size: 22px;
}

.edit-schema__subtitle {
  margin: 4px 0 0;
  color: var(--text-secondary);
  font-size: 14px;
}
</style>
