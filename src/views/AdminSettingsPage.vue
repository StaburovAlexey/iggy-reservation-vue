<template>
  <div class="admin-settings-page">
    <NavBar />
    <div class="admin-settings-page__body">
      <div v-if="initializing" class="settings-loader">
        <PreloaderApp />
      </div>
      <template v-else>
        <el-card class="invite-card" shadow="never">
          <div class="invite-card__header">
            <div>
              <h3 class="invite-card__title">Пригласить нового пользователя</h3>
              <p class="invite-card__subtitle">
                Укажите имя, e-mail и роль пользователя, чтобы отправить приглашение в систему.
              </p>
            </div>
          </div>
          <div class="invite-card__form">
            <el-input v-model="newUser.email" type="email" placeholder="Email нового сотрудника"
              :disabled="sendingInvite" />
            <el-input v-model="newUser.name" placeholder="Имя" :disabled="sendingInvite" />
            <el-input v-model="newUser.password" type="password" placeholder="Пароль" :disabled="sendingInvite"
              show-password />
            <el-select v-model="newUser.role" placeholder="Роль" style="min-width: 140px" :disabled="sendingInvite">
              <el-option label="Администратор" value="admin" />
              <el-option label="Пользователь" value="user" />
            </el-select>
            <el-button type="primary" :loading="sendingInvite" :disabled="sendingInvite" @click="createUser">
              Создать пользователя
            </el-button>
          </div>
        </el-card>

        <el-card class="settings-card" shadow="never">
          <div class="settings-card__header">
            <div>
              <h3 class="settings-card__title">Настройки интеграций</h3>
              <p class="settings-card__subtitle">Сохраните идентификаторы bot_id, chat_id и admin_chat.</p>
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
              <el-button type="primary" :loading="savingSettings" :disabled="savingSettings || loadingSettings"
                @click="saveSettings">
                Сохранить </el-button>
            </div>
          </el-form>

          <el-divider />

          <div class="telegram-link">
            <div class="telegram-link__header">
              <div>
                <h4 class="telegram-link__title">Связь с Telegram</h4>
                <p class="telegram-link__subtitle">
                  Используйте команду <code>/link</code> в боте и введите сгенерированный код, чтобы привязать чат.
                </p>
              </div>
              <div class="telegram-link__actions">
                <el-button type="primary" :loading="telegramLink.loading"
                  :disabled="telegramLink.loading || loadingSettings" @click="startTelegramLinking">
                  Сгенерировать код
                </el-button>
                <el-button v-if="telegramLink.code" :disabled="telegramLink.loading || loadingSettings"
                  @click="resetTelegramLink">
                  Сбросить код
                </el-button>
              </div>
            </div>

            <div v-if="telegramLink.code" class="telegram-link__code-block">
              <div class="telegram-link__code">{{ telegramLink.code }}</div>
              <div class="telegram-link__hint">
                <p>1. Откройте чат с ботом и отправьте команду <code>/link</code>.</p>
                <p>2. Вставьте код <code>/link {{ telegramLink.code }}</code>.</p>
                <p>3. После подтверждения чат_id отобразится ниже и будет связан с системой.</p>
              </div>
              <div class="telegram-link__status">
                <el-tag :type="telegramLinkTagType" size="small">
                  {{ telegramLinkStatusText }}
                </el-tag>
                <div class="telegram-link__status-actions">
                  <el-button size="small" :loading="telegramLink.checking" @click="copyLinkCode">
                    Скопировать код
                  </el-button>
                  <el-button size="small" :loading="telegramLink.checking" :disabled="telegramLink.status === 'linked'"
                    @click="checkTelegramLinkStatus">
                    Проверить статус
                  </el-button>
                </div>
              </div>
              <p v-if="telegramExpiresInMinutes !== null" class="telegram-link__expires">
                Код действует примерно {{ telegramExpiresInMinutes }} минут.
              </p>
              <p v-if="telegramLink.chatId" class="telegram-link__chat">
                Текущий chat_id:<strong>{{ telegramLink.chatId }}</strong>
                <span v-if="telegramLink.chatTitle">&nbsp;({{ telegramLink.chatTitle }})</span>
              </p>
            </div>
            <div v-else class="telegram-link__placeholder">
              <p>Сгенерируйте код, чтобы связать Telegram-канал и начать получать уведомления.</p>
            </div>
          </div>
        </el-card>
      </template>
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

const sendingInvite = ref(false);
const loadingSettings = ref(false);
const savingSettings = ref(false);
const initializing = ref(true);

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

const isAdmin = computed(
  () => authStore.user?.role === "admin" || authStore.user?.user_metadata?.role === "admin"
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

const createUser = async () => {
  if (!isAdmin.value) return;
  const email = (newUser.email || "").trim().toLowerCase();
  const emailPattern = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
  if (!emailPattern.test(email)) {
    ElMessage.warning("Укажите корректный адрес e-mail.");
    return;
  }
  if (!email || !newUser.password) {
    ElMessage.warning("Введите электронную почту и пароль.");
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
      ElMessage.success("Пользователь приглашён.");
      newUser.email = "";
      newUser.name = "";
      newUser.password = "";
      newUser.role = "user";
    } else {
      ElMessage.error("Не удалось пригласить пользователя.");
    }
  } catch (error) {
    console.log(error);
    ElMessage.error("Приглашение не отправлено, попробуйте позже.");
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
    ElMessage.success("Сейчас вы можете отправить команду /link в Telegram-боте.");
  } catch (error) {
    console.log(error);
    telegramLink.status = "error";
    telegramLink.error = "گ?گç ‘?گ?گّگ>گ?‘?‘? گُگ?گ>‘?‘طگٌ‘'‘? گَگ?گ? گُ‘?گٌگ?‘?گْگَگٌ";
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
      ElMessage.success("Связь установлена, chat_id сохранён.");
      return;
    }

    telegramLink.status = "waiting";
  } catch (error) {
    console.log(error);
    telegramLink.status = "error";
    telegramLink.error = "گ?گç ‘?گ?گّگ>گ?‘?‘? گُ‘?گ?گ?گç‘?گٌ‘'‘? ‘?‘'گّ‘'‘?‘? گُ‘?گٌگ?‘?گْگَگٌ";
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
    ElMessage.success("Код скопирован.");
  } catch (error) {
    console.log(error);
    ElMessage.error("Не удалось скопировать код.");
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
    ElMessage.error("Ошибка при загрузке настроек.");
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
    ElMessage.success("Настройки обновлены.");
  } catch (error) {
    console.log(error);
    ElMessage.error("Не удалось сохранить настройки.");
  } finally {
    savingSettings.value = false;
  }
};

onUnmounted(() => {
  clearTelegramTimer();
});

onMounted(async () => {
  if (!isAdmin.value) {
    ElMessage.warning("У вас нет доступа к этому разделу.");
    router.push("/");
    return;
  }
  await loadSettings();
  initializing.value = false;
});
</script>

<style scoped lang="scss">
.admin-settings-page {
  min-height: 100vh;
  background: radial-gradient(circle at 10% 20%, rgba(255, 255, 255, 0.08), transparent 30%),
    radial-gradient(circle at 90% 10%, rgba(255, 255, 255, 0.05), transparent 25%),
    linear-gradient(180deg, var(--gradient-start) 0%, var(--gradient-end) 100%);
}

.admin-settings-page__body {
  max-width: 820px;
  margin: 0 auto;
  padding: 20px 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.settings-loader {
  min-height: 240px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.invite-card,
.settings-card {
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

.settings-form__actions .el-button+.el-button {
  margin-left: 0;
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
