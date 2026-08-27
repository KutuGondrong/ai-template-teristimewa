"use client";

import i18n from "i18next";
import { initReactI18next } from "react-i18next";
import id from "./i18n/locales/id.json";
import en from "./i18n/locales/en.json";

/** Same default on server + first client paint to avoid hydration mismatch. */
const DEFAULT_LOCALE = "id";

if (!i18n.isInitialized) {
  void i18n.use(initReactI18next).init({
    resources: { id: { translation: id }, en: { translation: en } },
    lng: DEFAULT_LOCALE,
    fallbackLng: DEFAULT_LOCALE,
    interpolation: { escapeValue: false },
  });
}

/** Apply saved locale after mount (client only). */
export function syncLocaleFromStorage() {
  if (typeof window === "undefined") return;
  const stored = localStorage.getItem("locale");
  if ((stored === "id" || stored === "en") && i18n.language !== stored) {
    void i18n.changeLanguage(stored);
  }
}

export default i18n;
