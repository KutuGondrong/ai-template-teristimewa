import type { Message } from "../domain/types";
import { stripReasoning } from "../domain/parseReasoning";
import { streamChat } from "../infrastructure/stream";
import { createHistoryApi, type HistoryPage } from "../infrastructure/rest";
import type { AxiosInstance } from "axios";

export type ChatState = {
  messages: Message[];
  pending: boolean;
  lastUserMessage: string | null;
  hasMore: boolean;
};

export function emptyChat(): ChatState {
  return { messages: [], pending: false, lastUserMessage: null, hasMore: false };
}

let seq = 0;
function id() {
  seq += 1;
  return `m-${Date.now()}-${seq}`;
}

export function createChatUseCase(http: AxiosInstance, apiUrl: string) {
  const history = createHistoryApi(http);

  return {
    async loadHistory(before?: string): Promise<HistoryPage> {
      return history.load(10, before);
    },

    async resetToHistory(onChange: (next: ChatState) => void): Promise<void> {
      onChange(emptyChat());
      try {
        const page = await history.load(10);
        onChange({
          messages: page.items,
          pending: false,
          lastUserMessage: null,
          hasMore: page.hasMore,
        });
      } catch {
        onChange(emptyChat());
      }
    },

    async loadOlder(state: ChatState, onChange: (next: ChatState) => void): Promise<void> {
      if (!state.hasMore || state.pending || !state.messages.length) return;
      const before = state.messages[0]?.id;
      if (!before) return;
      try {
        const page = await history.load(10, before);
        const seen = new Set(state.messages.map((m) => m.id));
        const older = page.items.filter((m) => !seen.has(m.id));
        onChange({
          ...state,
          messages: [...older, ...state.messages],
          hasMore: page.hasMore,
        });
      } catch {
        onChange({ ...state, hasMore: false });
      }
    },

    async send(
      state: ChatState,
      text: string,
      onChange: (next: ChatState) => void,
    ): Promise<void> {
      const content = text.trim();
      if (!content || state.pending) return;

      const userMsg: Message = {
        id: id(),
        role: "user",
        content,
        createdAt: new Date().toISOString(),
      };
      const assistantId = id();
      const assistant: Message = {
        id: assistantId,
        role: "assistant",
        content: "",
        createdAt: new Date().toISOString(),
      };

      let next: ChatState = {
        messages: [...state.messages, userMsg, assistant],
        pending: true,
        lastUserMessage: content,
        hasMore: state.hasMore,
      };
      onChange(next);

      try {
        await streamChat(apiUrl, content, {
          onToken: (chunk) => {
            next = {
              ...next,
              messages: next.messages.map((m) =>
                m.id === assistantId ? { ...m, content: m.content + chunk } : m,
              ),
            };
            onChange(next);
          },
        });
        next = {
          ...next,
          messages: next.messages.map((m) =>
            m.id === assistantId ? { ...m, content: stripReasoning(m.content) } : m,
          ),
        };
        onChange({ ...next, pending: false });
      } catch {
        const err: Message = {
          id: id(),
          role: "error",
          content: "stream_error",
          createdAt: new Date().toISOString(),
          failed: true,
        };
        onChange({
          messages: next.messages.filter((m) => m.id !== assistantId).concat(err),
          pending: false,
          lastUserMessage: content,
          hasMore: state.hasMore,
        });
      }
    },

    async retry(state: ChatState, onChange: (next: ChatState) => void): Promise<void> {
      if (!state.lastUserMessage || state.pending) return;
      const cleaned = state.messages.filter((m) => m.role !== "error");
      await this.send({ ...state, messages: cleaned }, state.lastUserMessage, onChange);
    },
  };
}
