import { API, TELEGRAM_CHAT_ID } from "@/lib/telegramApi";

export async function sendPushMessage(data, date) {
  if (!API || !TELEGRAM_CHAT_ID) {
    console.warn(
      "Телеграм токен или chat_id не заданы. Укажите переменные и повторите отправку."
    );
    return;
  }

  const text = `Новая бронь: ${data.time || "-"} (${date || "-"}
Гость: ${data.name || "-"}
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
