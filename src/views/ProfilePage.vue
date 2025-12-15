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

          <el-divider />

          <div class="telegram-link">
            <div class="telegram-link__header">
              <div>
                <h4 class="telegram-link__title">Привязка приватной группы</h4>
                <p class="telegram-link__subtitle">
                  Получите код /link, добавьте бота в группу и отправьте команду, чтобы автоматически подставить chat_id.
                </p>
              </div>
              <div class="telegram-link__actions">
                <el-button
                  type="primary"
                  :loading="telegramLink.loading"
                  :disabled="telegramLink.loading || loadingSettings"
                  @click="startTelegramLinking"
                >
                  Привязать группу
                </el-button>
                <el-button
                  v-if="telegramLink.code"
                  :disabled="telegramLink.loading || loadingSettings"
                  @click="resetTelegramLink"
                >
                  Сбросить код
                </el-button>
              </div>
            </div>

            <div v-if="telegramLink.code" class="telegram-link__code-block">
              <div class="telegram-link__code">{{ telegramLink.code }}</div>
              <div class="telegram-link__hint">
                <p>1. Добавьте бота в приватную группу.</p>
                <p>2. Отправьте в группе команду: <code>/link {{ telegramLink.code }}</code></p>
                <p>3. После ответа бота мы заберём chat_id через API и заполним настройки.</p>
              </div>
              <div class="telegram-link__status">
                <el-tag :type="telegramLinkTagType" size="small">
                  {{ telegramLinkStatusText }}
                </el-tag>
                <div class="telegram-link__status-actions">
                  <el-button size="small" :loading="telegramLink.checking" @click="copyLinkCode">
                    Скопировать код
                  </el-button>
                  <el-button
                    size="small"
                    :loading="telegramLink.checking"
                    :disabled="telegramLink.status === 'linked'"
                    @click="checkTelegramLinkStatus"
                  >
                    Обновить статус
                  </el-button>
                </div>
              </div>
              <p v-if="telegramExpiresInMinutes !== null" class="telegram-link__expires">
                Код действует примерно {{ telegramExpiresInMinutes }} минут.
              </p>
              <p v-if="telegramLink.chatId" class="telegram-link__chat">
                Текущий chat_id: <strong>{{ telegramLink.chatId }}</strong>
                <span v-if="telegramLink.chatTitle">&nbsp;({{ telegramLink.chatTitle }})</span>
              </p>
            </div>
            <div v-else class="telegram-link__placeholder">
              <p>Нажмите «Привязать группу», чтобы получить одноразовый код.</p>
            </div>
          </div>
        </el-card>
      </el-card>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted, onUnmounted, reactive, ref } from "vue";
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

const telegramLink = reactive({
  code: "",
  status: "idle",
  expiresIn: null,
  expiresAt: null,
  ttlMinutes: null,
  chatId: "",
  chatTitle: "",
  error: "",
  loading: false,
  checking: false,
});

let telegramStatusTimer = null;

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

const telegramLinkTagType = computed(() => {
  if (telegramLink.status === "linked") return "success";
  if (telegramLink.status === "waiting") return "info";
  if (telegramLink.status === "expired") return "warning";
  if (telegramLink.status === "error") return "danger";
  return "info";
});

const telegramLinkStatusText = computed(() => {
  if (telegramLink.status === "linked" && telegramLink.chatId) {
    return `Готово: ${telegramLink.chatTitle || telegramLink.chatId}`;
  }
  if (telegramLink.status === "waiting") {
    return "Ждём команду /link в группе";
  }
  if (telegramLink.status === "expired") {
    return "Код истёк, сгенерируйте новый";
  }
  if (telegramLink.status === "error") {
    return telegramLink.error || "Ошибка привязки";
  }
  return "Получите код и отправьте его в группу";
});

