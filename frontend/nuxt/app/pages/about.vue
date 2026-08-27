<script setup lang="ts">
import type { LlmActive } from "~/shared";

const { t, locale } = useI18n();
const llm = ref<LlmActive | null>(null);

onMounted(async () => {
  try {
    llm.value = await $fetch<LlmActive>("/llm.active.json");
  } catch {
    llm.value = null;
  }
});
</script>

<template>
  <div class="about-page" data-testid="about-page">
    <section class="about-section" data-testid="about-model">
      <h2>{{ t("about.title") }}</h2>
      <template v-if="llm">
        <p class="about-lead">
          {{ llm.name }} {{ llm.version }}
        </p>
        <p class="about-body">
          {{ locale === "id" ? llm.about_id : llm.about_en }}
        </p>
        <dl class="mt-4 grid grid-cols-2 gap-2 text-sm">
          <dt class="text-muted-foreground">
            {{ t("about.vendor") }}
          </dt>
          <dd>{{ llm.vendor }}</dd>
          <dt class="text-muted-foreground">
            {{ t("about.license") }}
          </dt>
          <dd>{{ llm.license }}</dd>
          <dt class="text-muted-foreground">
            {{ t("about.weight") }}
          </dt>
          <dd>{{ llm.weight }}</dd>
          <dt class="text-muted-foreground">
            {{ t("about.ram") }}
          </dt>
          <dd>{{ llm.ram_min_gb }} GB</dd>
          <dt class="text-muted-foreground">
            {{ t("about.cpu") }}
          </dt>
          <dd>{{ llm.cpu_min_cores }}</dd>
          <dt class="text-muted-foreground">
            {{ t("about.disk") }}
          </dt>
          <dd>{{ llm.disk_min_gb }} GB</dd>
          <dt class="text-muted-foreground">
            {{ t("about.gpu") }}
          </dt>
          <dd>{{ llm.gpu }}</dd>
        </dl>
      </template>
    </section>

    <section class="about-section" data-testid="about-maker">
      <p class="about-body">
        {{ t("about.makerBody") }}
      </p>
      <p class="about-links">
        <a
          class="about-link"
          href="https://teristimewa.com/"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ t("about.makerStudioCta") }}
        </a>
        <a
          class="about-link"
          href="https://hedysimamora.teristimewa.com/"
          target="_blank"
          rel="noopener noreferrer"
        >
          {{ t("about.makerDevCta") }}
        </a>
      </p>
    </section>
  </div>
</template>
