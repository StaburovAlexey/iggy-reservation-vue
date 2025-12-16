<template>
  <div class="admin-settings-page">
    <NavBar />
    <div class="admin-settings-page__body">
      <div v-if="initializing" class="settings-loader">
        <PreloaderApp />
      </div>
      <template v-else>
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
              <el-button type="primary" :loading="savingSettings" :disabled="savingSettings || loadingSettings" @click="saveSettings">
                Сохранить настройки
              </el-button>
            </div>
          </el-form>
        </el-card>

        <el-card class="telegram-card" shadow="never">
          <div class="telegram-card__header">
            <div>
              <h3 class="telegram-card__title">Связь с Telegram</h3>
              <p class="telegram-card__subtitle">
                Используйте команду <code>/link</code> в боте и вставьте сгенерированный код для привязки чата.
              </p>
            </div>
            <div class="telegram-card__actions">
              <el-button
                type="primary"
                :loading="telegramLink.loading"
                :disabled="telegramLink.loading || loadingSettings"
                @click="startTelegramLinking"
              >
                Сгенерировать код
              </el-button>
              <el-button v-if="telegramLink.code" :disabled="telegramLink.loading || loadingSettings" @click="resetTelegramLink">
                Сбросить код
              </el-button>
            </div>
          </div>

          <div v-if="telegramLink.code" class="telegram-card__code-block">
            <div class="telegram-card__code">{{ telegramLink.code }}</div>
            <div class="telegram-card__hint">
              <p>1. Отправьте в чате с ботом команду <code>/link</code>.</p>
              <p>2. Вставьте код: <code>/link {{ telegramLink.code }}</code>.</p>
              <p>3. После подтверждения chat_id отобразится ниже и сохранится в настройках.</p>
            </div>
            <div class="telegram-card__status">
              <el-tag :type="telegramLinkTagType" size="small">{{ telegramLinkStatusText }}</el-tag>
              <div class="telegram-card__status-actions">
                <el-button size="small" :loading="telegramLink.checking" @click="copyLinkCode">Скопировать код</el-button>
                <el-button
                  size="small"
                  :loading="telegramLink.checking"
                  :disabled="telegramLink.status === 'linked'"
                  @click="checkTelegramLinkStatus"
                >
                  Проверить статус
                </el-button>
              </div>
            </div>
            <p v-if="telegramExpiresInMinutes !== null" class="telegram-card__expires">
              Код действителен примерно {{ telegramExpiresInMinutes }} минут.
            </p>
            <p v-if="telegramLink.chatId" class="telegram-card__chat">
              chat_id: <strong>{{ telegramLink.chatId }}</strong>
              <span v-if="telegramLink.chatTitle">&nbsp;({{ telegramLink.chatTitle }})</span>
            </p>
          </div>
          <div v-else class="telegram-card__placeholder">
            <p>Сгенерируйте код, чтобы привязать Telegram-канал и получать уведомления.</p>
          </div>
        </el-card>

        <el-card class="backup-card" shadow="never">
          <div class="backup-card__header">
            <div>
              <h3 class="backup-card__title">Резервная копия</h3>
              <p class="backup-card__subtitle">Скачайте архив базы или восстановите данные из .zip-файла.</p>
            </div>
          </div>
          <div class="backup-card__actions">
            <el-button type="primary" :loading="backupLoading" @click="downloadBackup">Скачать бекап</el-button>
            <el-button type="danger" :loading="restoreLoading" :disabled="!restoreFile" @click="restoreBackupFile">
              Восстановить
            </el-button>
          </div>
          <div class="backup-card__restore">
            <label class="backup-card__file">
              <span>Выберите архив (.zip)</span>
              <input type="file" accept=".zip" @change="handleRestoreFileChange" />
            </label>
            <span class="backup-card__file-name">{{ restoreFileName }}</span>
          </div>
          <p v-if="restoreStatus" class="backup-card__status">{{ restoreStatus }}</p>
        </el-card>

        <el-card class="magic-card" shadow="never">
          <div class="magic-card__header">
            <div>
              <h3 class="magic-card__title">Magic-ссылка</h3>
              <p class="magic-card__subtitle">Сгенерируйте QR-код, чтобы отправить приглашение по e-mail.</p>
            </div>
          </div>
          <div class="magic-card__form">
            <el-input
              v-model="magicEmail"
              placeholder="Email приглашённого"
              :disabled="magicLoading"
              clearable
              prefix-icon="el-icon-message"
            />
            <el-select v-model="magicRole" placeholder="Роль" :disabled="magicLoading">
              <el-option label="Пользователь" value="user" />
              <el-option label="Администратор" value="admin" />
            </el-select>
          </div>
          <div class="magic-card__qr">
            <canvas ref="magicCanvas"></canvas>
            <div v-if="!magicQrReady" class="magic-card__qr-placeholder">QR-код появится после генерации</div>
          </div>
          <div class="magic-card__link">
            <span class="magic-card__link-label">Ссылка:</span>
            <span class="magic-card__link-value">{{ magicLink || "Сначала сгенерируйте ссылку" }}</span>
          </div>
          <div class="magic-card__status-row">
            <el-tag
              size="small"
              :type="magicStatusTag"
            >
              {{ magicStatusText }}
            </el-tag>
            <p v-if="magicExpiresText && magicStatus !== 'approved'" class="magic-card__status">{{ magicExpiresText }}</p>
          </div>
          <p v-if="magicErrorMessage" class="magic-card__error">{{ magicErrorMessage }}</p>
          <div class="magic-card__actions">
            <el-button
              type="primary"
              :loading="magicLoading"
              :disabled="magicLoading"
              @click="generateMagicLink"
            >
              {{ magicLink ? "Сгенерировать заново" : "Сгенерировать" }}
            </el-button>
            <el-button :disabled="!magicLink" @click="copyMagicLink">Скопировать ссылку</el-button>
          </div>
        </el-card>
      </template>
    </div>
  </div>
