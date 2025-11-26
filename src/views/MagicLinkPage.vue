<template>
  <div class="magic-page">
    <div class="magic-card">
      <h2 class="magic-title">Приглашение</h2>
      <p class="magic-text">{{ statusText }}</p>
      <div class="magic-actions">
        <el-button type="primary" :loading="processing" @click="processLink">
          Проверить ссылку
        </el-button>
        <el-button @click="goHome">На главную</el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { ElMessage } from "element-plus";
import { useStore } from "vuex";
import { supabase } from "@/lib/supabaseClient";

const router = useRouter();
const route = useRoute();
const store = useStore();

const processing = ref(false);
const status = ref("pending"); // pending | success | error

const statusText = computed(() => {
  if (status.value === "success") {
    return "Ссылка подтверждена. Сейчас перенаправим.";
  }
  if (status.value === "error") {
    return "Не удалось активировать ссылку. Попробуйте ещё раз.";
  }
  return "Проверяем приглашение...";
});

const saveUserToStore = async () => {
  const { data, error } = await supabase.auth.getUser();
  if (!error && data?.user) {
    store.commit("setUser", data.user);
  }
};

const processLink = async () => {
  processing.value = true;
  status.value = "pending";
  try {
    const code = route.query.code;
    if (code) {
      const { error } = await supabase.auth.exchangeCodeForSession(code);
      if (error) throw error;
    } else {
      const hashParams = new URLSearchParams(window.location.hash.replace("#", ""));
      const access_token = hashParams.get("access_token");
      const refresh_token = hashParams.get("refresh_token");
      if (access_token && refresh_token) {
        const { error } = await supabase.auth.setSession({ access_token, refresh_token });
        if (error) throw error;
      } else {
        throw new Error("В ссылке нет кода авторизации");
      }
    }
    status.value = "success";
    await saveUserToStore();
    setTimeout(() => router.push("/profile"), 1200);
  } catch (error) {
    console.log(error);
    ElMessage.error("Ошибка при обработке ссылки");
    status.value = "error";
  } finally {
    processing.value = false;
  }
};

const goHome = () => {
  router.push("/");
};

onMounted(() => {
  processLink();
});
</script>

<style scoped>
.magic-page {
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(145deg, var(--gradient-start), var(--gradient-end));
  color: var(--text-primary);
  padding: 16px;
}

.magic-card {
  max-width: 420px;
  width: 95%;
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
