import { createApp } from "vue";
import App from "./App.vue";
import router from "./router";
import store from "./store";
import "normalize.css";
import ElementPlus from "element-plus";
import "element-plus/dist/index.css";
import ru from "element-plus/es/locale/lang/ru";
import dayjs from "dayjs";
import "dayjs/locale/ru";

dayjs.locale("ru");
export const tg = window.Telegram.WebApp;
createApp(App)
  .use(store)
  .use(router)
  .use(ElementPlus, {
    locale: ru,
  })
  .mount("#app");