</template>

<script setup>
import { computed, nextTick, onMounted, onUnmounted, reactive, ref } from "vue";
import { useRouter } from "vue-router";
import { ElMessage } from "element-plus";
import QRCode from "qrcode";
import NavBar from "@/components/NavBar.vue";
import PreloaderApp from "@/components/PreloaderApp.vue";
import { api } from "@/api/client";
import { useAuthStore } from "@/store/auth";

const authStore = useAuthStore();
const router = useRouter();

const initializing = ref(true);
const loadingSettings = ref(false);
const savingSettings = ref(false);
const backupLoading = ref(false);
const restoreLoading = ref(false);
const restoreFile = ref(null);
const restoreStatus = ref("");
const magicLink = ref("");
const magicLoading = ref(false);
const magicExpires = ref("");
const magicQrReady = ref(false);
const magicCanvas = ref(null);
const magicEmail = ref("");
const magicRole = ref("user");
const magicToken = ref("");
const magicStatus = ref("");
const magicStoredEmail = ref("");
const magicErrorMessage = ref("");
let magicPollTimer = null;

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
    return `Связано с ${telegramLink.chatTitle || telegramLink.chatId}`;
  }
  if (telegramLink.status === "waiting") {
    return "Ждём подтверждения /link";
  }
  if (telegramLink.status === "expired") {
    return "Код истёк, сгенерируйте новый";
  }
  if (telegramLink.status === "error") {
    return telegramLink.error || "Ошибка привязки Telegram";
  }
  return "Получите код и отправьте его боту";
});

const telegramExpiresInMinutes = computed(() => {
  if (!telegramLink.expiresAt) return null;
  const diff = Math.ceil((telegramLink.expiresAt - Date.now()) / 60000);
  return diff > 0 ? diff : 0;
});

const magicExpiresText = computed(() => {
  if (!magicExpires.value) return "";
  const diff = Math.max(new Date(magicExpires.value).getTime() - Date.now(), 0);
  const minutes = Math.ceil(diff / 60000);
  return minutes > 0 ? `Ссылка действует ещё около ${minutes} мин.` : "Ссылка вот-вот истечёт.";
});

const magicStatusTag = computed(() => {
  if (magicStatus.value === "approved") return "success";
  if (magicStatus.value === "expired") return "warning";
  if (magicStatus.value === "pending") return "info";
  if (magicStatus.value === "invalid") return "danger";
  return "info";
});

const magicStatusText = computed(() => {
  if (!magicToken.value) {
    return "Укажите email и нажмите «Сгенерировать»";
  }
  switch (magicStatus.value) {
    case "pending":
      return magicStoredEmail.value ? `Ожидаем подтверждения ${magicStoredEmail.value}` : "Ожидаем подтверждения";
    case "approved":
      return "Ссылка одобрена. Можно использовать для входа.";
    case "expired":
      return "Срок ссылки истёк, сгенерируйте новую.";
    case "invalid":
      return "Ссылка недействительна.";
    default:
      return "Состояние ссылки неизвестно.";
  }
});

