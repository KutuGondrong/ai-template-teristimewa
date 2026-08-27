import type { ChatState } from "@/shared";
import { ChatPanel } from "../components/ChatPanel";

export function ChatPage({
  chat,
  setChat,
  isGuest,
}: {
  chat: ChatState;
  setChat: (c: ChatState) => void;
  isGuest: boolean;
}) {
  return <ChatPanel chat={chat} setChat={setChat} isGuest={isGuest} />;
}
