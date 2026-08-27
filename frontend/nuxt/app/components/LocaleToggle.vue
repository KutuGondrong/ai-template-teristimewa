<script setup lang="ts">
const { t, locale, setLocale } = useI18n();
const localeCookie = useCookie<"id" | "en">("locale", {
  default: () => "id",
  sameSite: "lax",
});

onMounted(() => {
  if (localeCookie.value && localeCookie.value !== locale.value) {
    void setLocale(localeCookie.value);
  }
});

async function choose(next: "id" | "en") {
  if (locale.value === next) return;
  await setLocale(next);
  localeCookie.value = next;
}
</script>

<template>
  <div
    class="seg-toggle"
    role="group"
    :aria-label="t('nav.language')"
    data-testid="lang-switch"
  >
    <button
      type="button"
      :class="{ 'is-active': locale === 'id' }"
      :aria-pressed="locale === 'id'"
      @click="choose('id')"
    >
      ID
    </button>
    <button
      type="button"
      :class="{ 'is-active': locale === 'en' }"
      :aria-pressed="locale === 'en'"
      @click="choose('en')"
    >
      EN
    </button>
  </div>
</template>
