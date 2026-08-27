<script setup lang="ts">
import { computed } from "vue";
import { useI18n } from "vue-i18n";
import { parseAssistantContent } from "@/shared/domain/parseReasoning";

const props = defineProps<{ content: string; streaming?: boolean }>();
const { t } = useI18n();

const parsed = computed(() => parseAssistantContent(props.content));
const thinkingText = computed(() => parsed.value.thinking.trim());
const responseText = computed(() => parsed.value.response);
const showResponse = computed(() => Boolean(responseText.value.trim()));
const showThinkingIndicator = computed(
  () => props.streaming && !showResponse.value && parsed.value.phase !== "responding",
);
const showThinkingText = computed(
  () => showThinkingIndicator.value && Boolean(thinkingText.value),
);
</script>

<template>
  <div
    class="chat-assistant-response"
    data-testid="chat-assistant-response"
  >
    <div
      v-if="showThinkingIndicator"
      class="chat-reasoning"
      data-testid="chat-reasoning"
    >
      <div class="chat-reasoning-head">
        <span
          class="chat-thinking-dots"
          aria-hidden="true"
        >
          <span /><span /><span />
        </span>
        <span data-testid="chat-reasoning-label">{{ t("chat.thinking") }}</span>
      </div>
      <div
        v-if="showThinkingText"
        class="chat-reasoning-text"
        data-testid="chat-reasoning-text"
      >
        {{ thinkingText }}
      </div>
    </div>
    <div
      v-if="showResponse"
      class="chat-response-text"
      data-testid="chat-response-text"
    >
      {{ responseText }}<span
        v-if="streaming"
        class="chat-cursor"
        aria-hidden="true"
      />
    </div>
  </div>
</template>
