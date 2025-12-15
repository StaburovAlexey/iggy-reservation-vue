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
            <h2 class="profile-card__title">Профиль</h2>
            <p class="profile-card__subtitle">Обновите имя, e-mail и аватар.</p>
          </div>
        </div>

        <el-form :model="form" label-position="top" class="profile-form" autocomplete="off" @submit.prevent>
          <el-form-item label="Имя">
            <el-input v-model="form.fullName" autocomplete="off" placeholder="Как вас зовут?" />
          </el-form-item>
          <el-form-item label="E-mail">
            <el-input v-model="form.email" autocomplete="off" type="email" placeholder="you@example.com" />
          </el-form-item>
          <el-form-item label="Аватар">
            <div class="avatar-upload">
              <el-avatar :size="72" :src="avatarPreview" class="avatar-upload__preview">
                {{ initials }}
              </el-avatar>
              <el-upload
                action=""
                :auto-upload="false"
                :show-file-list="false"
                accept="image/*"
                :on-change="handleAvatarChange"
              >
                <el-button>Выбрать файл</el-button>
              </el-upload>
              <div class="avatar-upload__hint">PNG/JPG до 2MB</div>
            </div>
          </el-form-item>
          <el-form-item label="Новый пароль">
            <el-input
              v-model="form.password"
              autocomplete="new-password"
              type="password"
              show-password
              placeholder="Оставьте пустым, если менять не нужно"
            />
          </el-form-item>
          <div class="profile-form__actions">
            <el-button @click="resetForm" :disabled="saving || loadingProfile">Сбросить</el-button>
            <el-button type="primary" :disabled="!canSave" :loading="saving" @click="saveProfile">
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
import { ElMessage } from "element-plus";
import NavBar from "@/components/NavBar.vue";
import PreloaderApp from "@/components/PreloaderApp.vue";
import { api } from "@/api/client";
import { useAuthStore } from "@/store/auth";

const authStore = useAuthStore();
const router = useRouter();

const loadingProfile = ref(true);
const saving = ref(false);
const avatarFile = ref(null);

const form = reactive({
  fullName: "",
  email: "",
  password: "",
  avatarUrl: "",
});
const original = reactive({
  fullName: "",
  email: "",
  avatarUrl: "",
});

const canSave = computed(
  () =>
    !loadingProfile.value &&
    !saving.value &&
    !!form.email &&
    (form.fullName !== original.fullName ||
      form.email !== original.email ||
      !!form.password ||
      !!avatarFile.value)
);

const resetForm = () => {
  form.fullName = original.fullName;
  form.email = original.email;
  form.password = "";
  form.avatarUrl = original.avatarUrl;
  avatarFile.value = null;
};

const handleAvatarChange = (file) => {
  avatarFile.value = file.raw;
};

const initials = computed(() => (form.fullName ? form.fullName.slice(0, 1).toUpperCase() : "U"));

const avatarPreview = computed(() =>
  avatarFile.value ? URL.createObjectURL(avatarFile.value) : form.avatarUrl || ""
);

const loadUser = async () => {
  loadingProfile.value = true;
  try {
    const currentUser = authStore.user;
    if (!currentUser || (!currentUser.email && !currentUser.login)) {
      throw new Error("Требуется авторизация");
    }
    original.fullName = currentUser.user_metadata?.full_name || currentUser.name || "";
    original.email = currentUser.email || currentUser.login || "";
    original.avatarUrl = currentUser.user_metadata?.avatar_url || currentUser.avatar || "";
    resetForm();
    authStore.setUser(currentUser);
  } catch (error) {
    console.log(error);
    ElMessage.error("Произошла ошибка загрузки профиля");
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
    if (avatarFile.value) {
      const uploadResponse = await api.uploadFile(avatarFile.value);
      if (uploadResponse?.url) {
        form.avatarUrl = uploadResponse.url;
      }
    }
    if (form.fullName !== original.fullName) {
      payload.name = form.fullName;
    }
    if (form.email && form.email !== original.email) {
      payload.login = form.email;
    }
    if (form.password) {
      payload.password = form.password;
    }
    if (form.avatarUrl) {
      payload.avatar = form.avatarUrl;
    }

    const response = await api.updateProfile(payload);
    const updatedUser = response?.user || {};

    original.fullName = updatedUser.user_metadata?.full_name || updatedUser.name || "";
    original.email = updatedUser.email || updatedUser.login || "";
    original.avatarUrl = updatedUser.user_metadata?.avatar_url || updatedUser.avatar || "";
    resetForm();
    authStore.setUser(updatedUser);
    ElMessage.success("Профиль обновлён");
  } catch (error) {
    console.log(error);
    ElMessage.error("Произошла ошибка сохранения профиля");
  } finally {
    saving.value = false;
  }
};

