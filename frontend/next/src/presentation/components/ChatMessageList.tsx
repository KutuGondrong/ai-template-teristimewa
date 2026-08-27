"use client";

import { useEffect, useRef, useState } from "react";
import { useTranslation } from "react-i18next";
import type { Message } from "@/src/shared";
import { ChatBubble } from "./ChatBubble";
import { AppLogo } from "./AppLogo";

const SLOW_MS = 8000;

export function ChatMessageList({
  messages,
  pending,
  hasMore = false,
  loadingOlder = false,
  onRetry,
  onLoadOlder,
}: {
  messages: Message[];
  pending: boolean;
  hasMore?: boolean;
  loadingOlder?: boolean;
  onRetry: () => void;
  onLoadOlder?: () => void;
}) {
  const { t } = useTranslation();
  const [slow, setSlow] = useState(false);
  const listRef = useRef<HTMLDivElement>(null);
  const prependRef = useRef(false);
  const heightRef = useRef(0);
  const items = Array.isArray(messages) ? messages : [];
  const lastAssistant = [...items].reverse().find((m) => m.role === "assistant");
  const waiting = pending && !lastAssistant;

  useEffect(() => {
    if (!pending) {
      setSlow(false);
      return;
    }
    const timer = window.setTimeout(() => setSlow(true), SLOW_MS);
    return () => window.clearTimeout(timer);
  }, [pending]);

  useEffect(() => {
    const el = listRef.current;
    if (!el) return;
    if (prependRef.current) {
      el.scrollTop = el.scrollHeight - heightRef.current;
      prependRef.current = false;
      return;
    }
    el.scrollTo?.({ top: el.scrollHeight, behavior: "smooth" });
  }, [items.length, pending, lastAssistant?.content]);

  function loadOlder() {
    const el = listRef.current;
    heightRef.current = el?.scrollHeight ?? 0;
    prependRef.current = true;
    onLoadOlder?.();
  }

  return (
    <div ref={listRef} className="chat-list" data-testid="chat-list">
      {hasMore && items.length ? (
        <button
          type="button"
          className="btn btn-ghost chat-load-more"
          data-testid="chat-load-more"
          disabled={loadingOlder || pending}
          onClick={loadOlder}
        >
          {t("chat.loadMore")}
        </button>
      ) : null}
      {!items.length ? (
        <div className="chat-empty">
          <AppLogo size="lg" />
          <span>{t("chat.empty")}</span>
        </div>
      ) : null}
      {items.map((m) => (
        <ChatBubble key={m.id} message={m} streaming={pending && m.id === lastAssistant?.id}>
          <div className="flex flex-wrap items-center gap-3 text-sm text-destructive">
            <span>{t("chat.error")}</span>
            <button type="button" data-testid="chat-retry" className="chat-retry" onClick={onRetry}>
              {t("chat.retry")}
            </button>
          </div>
        </ChatBubble>
      ))}
      {waiting ? (
        <div className="chat-thinking" data-testid="chat-thinking">
          <span className="chat-thinking-dots" aria-hidden="true">
            <span />
            <span />
            <span />
          </span>
          <span data-testid="chat-pending">{slow ? t("chat.slow") : t("chat.thinking")}</span>
        </div>
      ) : null}
      {pending && !waiting && slow ? (
        <p className="text-xs text-muted-foreground" data-testid="chat-slow">
          {t("chat.slow")}
        </p>
      ) : null}
    </div>
  );
}
