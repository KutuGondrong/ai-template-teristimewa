import type { ReactNode } from "react";
import type { Message } from "@/shared";
import { AppIcon } from "./AppIcon";
import { AppLogo } from "./AppLogo";
import { ChatAssistantResponse } from "./ChatAssistantResponse";

export function ChatBubble({
  message,
  streaming,
  children,
}: {
  message: Message;
  streaming?: boolean;
  children?: ReactNode;
}) {
  return (
    <div data-testid={message.role === "error" ? "chat-error" : `chat-msg-${message.role}`}>
      {message.role === "user" ? (
        <div className="chat-row chat-row-user">
          <p className="chat-bubble chat-bubble-user">{message.content}</p>
          <span className="chat-avatar">
            <AppIcon name="user" />
          </span>
        </div>
      ) : null}
      {message.role === "assistant" ? (
        <div className="chat-row chat-row-ai">
          <AppLogo size="sm" />
          <div className="chat-bubble chat-bubble-ai chat-prose">
            <ChatAssistantResponse content={message.content} streaming={streaming} />
          </div>
        </div>
      ) : null}
      {message.role === "error" ? children : null}
    </div>
  );
}
