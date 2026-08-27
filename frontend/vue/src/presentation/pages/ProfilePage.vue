<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { useI18n } from "vue-i18n";
import { useRouter } from "vue-router";
import { applySignedOut, bootstrapSession, user } from "../../application/session";
import AppButton from "../components/AppButton.vue";
import AppIcon from "../components/AppIcon.vue";

const { t } = useI18n();
const router = useRouter();
const ready = ref(false);

const isGuest = computed(() => !user.value || user.value.guest || !user.value.email);
const avatarInitial = computed(() => (user.value?.email?.[0] ?? "?").toUpperCase());

onMounted(async () => {
  await bootstrapSession();
  ready.value = true;
  if (isGuest.value) await router.replace("/login");
});

async function logout() {
  await applySignedOut();
  await router.push("/");
}
</script>

<template>
  <article
    v-if="ready && !isGuest && user"
    class="auth-card mx-auto space-y-4"
    data-testid="profile-page"
  >
    <div class="flex items-center gap-3">
      <span class="profile-avatar profile-avatar-lg">{{ avatarInitial }}</span>
      <h1 class="font-display text-2xl font-semibold">
        {{ t("profile.title") }}
      </h1>
    </div>
    <dl class="grid grid-cols-2 gap-2 text-sm">
      <dt class="text-muted-foreground">
        {{ t("profile.email") }}
      </dt>
      <dd data-testid="profile-email">
        {{ user.email }}
      </dd>
      <dt class="text-muted-foreground">
        {{ t("profile.id") }}
      </dt>
      <dd data-testid="profile-id">
        {{ user.id }}
      </dd>
    </dl>
    <AppButton
      variant="outline"
      data-testid="auth-logout"
      @click="logout"
    >
      <AppIcon name="logout" />
      {{ t("nav.logout") }}
    </AppButton>
  </article>
</template>
