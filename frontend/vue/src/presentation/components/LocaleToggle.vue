<script setup lang="ts">
import { useI18n } from "vue-i18n";

const { t, locale } = useI18n();

function choose(next: "id" | "en") {
  if (locale.value === next) return;
  locale.value = next;
  localStorage.setItem("locale", next);
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
