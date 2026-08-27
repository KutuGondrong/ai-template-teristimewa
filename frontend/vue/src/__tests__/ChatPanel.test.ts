import { describe, expect, it, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/vue";
import { createI18n } from "vue-i18n";
import ChatPanel from "../presentation/components/ChatPanel.vue";
import id from "../i18n/locales/id.json";
import { chat } from "../application/session";

vi.mock("../application/session", async () => {
  const actual = await vi.importActual<typeof import("../application/session")>(
    "../application/session",
  );
  return {
    ...actual,
    chatApi: {
      send: vi.fn(async (_s, text, onChange) => {
        onChange({
          messages: [
            {
              id: "1",
              role: "user",
              content: text,
              createdAt: new Date().toISOString(),
            },
          ],
          pending: false,
          lastUserMessage: text,
          hasMore: false,
        });
      }),
      retry: vi.fn(),
      loadHistory: vi.fn(async () => ({ items: [], hasMore: false })),
      resetToHistory: vi.fn(),
      loadOlder: vi.fn(),
    },
  };
});

function renderPanel() {
  chat.value = { messages: [], pending: false, lastUserMessage: null, hasMore: false };
  const i18n = createI18n({ legacy: false, locale: "id", messages: { id } });
  return render(ChatPanel, { global: { plugins: [i18n] } });
}

describe("ChatPanel", () => {
  it("disables send while pending and accepts input", async () => {
    renderPanel();
    const input = screen.getByTestId("chat-input") as HTMLInputElement;
    const send = screen.getByTestId("chat-send") as HTMLButtonElement;
    expect(send.disabled).toBe(true);
    await fireEvent.update(input, "halo");
    expect(send.disabled).toBe(false);
  });
});
