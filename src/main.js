import { createApp } from "vue";
import App from "./App.vue";
import router from "./router";
import store from "./store";
import "materialize-css/dist/css/materialize.min.css";
import "materialize-css/dist/js/materialize";

createApp(App).use(store).use(router).mount("#app");
