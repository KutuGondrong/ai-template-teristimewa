import { createApp } from "vue";
import { createI18n } from "vue-i18n";
import App from "./App.vue";
import { router } from "./presentation/router";
import id from "./i18n/locales/id.json";
import en from "./i18n/locales/en.json";
import "./styles.css";

const saved = localStorage.getItem("locale") ?? "id";

const i18n = createI18n({
  legacy: false,
  locale: saved,
  fallbackLocale: "en",
  messages: { id, en },
});

createApp(App).use(i18n).use(router).mount("#app");
