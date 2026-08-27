"use client";

import { useMemo } from "react";
import { useTranslation } from "react-i18next";
import { parseAssistantContent } from "@/src/shared/domain/parseReasoning";

export function ChatAssistantResponse({
  content,
  streaming,
}: {
  content: string;
  streaming?: boolean;
}) {
  const { t } = useTranslation();
  const parsed = useMemo(() => parseAssistantContent(content), [content]);
  const thinkingText = parsed.thinking.trim();
  const responseText = parsed.response;
  const showResponse = Boolean(responseText.trim());
  const showThinkingIndicator =
    Boolean(streaming) && !showResponse && parsed.phase !== "responding";
  const showThinkingText = showThinkingIndicator && Boolean(thinkingText);

  return (
    <div className="chat-assistant-response" data-testid="chat-assistant-response">
      {showThinkingIndicator ? (
        <div className="chat-reasoning" data-testid="chat-reasoning">
          <div className="chat-reasoning-head">
            <span className="chat-thinking-dots" aria-hidden="true">
              <span />
              <span />
              <span />
            </span>
            <span data-testid="chat-reasoning-label">{t("chat.thinking")}</span>
          </div>
          {showThinkingText ? (
            <div className="chat-reasoning-text" data-testid="chat-reasoning-text">
              {thinkingText}
            </div>
          ) : null}
        </div>
      ) : null}
      {showResponse ? (
        <div className="chat-response-text" data-testid="chat-response-text">
          {responseText}
          {streaming ? <span className="chat-cursor" aria-hidden="true" /> : null}
        </div>
      ) : null}
    </div>
  );
}
