<script setup lang="ts">
import { computed, onMounted } from "vue";
import { useI18n } from "vue-i18n";
import { RouterLink, useRoute, useRouter } from "vue-router";
import { applySignedOut, bootstrapSession, user } from "../../application/session";
import AppIcon from "./AppIcon.vue";
import AppLogo from "./AppLogo.vue";
import LocaleToggle from "./LocaleToggle.vue";
import ThemeToggle from "./ThemeToggle.vue";

const { t } = useI18n();
const route = useRoute();
const router = useRouter();

onMounted(() => {
  void bootstrapSession();
});

async function logout() {
  await applySignedOut();
  await router.push("/");
}

function isNavActive(path: string) {
  const current = route.path.replace(/\/$/, "") || "/";
  if (path === "/") return current === "/";
  return current === path || current.startsWith(`${path}/`);
}

const isGuest = computed(() => !user.value || user.value.guest || !user.value.email);
const onLogin = computed(() => isNavActive("/login"));
</script>

<template>
  <header class="app-header">
    <div class="app-header-inner">
      <RouterLink
        to="/"
        class="app-brand"
      >
        <AppLogo />
        <div>
          <p class="font-display text-base font-semibold tracking-tight">
            {{ t("app.name") }}
          </p>
          <p class="text-xs text-muted-foreground">
            {{ t("app.tagline") }}
          </p>
        </div>
      </RouterLink>
      <nav
        class="app-header-nav"
        :aria-label="t('nav.chat')"
      >
        <RouterLink
          to="/"
          class="btn btn-ghost"
          :class="{ 'is-active': isNavActive('/') }"
          :aria-current="isNavActive('/') ? 'page' : undefined"
          data-testid="nav-chat"
        >
          <AppIcon name="chat" />
          {{ t("nav.chat") }}
        </RouterLink>
        <RouterLink
          to="/about"
          class="btn btn-ghost"
          :class="{ 'is-active': isNavActive('/about') }"
          :aria-current="isNavActive('/about') ? 'page' : undefined"
          data-testid="nav-about"
        >
          <AppIcon name="about" />
          {{ t("nav.about") }}
        </RouterLink>
        <ThemeToggle />
        <LocaleToggle />
      </nav>
      <div class="app-header-auth">
        <RouterLink
          v-if="isGuest && !onLogin"
          to="/login"
          class="btn btn-outline"
          :class="{ 'is-active': isNavActive('/login') }"
          :aria-current="isNavActive('/login') ? 'page' : undefined"
          data-testid="nav-login"
        >
          <AppIcon name="login" />
          {{ t("nav.login") }}
        </RouterLink>
        <button
          v-else-if="!isGuest"
          type="button"
          class="btn btn-outline"
          data-testid="auth-logout"
          @click="logout"
        >
          <AppIcon name="logout" />
          {{ t("nav.logout") }}
        </button>
      </div>
    </div>
  </header>
</template>