const restoreFileName = computed(() => (restoreFile.value ? restoreFile.value.name : "Файл не выбран"));

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
    if (!telegramLink.code) {
      throw new Error("no-code");
    }
    telegramStatusTimer = setInterval(() => checkTelegramLinkStatus(true), 4000);
    ElMessage.success("Отправьте /link в Telegram-боте для привязки.");
  } catch (error) {
    console.error(error);
    telegramLink.status = "error";
    telegramLink.error = "Не удалось сгенерировать код Telegram.";
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
      ElMessage.success("Связь с Telegram установлена.");
      return;
    }
    telegramLink.status = "waiting";
  } catch (error) {
    console.error(error);
    telegramLink.status = "error";
    telegramLink.error = "Не удалось проверить статус Telegram.";
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
    console.error(error);
    ElMessage.error("Не удалось скопировать код.");
  }
};

const downloadBackup = async () => {
  backupLoading.value = true;
  try {
    const payload = await api.downloadBackup();
    const url = URL.createObjectURL(payload.blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = payload.filename;
    document.body.appendChild(link);
    link.click();
    link.remove();
    URL.revokeObjectURL(url);
    ElMessage.success("Бекап скачан.");
  } catch (error) {
    console.error(error);
    ElMessage.error("Не удалось скачать бекап.");
  } finally {
    backupLoading.value = false;
  }
};

const handleRestoreFileChange = (event) => {
  restoreStatus.value = "";
  restoreFile.value = event.target?.files?.[0] || null;
};

const restoreBackupFile = async () => {
  if (!restoreFile.value) {
    ElMessage.warning("Выберите файл архива .zip.");
    return;
  }
  restoreLoading.value = true;
  try {
    await api.restoreBackup(restoreFile.value);
    restoreStatus.value = "Бекап успешно восстановлен.";
    ElMessage.success("Бекап восстановлен.");
  } catch (error) {
    console.error(error);
    const message = error?.response?.error || "Не удалось восстановить бекап.";
    restoreStatus.value = message;
    ElMessage.error(message);
  } finally {
    restoreLoading.value = false;
  }
};

const clearMagicPolling = () => {
  if (magicPollTimer) {
    clearInterval(magicPollTimer);
    magicPollTimer = null;
  }
};

const pollMagicLinkStatus = async () => {
  if (!magicToken.value) return;
  try {
    const response = await api.fetchMagicLink(magicToken.value);
    magicStatus.value = response?.status || "";
    magicExpires.value = response?.expires_at || magicExpires.value;
    magicStoredEmail.value = response?.email || magicStoredEmail.value;
    if (["approved", "expired", "invalid"].includes(magicStatus.value)) {
      clearMagicPolling();
    }
  } catch (error) {
    console.error(error);
    magicErrorMessage.value = "Не удалось получить статус magic-ссылки.";
    clearMagicPolling();
  }
};

const startMagicPolling = () => {
  clearMagicPolling();
  if (!magicToken.value) return;
  pollMagicLinkStatus();
  magicPollTimer = setInterval(pollMagicLinkStatus, 4000);
};

const renderMagicQr = async (value) => {
  if (!magicCanvas.value || !value) {
    magicQrReady.value = false;
    return;
  }
  try {
    await QRCode.toCanvas(magicCanvas.value, value, { margin: 1, width: 200 });
    magicQrReady.value = true;
  } catch (error) {
    console.error("QR error", error);
    magicQrReady.value = false;
  }
};

const generateMagicLink = async () => {
  if (!isAdmin.value) return;
  const email = (magicEmail.value || "").trim().toLowerCase();
  if (!email) {
    magicErrorMessage.value = "Укажите email приглашённого.";
    return;
  }
  magicLoading.value = true;
  magicErrorMessage.value = "";
  try {
    const response = await api.createMagicLink({ email, role: magicRole.value });
    magicLink.value = response?.magic_link || "";
    magicToken.value = response?.token || "";
    magicStoredEmail.value = email;
    magicExpires.value = response?.expires_at || "";
    magicStatus.value = "pending";
    await renderMagicQr(magicLink.value);
    startMagicPolling();
  } catch (error) {
    console.error(error);
    const message = error?.response?.error || "Не удалось создать magic-ссылку.";
    magicErrorMessage.value = message;
    ElMessage.error(message);
  } finally {
    magicLoading.value = false;
  }
};

const copyMagicLink = async () => {
  if (!magicLink.value) return;
  try {
    if (navigator?.clipboard?.writeText) {
      await navigator.clipboard.writeText(magicLink.value);
    } else {
      const temp = document.createElement("textarea");
      temp.value = magicLink.value;
      document.body.appendChild(temp);
      temp.select();
      document.execCommand("copy");
      document.body.removeChild(temp);
    }
    ElMessage.success("Ссылка скопирована.");
  } catch (error) {
    console.error(error);
    ElMessage.error("Не удалось скопировать ссылку.");
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
    console.error(error);
    ElMessage.error("Не удалось загрузить настройки.");
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
    ElMessage.success("Настройки сохранены.");
  } catch (error) {
    console.error(error);
    ElMessage.error("Не удалось сохранить настройки.");
  } finally {
    savingSettings.value = false;
  }
};

onUnmounted(() => {
  clearTelegramTimer();
  clearMagicPolling();
});

onMounted(async () => {
  if (!isAdmin.value) {
    ElMessage.warning("Доступ к этому разделу только для администраторов.");
    router.push("/");
    return;
  }
  await loadSettings();
  initializing.value = false;
  await nextTick();
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
  max-width: 860px;
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

.settings-card,
.telegram-card,
.backup-card,
.magic-card {
  background: var(--bg-surface);
  border: 1px solid var(--border-color);
}

.settings-card__header,
.telegram-card__header,
.backup-card__header,
.magic-card__header {
  margin-bottom: 8px;
}

.settings-card__title,
.telegram-card__title,
.backup-card__title,
.magic-card__title {
  margin: 0;
  color: var(--text-primary);
}

.settings-card__subtitle,
.telegram-card__subtitle,
.backup-card__subtitle,
.magic-card__subtitle {
  margin: 4px 0 0;
  color: var(--text-secondary);
  font-size: 13px;
}

.settings-form,
.telegram-card__header {
  display: flex;
  flex-wrap: wrap;
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

.telegram-card__actions {
  width: 100%;
}

.telegram-card__subtitle code {
  font-size: 11px;
}

.telegram-card__code-block {
  margin-top: 12px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  padding-top: 12px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.telegram-card__code {
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

.telegram-card__hint {
  background: var(--bg-surface-2);
  border-radius: 10px;
  padding: 10px 12px;
  border: 1px solid var(--border-color);
  color: var(--text-primary);
  opacity: 0.9;
}

.telegram-card__status {
  margin-top: 4px;
  display: flex;
  align-items: center;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: space-between;
}

.telegram-card__status-actions {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.telegram-card__expires,
.telegram-card__chat,
.telegram-card__placeholder {
  margin: 0;
  color: var(--text-primary);
}

.telegram-card__placeholder {
  padding: 12px;
  border-top: 1px dashed rgba(255, 255, 255, 0.2);
}

.backup-card__actions {
  margin-bottom: 12px;
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.backup-card__restore {
  display: flex;
  align-items: center;
  gap: 8px;
}

.backup-card__file {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  cursor: pointer;
  color: var(--text-primary);
}

.backup-card__file input {
  display: none;
}

.backup-card__file-name {
  font-size: 12px;
  color: var(--text-secondary);
}

.backup-card__status {
  margin-top: 8px;
  font-size: 13px;
  color: var(--text-secondary);
}

.magic-card {
  padding-bottom: 16px;
}

.magic-card__qr {
  margin-top: 8px;
  height: 220px;
  border-radius: 16px;
  border: 1px dashed rgba(255, 255, 255, 0.2);
  background: var(--bg-surface-2);
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
}

.magic-card__qr canvas {
  width: 200px;
  height: 200px;
}

.magic-card__qr-placeholder {
  position: absolute;
  text-align: center;
  color: var(--text-secondary);
  font-size: 14px;
  padding: 8px 16px;
}

.magic-card__link {
  margin-top: 16px;
  font-size: 13px;
  color: var(--text-secondary);
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.magic-card__link-label {
  font-weight: 600;
  color: var(--text-primary);
}

.magic-card__link-value {
  word-break: break-all;
  color: var(--text-primary);
}

.magic-card__actions {
  margin-top: 12px;
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.magic-card__status {
  margin-top: 8px;
  font-size: 12px;
  color: var(--text-secondary);
}

.magic-card__form {
  display: flex;
  gap: 8px;
  flex-wrap: wrap;
}

.magic-card__status-row {
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
  margin-top: 12px;
}

.magic-card__error {
  margin: 4px 0 0;
  color: #ff6b6b;
  font-size: 13px;
}
</style>
