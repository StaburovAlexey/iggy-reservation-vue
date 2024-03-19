import { API, TELEGRAM_CHAT_ID} from "@/lib/telegramApi";

export async function sendPushMessage(data) {
  const text = `Новая бронь! Не проеби, там ${data.person} человек в ${data.time} и возможно на сегодня. но это не точно....`;
  try {
    const response = await fetch(API, {
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
    throw error;
  }
}
