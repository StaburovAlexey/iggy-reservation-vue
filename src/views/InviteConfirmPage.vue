<template>
  <div class="invite-page">
    <div class="invite-card">
      <h2 class="invite-title">Создайте пароль</h2>
      <p class="invite-text">
        Введите желаемый пароль, чтобы активировать приглашение. Ссылка действительна один раз.
      </p>
      <el-form class="invite-form" @submit.prevent="submit">
        <el-form-item label="Имя (необязательно)">
          <el-input v-model="name" autocomplete="name" />
        </el-form-item>
        <el-form-item label="Пароль">
          <el-input
            v-model="password"
            type="password"
            autocomplete="new-password"
            placeholder="Придумайте надёжный пароль"
            show-password
          />
        </el-form-item>
        <el-form-item label="Подтвердите пароль">
          <el-input
            v-model="confirmPassword"
            type="password"
            autocomplete="new-password"
            placeholder="Повторите пароль"
            show-password
          />
        </el-form-item>
        <div v-if="error" class="invite-error">{{ error }}</div>
        <el-button type="primary" :loading="submitting" :disabled="!canSubmit" @click="submit">
          Завершить регистрацию
        </el-button>
        <p class="invite-footnote">Если ссылка не работает, обратитесь к администратору.</p>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { ElMessage } from "element-plus";
import { api } from "@/api/client";

const route = useRoute();
const router = useRouter();
const token = String(route.query?.token || "").trim();

const name = ref("");
const password = ref("");
const confirmPassword = ref("");
const submitting = ref(false);
const error = ref("");

const canSubmit = computed(() => {
  return token && password.value && confirmPassword.value && password.value === confirmPassword.value;
});

const submit = async () => {
  if (!token) {
    error.value = "Ошибка ссылки. Запросите новое приглашение.";
    return;
  }
  if (password.value !== confirmPassword.value) {
    error.value = "Пароли не совпадают.";
    return;
  }
  submitting.value = true;
  error.value = "";
  try {
    await api.confirmInvitation({
      token,
      password: password.value,
      name: name.value || undefined,
    });
    ElMessage.success("Регистрация завершена. Войдите на сайт.");
    router.push("/login");
  } catch (err) {
    console.log(err);
    error.value = err?.response?.error || "Не удалось завершить регистрацию.";
  } finally {
    submitting.value = false;
  }
};
</script>

<style scoped>
.invite-page {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 16px;
  background: linear-gradient(145deg, var(--gradient-start), var(--gradient-end));
  color: var(--text-primary);
}

.invite-card {
  width: min(480px, 100%);
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.25);
}

.invite-title {
  margin: 0 0 8px;
}

.invite-text {
  margin: 0 0 16px;
  color: var(--text-secondary);
}

.invite-form {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.invite-error {
  color: #ff6b6b;
  font-size: 13px;
  margin-bottom: 4px;
}

.invite-footnote {
  margin: 10px 0 0;
  font-size: 12px;
  color: var(--text-secondary);
}
</style>
