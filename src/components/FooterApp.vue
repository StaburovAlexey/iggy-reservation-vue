<template>
  <footer class="footer">
    <div class="footer__inner">
      <div class="footer__title">Выберите дату:</div>
      <el-date-picker
        v-model="date"
        type="date"
        placeholder="Дата бронирования"
        format="DD.MM.YY"
        value-format="DD.MM.YY"
        :clearable="false"
        :editable="false"
        style="width: 150px;"
        @change="handleDateChange"
      />
    </div>
  </footer>
</template>

<script setup>
import { onMounted, ref } from "vue";
import { useDataStore } from "@/store/dataBase";

const dataStore = useDataStore();
const date = ref("");

const formatDate = (value) => {
  const options = { day: "2-digit", month: "2-digit", year: "2-digit" };
  return new Intl.DateTimeFormat("ru-RU", options).format(value);
};

const handleDateChange = async (value) => {
  if (!value) return;
  try {
    dataStore.setDate(value);
    await dataStore.fetchInfo();
  } catch (error) {
    console.log(error);
  }
};

onMounted(() => {
  const today = formatDate(new Date());
  date.value = today;
  dataStore.setDate(today);
  dataStore.fetchInfo().catch((error) => console.log(error));
});
</script>

<style lang="scss" scoped>
.footer {
  margin-top: auto;
  background: var(--bg-navbar);
  color: var(--text-primary);
  padding: 8px 12px 10px;
}

.footer__inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.footer__title {
  font-weight: 600;
}
</style>