const telegramExpiresInMinutes = computed(() => {
  if (!telegramLink.expiresAt) return null;
  const diff = Math.ceil((telegramLink.expiresAt - Date.now()) / 60000);
  return diff > 0 ? diff : 0;
});

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
  const email = (newUser.email || "").trim().toLowerCase();
  const emailPattern = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
  if(!emailPattern.test(email)){
    ElMessage.warning("Укажите валидный email");
    return
  }
  if (!email || !newUser.password) {
    ElMessage.warning("Укажите email и пароль");
    return;
  }
  sendingInvite.value = true;
  try {
    const payload = {
      login: email,
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

const clearTelegramTimer = () => {
  if (telegramStatusTimer) {
    clearInterval(telegramStatusTimer);
    telegramStatusTimer = null;
  }
};

const resetTelegramLink = () => {
  clearTelegramTimer();
  telegramLink.code = "";
  telegramLink.status = "idle";
  telegramLink.expiresIn = null;
  telegramLink.expiresAt = null;
  telegramLink.ttlMinutes = null;
  telegramLink.chatId = "";
  telegramLink.chatTitle = "";
  telegramLink.error = "";
};

const startTelegramLinking = async () => {
  if (!isAdmin.value || telegramLink.loading || loadingSettings.value) return;
  telegramLink.loading = true;
  telegramLink.error = "";
  telegramLink.status = "waiting";
  telegramLink.chatId = "";
  telegramLink.chatTitle = "";
  telegramLink.expiresIn = null;
  telegramLink.expiresAt = null;
  telegramLink.ttlMinutes = null;
  clearTelegramTimer();
  try {
    const resp = await api.createTelegramLinkCode();
    telegramLink.code = resp?.code || "";
    telegramLink.ttlMinutes = resp?.ttl_minutes ?? null;
    const expiresRaw = resp?.expires_at ? Date.parse(resp.expires_at) : null;
    telegramLink.expiresAt =
      Number.isFinite(expiresRaw) && expiresRaw > 0
        ? expiresRaw
        : telegramLink.ttlMinutes
          ? Date.now() + telegramLink.ttlMinutes * 60 * 1000
          : null;
    telegramLink.status = "waiting";
    if (!telegramLink.code) {
      throw new Error("no-link-code");
    }
    telegramStatusTimer = setInterval(() => checkTelegramLinkStatus(true), 4000);
    ElMessage.success("Код привязки получен. Отправьте /link в группе.");
  } catch (error) {
    console.log(error);
    telegramLink.status = "error";
    telegramLink.error = "Не удалось получить код привязки";
    ElMessage.error(telegramLink.error);
  } finally {
    telegramLink.loading = false;
  }
};

const checkTelegramLinkStatus = async (silent = false) => {
  if (!telegramLink.code) {
    clearTelegramTimer();
    return;
  }
  if (telegramLink.expiresAt && telegramLink.expiresAt <= Date.now()) {
    telegramLink.status = "expired";
    clearTelegramTimer();
    return;
  }
  if (!silent) {
    telegramLink.checking = true;
  }
  try {
    const resp = await api.getSettings();
    const s = resp?.settings || resp || {};
    const chatId = s.chat_id ? String(s.chat_id) : "";

    if (chatId) {
      telegramLink.chatId = chatId;
      telegramLink.status = "linked";
      settings.chat_id = chatId;
      originalSettings.chat_id = chatId;
      clearTelegramTimer();
      ElMessage.success("Чат привязан, chat_id обновлён.");
      return;
    }

    telegramLink.status = "waiting";
  } catch (error) {
    console.log(error);
    telegramLink.status = "error";
    telegramLink.error = "Не удалось проверить статус привязки";
    clearTelegramTimer();
  } finally {
    telegramLink.checking = false;
  }
};

const copyLinkCode = async () => {
  if (!telegramLink.code) return;
  try {
    if (navigator?.clipboard?.writeText) {
      await navigator.clipboard.writeText(telegramLink.code);
    } else {
      const input = document.createElement("input");
      input.value = telegramLink.code;
      document.body.appendChild(input);
      input.select();
      document.execCommand("copy");
      document.body.removeChild(input);
    }
    ElMessage.success("Код скопирован");
  } catch (error) {
    console.log(error);
    ElMessage.error("Не удалось скопировать код");
  }
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

onUnmounted(() => {
  clearTelegramTimer();
});

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
