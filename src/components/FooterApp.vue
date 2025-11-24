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
        @change="handleDateChange"
      />
    </div>
  </footer>
</template>

<script setup>
import { onMounted, ref } from "vue";
import { useStore } from "vuex";

const store = useStore();
const date = ref("");

const formatDate = (value) => {
  const options = { day: "2-digit", month: "2-digit", year: "2-digit" };
  return new Intl.DateTimeFormat("ru-RU", options).format(value);
};

const handleDateChange = async (value) => {
  if (!value) return;
  try {
    store.commit("setDate", value);
    await store.dispatch("fetchInfo");
  } catch (error) {
    console.log(error);
  }
};

onMounted(() => {
  const today = formatDate(new Date());
  date.value = today;
  store.commit("setDate", today);
  store.dispatch("fetchInfo").catch((error) => console.log(error));
});
</script>

<style lang="scss" scoped>
.footer {
  margin-top: auto;
  background: #0f172a;
  color: #e2e8f0;
  padding: 16px 24px;
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
