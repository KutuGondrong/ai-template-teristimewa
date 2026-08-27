import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import "../i18n";
import { ChatPanel } from "../presentation/components/ChatPanel";
import { initialChat } from "../application/session";

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
  it("keeps send disabled until input has text", async () => {
    const user = userEvent.setup();
    render(<ChatPanel chat={initialChat} setChat={() => undefined} isGuest />);
    const send = screen.getByTestId("chat-send");
    expect(send).toBeDisabled();
    await user.type(screen.getByTestId("chat-input"), "halo");
    expect(send).toBeEnabled();
  });
});
