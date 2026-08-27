<script setup lang="ts">
import type { Message } from "~/shared";

const props = withDefaults(
  defineProps<{
    messages?: Message[];
    pending?: boolean;
    hasMore?: boolean;
    loadingOlder?: boolean;
  }>(),
  {
    messages: () => [],
    pending: false,
    hasMore: false,
    loadingOlder: false,
  },
);
const emit = defineEmits<{ retry: []; loadOlder: [] }>();
const { t } = useI18n();
const slow = ref(false);
const listEl = ref<HTMLElement | null>(null);
const skipStick = ref(false);
const prevHeight = ref(0);
let timer: ReturnType<typeof setTimeout> | undefined;

function listOf(value: unknown): Message[] {
  return Array.isArray(value) ? value : [];
}

const items = computed(() => listOf(props.messages));
const lastAssistant = computed(() => {
  const list = listOf(items.value);
  for (let i = list.length - 1; i >= 0; i--) {
    if (list[i]?.role === "assistant") return list[i];
  }
  return undefined;
});
/** Global fallback only before the assistant bubble exists; bubble handles thinking UI. */
const waiting = computed(() => props.pending && !lastAssistant.value);

const stopPending = watch(
  () => props.pending,
  (pending) => {
    if (timer) clearTimeout(timer);
    slow.value = false;
    if (pending) {
      timer = setTimeout(() => {
        slow.value = true;
      }, 8000);
    }
  },
  { immediate: true },
);

const stopScroll = watch(
  () => [listOf(items.value).length, props.pending, lastAssistant.value?.content] as const,
  async () => {
    await nextTick();
    const el = listEl.value;
    if (!el) return;
    if (skipStick.value) {
      el.scrollTop = el.scrollHeight - prevHeight.value;
      skipStick.value = false;
      return;
    }
    el.scrollTo?.({ top: el.scrollHeight, behavior: "smooth" });
  },
);

function loadOlder() {
  prevHeight.value = listEl.value?.scrollHeight ?? 0;
  skipStick.value = true;
  emit("loadOlder");
}

onBeforeUnmount(() => {
  stopPending();
  stopScroll();
  if (timer) clearTimeout(timer);
});
</script>

<template>
  <div
    ref="listEl"
    class="chat-list"
    data-testid="chat-list"
  >
    <button
      v-if="hasMore && items.length"
      type="button"
      class="btn btn-ghost chat-load-more"
      data-testid="chat-load-more"
      :disabled="loadingOlder || pending"
      @click="loadOlder"
    >
      {{ t("chat.loadMore") }}
    </button>
    <div
      v-if="!items.length"
      class="chat-empty"
    >
      <AppLogo size="lg" />
      <span>{{ t("chat.empty") }}</span>
    </div>
    <ChatBubble
      v-for="m in items"
      :key="m.id"
      :message="m"
      :streaming="pending && m.id === lastAssistant?.id"
    >
      <div class="flex flex-wrap items-center gap-3 text-sm text-destructive">
        <span>{{ t("chat.error") }}</span>
        <button
          type="button"
          class="chat-retry"
          data-testid="chat-retry"
          @click="emit('retry')"
        >
          {{ t("chat.retry") }}
        </button>
      </div>
    </ChatBubble>
    <div
      v-if="waiting"
      class="chat-thinking"
      data-testid="chat-thinking"
    >
      <span
        class="chat-thinking-dots"
        aria-hidden="true"
      >
        <span /><span /><span />
      </span>
      <span data-testid="chat-pending">{{ slow ? t("chat.slow") : t("chat.thinking") }}</span>
    </div>
    <p
      v-else-if="pending && slow"
      class="text-xs text-muted-foreground"
      data-testid="chat-slow"
    >
      {{ t("chat.slow") }}
    </p>
  </div>
</template>
