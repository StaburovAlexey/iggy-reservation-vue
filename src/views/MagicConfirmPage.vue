<template>
  <div class="magic-confirm">
    <div class="magic-confirm__card">
      <h2 class="magic-confirm__title">Magic-ссылка</h2>
      <p class="magic-confirm__subtitle">Введите e-mail и придумайте пароль для регистрации.</p>

      <div class="magic-confirm__status">
        <p v-if="status === 'loading'">Проверяем ссылку...</p>
        <p v-else-if="status === 'invalid'">Ссылка недействительна или уже использовалась.</p>
        <p v-else-if="status === 'expired'">Срок действия ссылки истёк.</p>
        <p v-else-if="status === 'pending'">
          Ссылка ожидает подтверждения и истечёт {{ expiresText }}.
        </p>
        <p v-else-if="status === 'approved'">Ссылка одобрена, можно авторизоваться.</p>
        <p v-else class="magic-confirm__error">{{ error || "Произошла неизвестная ошибка." }}</p>
      </div>

      <el-form class="magic-confirm__form" label-position="top" @submit.prevent="submit">
        <el-form-item label="E-mail" class="magic-confirm__form-item">
          <el-input v-model="form.email" autocomplete="email" type="email" placeholder="email@example.com" />
        </el-form-item>
        <el-form-item label="Пароль" class="magic-confirm__form-item">
          <el-input
            v-model="form.password"
            type="password"
            autocomplete="new-password"
            placeholder="Придумайте надёжный пароль"
            show-password
          />
        </el-form-item>
        <el-form-item label="Имя (необязательно)" class="magic-confirm__form-item">
          <el-input v-model="form.name" autocomplete="name" placeholder="Иванов" />
        </el-form-item>
        <p v-if="formError" class="magic-confirm__error">{{ formError }}</p>
        <div class="magic-confirm__form-actions">
          <el-button type="primary" :loading="submitting" :disabled="!canSubmit" @click="submit">
            Завершить регистрацию
          </el-button>
          <el-button @click="retry" :disabled="status === 'loading'">Обновить статус</el-button>
        </div>
      </el-form>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import { ElMessage } from "element-plus";
import { api, setToken } from "@/api/client";
import { useAuthStore } from "@/store/auth";

const route = useRoute();
const router = useRouter();
const authStore = useAuthStore();

const token = computed(() => String(route.query?.token || "").trim());
const status = ref("loading");
const error = ref("");
const expiresAt = ref("");
const form = reactive({
  email: "",
  password: "",
  name: "",
});
const submitting = ref(false);
const formError = ref("");

const expiresText = computed(() => {
  if (!expiresAt.value) return "";
  const diff = Math.max(new Date(expiresAt.value).getTime() - Date.now(), 0);
  const minutes = Math.ceil(diff / 60000);
  return minutes > 0 ? `ещё около ${minutes} мин.` : "менее минуты";
});

const performCheck = async () => {
  if (!token.value) {
    status.value = "invalid";
    error.value = "Токен не передан.";
    return;
  }
  status.value = "loading";
  error.value = "";
  try {
    const resp = await api.fetchMagicLink(token.value);
    expiresAt.value = resp?.expires_at || "";
    status.value = resp?.status || "invalid";
    if (status.value === "approved") {
      if (resp.token) {
        setToken(resp.token);
      }
      if (resp.user) {
        authStore.setUser(resp.user);
      }
      ElMessage.success("Авторизация по magic-ссылке выполнена.");
      router.replace("/");
    }
    if (status.value === "pending" && resp?.email) {
      form.email = resp.email;
    }
  } catch (err) {
    console.error(err);
    status.value = "error";
    error.value = err?.response?.error || "Произошла ошибка при проверке токена.";
  }
};

const normalizedEmail = () => (form.email || "").trim().toLowerCase();

const canSubmit = computed(() => {
  if (!token.value) return false;
  if (!form.email || !form.password) return false;
  if (status.value === "expired") return false;
  return true;
});

const submit = async () => {
  if (!canSubmit.value) {
    formError.value = "Заполните email и пароль.";
    return;
  }
  formError.value = "";
  submitting.value = true;
  try {
    const payload = {
      email: normalizedEmail(),
      password: form.password,
      name: form.name?.trim() || undefined,
    };
    const resp = await api.confirmMagicLink(token.value, payload);
    if (resp.token) {
      setToken(resp.token);
    }
    if (resp.user) {
      authStore.setUser(resp.user);
    }
    status.value = "approved";
    ElMessage.success("Вы успешно авторизованы. Перенаправляем на главную.");
    router.replace("/");
  } catch (err) {
    console.error(err);
    formError.value = err?.response?.error || "Не удалось завершить регистрацию.";
    status.value = "error";
  } finally {
    submitting.value = false;
  }
};

const retry = () => performCheck();

onMounted(performCheck);
</script>

<style scoped>
.magic-confirm {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}

.magic-confirm__card {
  width: min(480px, 100%);
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
  border-radius: 16px;
  padding: 24px;
  box-shadow: 0 20px 40px rgba(0, 0, 0, 0.25);
  text-align: center;
  color: var(--text-primary);
}

.magic-confirm__title {
  margin: 0;
  font-size: 24px;
}

.magic-confirm__subtitle {
  margin: 8px 0 16px;
  color: var(--text-secondary);
}

.magic-confirm__status {
  min-height: 64px;
  font-size: 14px;
  color: var(--text-secondary);
}

.magic-confirm__error {
  color: #ff6b6b;
  margin: 0;
}

.magic-confirm__error + .magic-confirm__error {
  margin-top: 8px;
}

.magic-confirm__form {
  margin-top: 16px;
  display: flex;
  flex-direction: column;
}

.magic-confirm__form-item {
  width: 100%;
}

.magic-confirm__form-item .el-form-item__label {
  width: 100%;
  text-align: left;
  margin-bottom: 8px;
}

.magic-confirm__form-item .el-input,
.magic-confirm__form-item .el-input__inner {
  width: 100%;
  box-sizing: border-box;
}

.magic-confirm__form-actions {
  display: flex;
  justify-content: center;
  gap: 12px;
  margin-top: 8px;
  flex-wrap: wrap;
}
</style>
