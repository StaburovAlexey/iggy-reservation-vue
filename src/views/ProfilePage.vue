<template>
  <div class="profile-page">
    <NavBar />
    <div class="profile-page__body">
      <div v-if="loadingProfile || saving" class="profile-loader">
        <PreloaderApp />
      </div>
      <el-card v-else class="profile-card" shadow="hover">
        <div class="profile-card__header">
          <div>
            <h2 class="profile-card__title">Профиль <el-button style="float: right;" @click="goHome">На главную</el-button></h2>
            <p class="profile-card__subtitle">Обновите имя, e-mail или пароль.</p>
          </div>
          
        </div>
        <el-form
          :model="form"
          label-position="top"
          class="profile-form"
          @submit.prevent
        >
          <el-form-item label="Имя">
            <el-input v-model="form.fullName" placeholder="Как вас зовут?" />
          </el-form-item>
          <el-form-item label="E-mail">
            <el-input v-model="form.email" type="email" placeholder="you@example.com" />
          </el-form-item>
          <el-form-item label="Новый пароль">
            <el-input
              v-model="form.password"
              type="password"
              show-password
              placeholder="Оставьте пустым, если не нужно менять"
            />
          </el-form-item>
          <div class="profile-form__actions">
            
            <el-button @click="resetForm" :disabled="saving || loadingProfile">Сбросить</el-button>
            <el-button
              type="primary"
              :disabled="!canSave"
              :loading="saving"
              @click="saveProfile"
            >
              Сохранить
            </el-button>
          </div>
        </el-form>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from "vue";
import { useRouter } from "vue-router";
import { useStore } from "vuex";
import { ElMessage } from "element-plus";
import NavBar from "@/components/NavBar.vue";
import PreloaderApp from "@/components/PreloaderApp.vue";
import { supabase } from "@/lib/supabaseClient";

const store = useStore();
const router = useRouter();

const loadingProfile = ref(true);
const saving = ref(false);
const form = reactive({
  fullName: "",
  email: "",
  password: "",
});
const original = reactive({
  fullName: "",
  email: "",
});

const canSave = computed(
  () =>
    !loadingProfile.value &&
    !saving.value &&
    !!form.email &&
    (form.fullName !== original.fullName ||
      form.email !== original.email ||
      !!form.password)
);

const resetForm = () => {
  form.fullName = original.fullName;
  form.email = original.email;
  form.password = "";
};

const loadUser = async () => {
  loadingProfile.value = true;
  try {
    const { data, error } = await supabase.auth.getUser();
    if (error || !data?.user) {
      throw error || new Error("Пользователь не найден");
    }
    const currentUser = data.user;
    original.fullName = currentUser.user_metadata?.full_name || "";
    original.email = currentUser.email || "";
    resetForm();
    store.commit("setUser", currentUser);
  } catch (error) {
    console.log(error);
    ElMessage.error("Не удалось загрузить профиль");
    router.push("/login");
  } finally {
    loadingProfile.value = false;
  }
};

const saveProfile = async () => {
  if (!canSave.value) return;
  saving.value = true;
  try {
    const payload = {};
    const meta = {};

    if (form.fullName !== original.fullName) {
      meta.full_name = form.fullName;
    }
    if (Object.keys(meta).length) {
      payload.data = meta;
    }
    if (form.email && form.email !== original.email) {
      payload.email = form.email;
    }
    if (form.password) {
      payload.password = form.password;
    }

    const { data, error } = await supabase.auth.updateUser(payload);
    if (error) throw error;
    const updatedUser = data.user;

    original.fullName = updatedUser.user_metadata?.full_name || "";
    original.email = updatedUser.email || "";
    resetForm();
    store.commit("setUser", updatedUser);
    ElMessage.success("Профиль обновлен");
  } catch (error) {
    console.log(error);
    ElMessage.error("Не удалось сохранить профиль");
  } finally {
    saving.value = false;
  }
};

const goHome = () => {
  router.push("/");
};

onMounted(loadUser);
</script>

<style lang="scss" scoped>
.profile-page {
  min-height: 100vh;
  background: radial-gradient(circle at 10% 20%, rgba(255, 255, 255, 0.08), transparent 30%),
    radial-gradient(circle at 90% 10%, rgba(255, 255, 255, 0.05), transparent 25%),
    linear-gradient(180deg, var(--gradient-start) 0%, var(--gradient-end) 100%);
}

.profile-page__body {
  max-width: 720px;
  margin: 32px auto;
  padding: 0 16px 48px;
}

.profile-card {
  background: var(--bg-surface-2);
  color: var(--text-primary);
  border: 1px solid var(--border-color);
}

.profile-card__header {
  margin-bottom: 12px;
}

.profile-card__title {
  margin: 0;
  width: 100%;
  font-size: 22px;
}

.profile-card__subtitle {
  margin: 4px 0 0;
  color: var(--text-secondary);
  font-size: 14px;
}

.profile-form {
  margin-top: 8px;
}

.profile-form__actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
  margin-top: 4px;
}

.profile-loader {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 240px;
}
</style>
