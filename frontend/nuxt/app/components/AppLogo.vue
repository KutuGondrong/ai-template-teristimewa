<script setup lang="ts">
withDefaults(defineProps<{ size?: "sm" | "md" | "lg" }>(), { size: "md" });
</script>

<template>
  <svg
    viewBox="0 0 32 32"
    fill="none"
    aria-hidden="true"
    :class="{
      'app-logo-sm': size === 'sm',
      'app-logo': size === 'md',
      'app-logo-lg': size === 'lg',
    }"
  >
    <rect
      width="32"
      height="32"
      rx="10"
      fill="#163a6b"
    />
    <rect
      width="32"
      height="14"
      rx="10"
      fill="#4a7bb0"
      opacity="0.38"
    />
    <path
      fill="#fff"
      d="M8.2 11.1c0-1.55 1.25-2.8 2.8-2.8h9c1.55 0 2.8 1.25 2.8 2.8v6.2c0 1.55-1.25 2.8-2.8 2.8h-3.45L12.4 22.8v-2.7h-1.4c-1.55 0-2.8-1.25-2.8-2.8z"
    />
    <path
      fill="#fff"
      d="M23.55 6.15 24.5 8.9l2.75.95-2.75.95-.95 2.75-.95-2.75-2.75-.95 2.75-.95z"
    />
  </svg>
</template>
