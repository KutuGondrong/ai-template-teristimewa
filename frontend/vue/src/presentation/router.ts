import { createRouter, createWebHistory } from "vue-router";
import ChatPage from "./pages/ChatPage.vue";
import AuthPage from "./pages/AuthPage.vue";
import AboutPage from "./pages/AboutPage.vue";
import ProfilePage from "./pages/ProfilePage.vue";

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior() {
    return { top: 0 };
  },
  routes: [
    { name: "chat", path: "/", component: ChatPage },
    { name: "login", path: "/login", component: AuthPage, props: { mode: "login" } },
    { name: "signup", path: "/signup", component: AuthPage, props: { mode: "signup" } },
    { name: "about", path: "/about", component: AboutPage },
    { name: "profile", path: "/profile", component: ProfilePage },
  ],
});
