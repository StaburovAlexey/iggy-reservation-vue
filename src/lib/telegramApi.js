const TELEGRAM_BOT_TOKEN = process.env.VUE_APP_TELEGRAM_BOT_TOKEN || "";
export const TELEGRAM_CHAT_ID = process.env.VUE_APP_TELEGRAM_CHAT_ID || "";

if (!TELEGRAM_BOT_TOKEN || !TELEGRAM_CHAT_ID) {
  console.warn(
    "Не заданы VUE_APP_TELEGRAM_BOT_TOKEN и VUE_APP_TELEGRAM_CHAT_ID. Укажите их в .env.local."
  );
}

export const API = TELEGRAM_BOT_TOKEN
  ? `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`
  : "";
