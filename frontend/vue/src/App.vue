<script setup lang="ts">
import { RouterView } from "vue-router";
import AppHeader from "./presentation/components/AppHeader.vue";
</script>

<template>
  <div class="app-canvas">
    <AppHeader />
    <main class="app-main">
      <RouterView />
    </main>
  </div>
</template>
