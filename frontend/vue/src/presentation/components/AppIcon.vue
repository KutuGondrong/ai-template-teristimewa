<script setup lang="ts">
defineProps<{
  name: "chat" | "about" | "login" | "signup" | "logout" | "user" | "globe";
}>();
</script>

<template>
  <svg
    viewBox="0 0 24 24"
    class="app-icon"
    fill="none"
    stroke="currentColor"
    stroke-width="1.8"
    stroke-linecap="round"
    stroke-linejoin="round"
    aria-hidden="true"
  >
    <template v-if="name === 'chat'">
      <path d="M5 8.4A3.4 3.4 0 0 1 8.4 5h7.2A3.4 3.4 0 0 1 19 8.4v5.2A3.4 3.4 0 0 1 15.6 17h-3.05L8 20.2V17H8.4A3.4 3.4 0 0 1 5 13.6z" />
    </template>
    <template v-else-if="name === 'about'">
      <circle
        cx="12"
        cy="12"
        r="8"
      />
      <path d="M12 11.2V16" />
      <path d="M12 8.15h.01" />
    </template>
    <template v-else-if="name === 'login'">
      <path d="M10 7H7.5A2.5 2.5 0 0 0 5 9.5v5A2.5 2.5 0 0 0 7.5 17H10" />
      <path d="M10 12h9" />
      <path d="M16 8.5 19.5 12 16 15.5" />
    </template>
    <template v-else-if="name === 'signup'">
      <circle
        cx="10"
        cy="8"
        r="3"
      />
      <path d="M4.5 19c0-2.6 2.2-4.5 5.5-4.5s5.5 1.9 5.5 4.5" />
      <path d="M18 8v6M15 11h6" />
    </template>
    <template v-else-if="name === 'logout'">
      <path d="M14 7h2.5A2.5 2.5 0 0 1 19 9.5v5A2.5 2.5 0 0 1 16.5 17H14" />
      <path d="M14 12H5" />
      <path d="M8 8.5 4.5 12 8 15.5" />
    </template>
    <template v-else-if="name === 'user'">
      <circle
        cx="12"
        cy="8.5"
        r="3.2"
      />
      <path d="M5.5 19.5c0-3.1 2.8-5.2 6.5-5.2s6.5 2.1 6.5 5.2" />
    </template>
    <template v-else>
      <circle
        cx="12"
        cy="12"
        r="8"
      />
      <path d="M4 12h16" />
      <path d="M12 4c2.5 2.8 3.8 5.5 3.8 8s-1.3 5.2-3.8 8c-2.5-2.8-3.8-5.5-3.8-8S9.5 6.8 12 4Z" />
    </template>
  </svg>
</template>
