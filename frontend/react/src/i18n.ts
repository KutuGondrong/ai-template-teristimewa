import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import id from "./i18n/locales/id.json";
import en from "./i18n/locales/en.json";

void i18n.use(initReactI18next).init({
  resources: { id: { translation: id }, en: { translation: en } },
  lng: localStorage.getItem("locale") ?? "id",
  fallbackLng: "en",
  interpolation: { escapeValue: false },
});

export default i18n;
