"use client";

import { useState } from "react";
import { useTranslation } from "react-i18next";
import { chatApi } from "@/src/application/session";
import { useSession } from "./SessionProvider";
import { ChatComposer } from "./ChatComposer";
import { ChatMessageList } from "./ChatMessageList";

export function ChatPanel() {
  const { t } = useTranslation();
  const { chat, setChat, user } = useSession();
  const [draft, setDraft] = useState("");
  const [loadingOlder, setLoadingOlder] = useState(false);
  const showGuestNotice = Boolean(user && (user.guest || !user.email));

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
      {showGuestNotice ? (
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
