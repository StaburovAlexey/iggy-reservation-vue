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
            <h2 class="profile-card__title">
              Профиль
              <el-button style="float: right;" @click="goHome">На главную</el-button>
            </h2>
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

        <el-card v-if="isAdmin" class="invite-card" shadow="never">
          <div class="invite-card__header">
            <div>
              <h3 class="invite-card__title">Создать пользователя</h3>
              <p class="invite-card__subtitle">
                Админ может создать аккаунт, задав e-mail, имя, пароль и роль.
              </p>
            </div>
          </div>
          <div class="invite-card__form">
            <el-input
              v-model="newUser.email"
              type="email"
              placeholder="email пользователя"
              :disabled="sendingInvite"
            />
            <el-input v-model="newUser.name" placeholder="Имя" :disabled="sendingInvite" />
            <el-input
              v-model="newUser.password"
              type="password"
              placeholder="Пароль"
              :disabled="sendingInvite"
              show-password
            />
            <el-select v-model="newUser.role" placeholder="Роль" style="min-width: 140px" :disabled="sendingInvite">
              <el-option label="Админ" value="admin" />
              <el-option label="Пользователь" value="user" />
            </el-select>
            <el-button type="primary" :loading="sendingInvite" :disabled="sendingInvite" @click="createUser">
              Создать
            </el-button>
          </div>
        </el-card>

        <el-card v-if="isAdmin" class="settings-card" shadow="never">
          <div class="settings-card__header">
            <div>
              <h3 class="settings-card__title">Настройки бота</h3>
              <p class="settings-card__subtitle">Измените bot_id, chat_id и admin_chat.</p>
            </div>
          </div>
          <el-form label-position="top" class="settings-form" @submit.prevent>
            <el-form-item label="bot_id">
              <el-input v-model="settings.bot_id" placeholder="123456:ABCD..." :disabled="loadingSettings" />
            </el-form-item>
            <el-form-item label="chat_id">
              <el-input v-model="settings.chat_id" placeholder="-1001234567890" :disabled="loadingSettings" />
            </el-form-item>
            <el-form-item label="admin_chat">
              <el-input v-model="settings.admin_chat" placeholder="-1001234567890" :disabled="loadingSettings" />
            </el-form-item>
            <div class="settings-form__actions">
              <el-button @click="resetSettings" :disabled="savingSettings || loadingSettings">Сбросить</el-button>
              <el-button
                type="primary"
                :loading="savingSettings"
                :disabled="savingSettings || loadingSettings"
                @click="saveSettings"
              >
                Сохранить настройки
              </el-button>
            </div>
          </el-form>
        </el-card>
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
const sendingInvite = ref(false);
const loadingSettings = ref(false);
const savingSettings = ref(false);

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

const newUser = reactive({
  email: "",
  name: "",
  password: "",
  role: "user",
});

const settings = reactive({
  bot_id: "",
  chat_id: "",
  admin_chat: "",
});
const originalSettings = reactive({
  bot_id: "",
  chat_id: "",
  admin_chat: "",
});

const isAdmin = computed(() => authStore.user?.role === "admin");

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

const createUser = async () => {
  if (!isAdmin.value) return;
  if (!newUser.email || !newUser.password) {
    ElMessage.warning("Укажите email и пароль");
    return;
  }
  sendingInvite.value = true;
  try {
    const payload = {
      login: newUser.email,
      password: newUser.password,
      name: newUser.name || "",
      role: newUser.role || "user",
      avatar: null,
    };
    const resp = await api.registerUser(payload);
    if (resp?.user) {
      ElMessage.success("Пользователь создан");
      newUser.email = "";
      newUser.name = "";
      newUser.password = "";
      newUser.role = "user";
    } else {
      ElMessage.error("Не удалось создать пользователя");
    }
  } catch (error) {
    console.log(error);
    ElMessage.error("Ошибка при создании пользователя");
  } finally {
    sendingInvite.value = false;
  }
};

const resetSettings = () => {
  settings.bot_id = originalSettings.bot_id;
  settings.chat_id = originalSettings.chat_id;
  settings.admin_chat = originalSettings.admin_chat;
};

const loadSettings = async () => {
  if (!isAdmin.value) return;
  loadingSettings.value = true;
  try {
    const resp = await api.getSettings();
    const s = resp?.settings || resp || {};
    originalSettings.bot_id = s.bot_id || "";
    originalSettings.chat_id = s.chat_id || "";
    originalSettings.admin_chat = s.admin_chat || "";
    resetSettings();
  } catch (error) {
    console.log(error);
    ElMessage.error("Не удалось загрузить настройки");
  } finally {
    loadingSettings.value = false;
  }
};

const saveSettings = async () => {
  if (!isAdmin.value) return;
  savingSettings.value = true;
  try {
    const payload = {
      bot_id: settings.bot_id || null,
      chat_id: settings.chat_id || null,
      admin_chat: settings.admin_chat || null,
    };
    const resp = await api.updateSettings(payload);
    const s = resp?.settings || payload;
    originalSettings.bot_id = s.bot_id || "";
    originalSettings.chat_id = s.chat_id || "";
    originalSettings.admin_chat = s.admin_chat || "";
    resetSettings();
    ElMessage.success("Настройки сохранены");
  } catch (error) {
    console.log(error);
    ElMessage.error("Не удалось сохранить настройки");
  } finally {
    savingSettings.value = false;
  }
};

const goHome = () => {
  router.push("/");
};

onMounted(async () => {
  await loadUser();
  await loadSettings();
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
  gap: 8px;
  margin-top: 8px;
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
</style>
