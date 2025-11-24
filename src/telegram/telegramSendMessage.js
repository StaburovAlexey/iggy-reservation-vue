import { API, TELEGRAM_CHAT_ID } from "@/lib/telegramApi";

export async function sendPushMessage(data, date) {
  if (!API || !TELEGRAM_CHAT_ID) {
    console.warn(
      "Телеграм токен или chat_id не заданы. Отправка уведомления пропущена."
    );
    return;
  }

  const text = `Новая бронь на ${data.time || "-"} (${date || "-"})\n
  Имя ${data.name || "-"}
  Гостей: ${data.person || "-"}
  Телефон: ${data.tel || "-"}`;

  try {
    await fetch(API, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        chat_id: TELEGRAM_CHAT_ID,
        text,
      }),
    });
  } catch (error) {
    console.log(error);
  }
}
