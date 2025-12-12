<template>
  <div class="magic-page">
    <div class="magic-card">
      <h2 class="magic-title">Magic link</h2>
      <p class="magic-text">{{ statusText }}</p>
      <div class="magic-actions">
        <el-button type="primary" @click="goLogin">Перейти к входу</el-button>
        <el-button @click="goHome">На главную</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from "vue";
import { useRouter } from "vue-router";

const router = useRouter();
const status = ref("unsupported"); // unsupported state

const statusText = computed(() => {
  if (status.value === "unsupported") {
    return "Magic-link авторизация больше не используется. Пожалуйста, войдите через форму логина.";
  }
  return "";
});

const goLogin = () => {
  router.push("/login");
};

const goHome = () => {
  router.push("/");
};
</script>

<style scoped>
.magic-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(145deg, var(--gradient-start), var(--gradient-end));
  color: var(--text-primary);
  padding: 16px;
}

.magic-card {
  max-width: 420px;
  width: 100%;
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: 12px;
  padding: 20px;
  box-shadow: 0 10px 30px rgba(0, 0, 0, 0.25);
}

.magic-title {
  margin: 0 0 8px;
  font-size: 22px;
}

.magic-text {
  margin: 0 0 16px;
  color: var(--text-secondary);
}

.magic-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}
</style>