onMounted(async () => {
  await loadUser();
});
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
  margin: 0 auto;
  padding: 20px 16px;
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
  flex-wrap: wrap;
}
.profile-form__actions .el-button {
  flex: 1 1 200px;
  margin-left: 0;
}
.profile-form__actions .el-button + .el-button {
  margin-left: 0;
}

.schema-actions {
  display: flex;
  justify-content: flex-end;
  margin: 12px 0;
}

.invite-card,
.settings-card {
  margin-top: 16px;
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
}

.invite-card__header,
.settings-card__header {
  margin-bottom: 8px;
}

.invite-card__title,
.settings-card__title {
  margin: 0;
  color: var(--text-primary);
}

.invite-card__subtitle,
.settings-card__subtitle {
  margin: 4px 0 0;
  color: var(--text-secondary);
  font-size: 13px;
}

.invite-card__form {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 8px;
  align-items: center;
}

.settings-form__actions {
  display: flex;
  justify-content: flex-end;
  flex-wrap: wrap;
  gap: 8px;
  margin-top: 8px;
}
.settings-form__actions .el-button {
  flex: 1 1 200px;
  margin-left: 0;
}
.settings-form__actions .el-button + .el-button {
  margin-left: 0;
}

.profile-loader {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 240px;
}

.avatar-upload {
  display: flex;
  align-items: center;
  gap: 12px;
}

.avatar-upload__preview {
  background: var(--bg-surface);
  color: var(--text-primary);
}

.avatar-upload__hint {
  font-size: 12px;
  color: var(--text-secondary);
}

.telegram-link {
  margin-top: 16px;
  padding: 12px;
  border: 1px dashed var(--border-color);
  border-radius: 12px;
  background: var(--bg-surface);
}

.telegram-link__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
}

.telegram-link__title {
  margin: 0;
  color: var(--text-primary);
}

.telegram-link__subtitle {
  margin: 4px 0 0;
  color: var(--text-primary);
  opacity: 0.9;
}

.telegram-link__actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
  justify-content: flex-end;
}

.telegram-link__code-block {
  margin-top: 12px;
  display: grid;
  gap: 8px;
}

.telegram-link__code {
  font-family: "SFMono-Regular", Consolas, "Liberation Mono", Menlo, monospace;
  font-size: 22px;
  font-weight: 700;
  letter-spacing: 2px;
  padding: 12px;
  background: var(--bg-surface-2);
  border: 1px solid var(--border-color);
  border-radius: 10px;
  text-align: center;
}

.telegram-link__hint {
  background: var(--bg-surface-2);
  border-radius: 10px;
  padding: 10px 12px;
  border: 1px solid var(--border-color);
  color: var(--text-primary);
  opacity: 0.92;
}

.telegram-link__hint p {
  margin: 4px 0;
}

.telegram-link__status {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  flex-wrap: wrap;
}

.telegram-link__status-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.telegram-link__expires,
.telegram-link__chat,
.telegram-link__placeholder {
  margin: 0;
  color: var(--text-primary);
  opacity: 0.9;
}
</style>
