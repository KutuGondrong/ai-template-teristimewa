import { defineNuxtConfig } from "nuxt/config";
import tailwindcss from "@tailwindcss/vite";

export default defineNuxtConfig({
  compatibilityDate: "2025-07-15",
  devtools: { enabled: false },
  ssr: false,
  css: ["~/assets/css/main.css"],
  modules: ["@nuxtjs/i18n"],
  i18n: {
    locales: [
      { code: "id", language: "id-ID", file: "id.json", name: "Indonesia" },
      { code: "en", language: "en-US", file: "en.json", name: "English" },
    ],
    defaultLocale: "id",
    strategy: "no_prefix",
    lazy: true,
    langDir: "locales",
    detectBrowserLanguage: false,
  },
  runtimeConfig: {
    public: {
      appEnv: process.env.NUXT_PUBLIC_APP_ENV || "local",
      apiUrl: process.env.NUXT_PUBLIC_API_URL || "http://127.0.0.1:8000",
    },
  },
  devServer: {
    host: "127.0.0.1",
    port: 3000,
  },
  vite: {
    plugins: [tailwindcss()],
  },
  nitro: {
    publicAssets: [{ dir: "public" }],
  },
  app: {
    head: {
      title: "AI Template [nuxt]",
      htmlAttrs: { class: "dark", lang: "id" },
      script: [
        {
          innerHTML:
            "(function(){try{var t=localStorage.getItem('theme');if(t==='light')document.documentElement.classList.remove('dark');else document.documentElement.classList.add('dark');}catch(e){}})();",
        },
      ],
      link: [
        { rel: "preconnect", href: "https://fonts.googleapis.com" },
        { rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: "" },
        {
          rel: "stylesheet",
          href: "https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap",
        },
        { rel: "icon", type: "image/svg+xml", href: "/favicon.svg" },
      ],
    },
  },
});
