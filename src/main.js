import { createApp } from "vue";
import App from "./App.vue";
import router from "./router";
import pinia from "./store";
import "normalize.css";
import ElementPlus from "element-plus";
import "element-plus/dist/index.css";
export const tg = window.Telegram.WebApp;
createApp(App).use(pinia).use(router).use(ElementPlus).mount("#app");
