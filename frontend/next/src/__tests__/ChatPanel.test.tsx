import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { ChatPanel } from "../presentation/components/ChatPanel";
import { SessionProvider } from "../presentation/components/SessionProvider";
import "../i18n";

vi.mock("../application/session", async () => {
  const actual = await vi.importActual<typeof import("../application/session")>("../application/session");
  return {
    ...actual,
    chatApi: {
      send: vi.fn(),
      retry: vi.fn(),
      loadHistory: vi.fn(async () => ({ items: [], hasMore: false })),
      resetToHistory: vi.fn(),
      loadOlder: vi.fn(),
    },
  };
});

describe("ChatPanel", () => {
  it("enables send after typing", async () => {
    const user = userEvent.setup();
    render(
      <SessionProvider>
        <ChatPanel />
      </SessionProvider>,
    );
    const send = screen.getByTestId("chat-send");
    expect(send).toBeDisabled();
    await user.type(screen.getByTestId("chat-input"), "halo");
    expect(send).toBeEnabled();
  });
});
