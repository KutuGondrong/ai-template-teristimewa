<script setup lang="ts">
import { computed, ref } from "vue";
import { useI18n } from "vue-i18n";
import { chat, chatApi, user } from "../../application/session";
import ChatMessageList from "./ChatMessageList.vue";
import ChatComposer from "./ChatComposer.vue";

const { t } = useI18n();
const showGuestNotice = computed(
  () => Boolean(user.value && (user.value.guest || !user.value.email)),
);

const draft = ref("");
const loadingOlder = ref(false);

async function send() {
  const text = draft.value;
  draft.value = "";
  await chatApi.send(chat.value, text, (next) => {
    chat.value = next;
  });
}

async function retry() {
  await chatApi.retry(chat.value, (next) => {
    chat.value = next;
  });
}

async function loadOlder() {
  if (loadingOlder.value) return;
  loadingOlder.value = true;
  try {
    await chatApi.loadOlder(chat.value, (next) => {
      chat.value = next;
    });
  } finally {
    loadingOlder.value = false;
  }
}
</script>

<template>
  <section class="chat-shell">
    <p
      v-if="showGuestNotice"
      class="guest-notice"
      data-testid="guest-banner"
    >
      {{ t("auth.guestBanner") }}
    </p>
    <ChatMessageList
      :messages="chat.messages ?? []"
      :pending="Boolean(chat.pending)"
      :has-more="Boolean(chat.hasMore)"
      :loading-older="loadingOlder"
      @retry="retry"
      @load-older="loadOlder"
    />
    <ChatComposer
      v-model="draft"
      :pending="chat.pending"
      @send="send"
    />
  </section>
</template>
