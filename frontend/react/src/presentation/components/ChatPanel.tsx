import { useState } from "react";
import { useTranslation } from "react-i18next";
import type { ChatState } from "@/shared";
import { chatApi } from "../../application/session";
import { ChatComposer } from "./ChatComposer";
import { ChatMessageList } from "./ChatMessageList";

export function ChatPanel({
  chat,
  setChat,
  isGuest,
}: {
  chat: ChatState;
  setChat: (c: ChatState) => void;
  isGuest: boolean;
}) {
  const { t } = useTranslation();
  const [draft, setDraft] = useState("");
  const [loadingOlder, setLoadingOlder] = useState(false);

  async function send() {
    const text = draft;
    setDraft("");
    await chatApi.send(chat, text, setChat);
  }

  async function loadOlder() {
    if (loadingOlder) return;
    setLoadingOlder(true);
    try {
      await chatApi.loadOlder(chat, setChat);
    } finally {
      setLoadingOlder(false);
    }
  }

  return (
    <section className="chat-shell">
      {isGuest ? (
        <p className="guest-notice" data-testid="guest-banner">
          {t("auth.guestBanner")}
        </p>
      ) : null}
      <ChatMessageList
        messages={chat.messages}
        pending={chat.pending}
        hasMore={chat.hasMore}
        loadingOlder={loadingOlder}
        onRetry={() => void chatApi.retry(chat, setChat)}
        onLoadOlder={() => void loadOlder()}
      />
      <ChatComposer draft={draft} pending={chat.pending} onDraft={setDraft} onSend={() => void send()} />
    </section>
  );
}
