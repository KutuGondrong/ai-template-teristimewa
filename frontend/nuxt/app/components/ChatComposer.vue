<script setup lang="ts">
const draft = defineModel<string>({ default: "" });
defineProps<{ pending: boolean }>();
const emit = defineEmits<{ send: [] }>();
const { t } = useI18n();
</script>

<template>
  <form
    class="composer"
    @submit.prevent="emit('send')"
  >
    <input
      v-model="draft"
      type="text"
      class="composer-input"
      :placeholder="t('chat.placeholder')"
      :disabled="pending"
      data-testid="chat-input"
    >
    <button
      type="submit"
      class="composer-send"
      :disabled="pending || !draft.trim()"
      data-testid="chat-send"
      :aria-label="t('chat.send')"
    >
      <svg
        viewBox="0 0 24 24"
        class="h-4 w-4"
        fill="currentColor"
      >
        <path d="M12 4 5.5 10.5h4.25V20h4.5v-9.5H18.5Z" />
      </svg>
    </button>
  </form>
</template>
