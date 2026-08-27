<script setup lang="ts">
import type { Message } from "@/shared";
import AppIcon from "./AppIcon.vue";
import AppLogo from "./AppLogo.vue";
import ChatAssistantResponse from "./ChatAssistantResponse.vue";

defineProps<{ message: Message; streaming?: boolean }>();
</script>

<template>
  <div
    v-if="message"
    :data-testid="message.role === 'error' ? 'chat-error' : `chat-msg-${message.role}`"
  >
    <div
      v-if="message.role === 'user'"
      class="chat-row chat-row-user"
    >
      <p class="chat-bubble chat-bubble-user">
        {{ message.content }}
      </p>
      <span class="chat-avatar">
        <AppIcon name="user" />
      </span>
    </div>
    <div
      v-else-if="message.role === 'assistant'"
      class="chat-row chat-row-ai"
    >
      <AppLogo size="sm" />
      <div class="chat-bubble chat-bubble-ai chat-prose">
        <ChatAssistantResponse
          :content="message.content"
          :streaming="streaming"
        />
      </div>
    </div>
    <slot v-else />
  </div>
</template>
