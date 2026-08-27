<script setup lang="ts">
const { t } = useI18n();
const { user, bootstrap, applySignedOut } = useSession();
const route = useRoute();
const localePath = useLocalePath();

onMounted(() => {
  void bootstrap();
});

async function logout() {
  await applySignedOut();
  await navigateTo(localePath("/"));
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
      <NuxtLink
        :to="localePath('/')"
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
      </NuxtLink>
      <nav
        class="app-header-nav"
        :aria-label="t('nav.chat')"
      >
        <NuxtLink
          :to="localePath('/')"
          class="btn btn-ghost"
          :class="{ 'is-active': isNavActive('/') }"
          :aria-current="isNavActive('/') ? 'page' : undefined"
          data-testid="nav-chat"
        >
          <AppIcon name="chat" />
          {{ t("nav.chat") }}
        </NuxtLink>
        <NuxtLink
          :to="localePath('/about')"
          class="btn btn-ghost"
          :class="{ 'is-active': isNavActive('/about') }"
          :aria-current="isNavActive('/about') ? 'page' : undefined"
          data-testid="nav-about"
        >
          <AppIcon name="about" />
          {{ t("nav.about") }}
        </NuxtLink>
        <ThemeToggle />
        <LocaleToggle />
      </nav>
      <div class="app-header-auth">
        <NuxtLink
          v-if="isGuest && !onLogin"
          :to="localePath('/login')"
          class="btn btn-outline"
          :class="{ 'is-active': isNavActive('/login') }"
          :aria-current="isNavActive('/login') ? 'page' : undefined"
          data-testid="nav-login"
        >
          <AppIcon name="login" />
          {{ t("nav.login") }}
        </NuxtLink>
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
