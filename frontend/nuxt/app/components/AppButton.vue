<script setup lang="ts">
withDefaults(
  defineProps<{
    variant?: "primary" | "outline" | "ghost" | "icon";
    type?: "button" | "submit";
    disabled?: boolean;
  }>(),
  { variant: "primary", type: "button", disabled: false },
);
</script>

<template>
  <button
    :type="type"
    class="btn"
    :class="{
      'btn-primary': variant === 'primary',
      'btn-outline': variant === 'outline',
      'btn-ghost': variant === 'ghost',
      'btn-icon': variant === 'icon',
    }"
    :disabled="disabled"
  >
    <slot />
  </button>
</template>
