<script setup lang="ts">
import { isStrongPassword, isValidEmail } from "~/shared";

const props = defineProps<{ mode: "login" | "signup" }>();
const localePath = useLocalePath();
const { t } = useI18n();
const { authApi, applySignedIn } = useSession();
const route = useRoute();
const email = ref("");
const password = ref("");
const error = ref("");
const justRegistered = computed(
  () => props.mode === "login" && route.query.registered === "1",
);

async function submit() {
  error.value = "";
  const e = email.value.trim().toLowerCase();
  if (!isValidEmail(e)) {
    error.value = t("auth.invalidEmail");
    return;
  }
  if (props.mode === "signup" && !isStrongPassword(password.value)) {
    error.value = t("auth.weakPassword");
    return;
  }
  try {
    if (props.mode === "signup") {
      await authApi.signup(e, password.value);
      await navigateTo({ path: localePath("/login"), query: { registered: "1" } });
      return;
    }
    const next = await authApi.login(e, password.value);
    await applySignedIn(next);
    await navigateTo(localePath("/"));
  } catch (err: unknown) {
    const status = (err as { response?: { status?: number } })?.response?.status;
    if (status === 409) error.value = t("auth.emailTaken");
    else if (status === 401) error.value = t("auth.wrongCredentials");
    else error.value = t("errors.network");
  }
}
</script>

<template>
  <form
    class="auth-card mx-auto flex flex-col gap-4"
    data-testid="auth-form"
    @submit.prevent="submit"
  >
    <div class="flex flex-col items-center text-center">
      <AppLogo size="lg" />
      <h1 class="mt-3 font-display text-2xl font-semibold">
        {{ mode === "login" ? t("nav.login") : t("nav.signup") }}
      </h1>
      <p class="mt-1 text-sm text-muted-foreground">
        {{ mode === "login" ? t("auth.subtitleLogin") : t("auth.subtitleSignup") }}
      </p>
    </div>
    <label class="text-sm">
      {{ t("auth.email") }}
      <input
        v-model="email"
        type="email"
        class="field"
        data-testid="auth-email"
      >
    </label>
    <label class="text-sm">
      {{ t("auth.password") }}
      <input
        v-model="password"
        type="password"
        class="field"
        data-testid="auth-password"
      >
    </label>
    <p
      v-if="justRegistered && !error"
      class="text-sm text-primary"
      data-testid="auth-success"
    >
      {{ t("auth.signupSuccess") }}
    </p>
    <p
      v-if="error"
      class="text-sm text-destructive"
      data-testid="auth-error"
    >
      {{ error }}
    </p>
    <AppButton
      type="submit"
      data-testid="auth-submit"
    >
      {{ mode === "login" ? t("auth.submitLogin") : t("auth.submitSignup") }}
    </AppButton>
    <p class="text-center text-sm text-muted-foreground">
      <template v-if="mode === 'login'">
        {{ t("auth.noAccount") }}
        <NuxtLink
          :to="localePath('/signup')"
          class="text-primary"
          data-testid="nav-signup"
        >{{ t("nav.signup") }}</NuxtLink>
      </template>
      <template v-else>
        {{ t("auth.haveAccount") }}
        <NuxtLink
          :to="localePath('/login')"
          class="text-primary"
        >{{ t("nav.login") }}</NuxtLink>
      </template>
    </p>
  </form>
</template>
