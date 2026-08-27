import { describe, expect, it, vi } from "vitest";
import { emptyChat, type ChatState, type User } from "@/src/shared";
import { applySignedIn, hydrateSession } from "@/src/application/session";

const { me, resetToHistory } = vi.hoisted(() => ({
  me: vi.fn(),
  resetToHistory: vi.fn(),
}));

vi.mock("@/src/shared", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/src/shared")>();
  return {
    ...actual,
    createAuthApi: () => ({
      me,
      login: vi.fn(),
      signup: vi.fn(),
      logout: vi.fn(async () => {}),
    }),
    createChatUseCase: () => ({
      resetToHistory,
      send: vi.fn(),
      retry: vi.fn(),
      loadHistory: vi.fn(),
      loadOlder: vi.fn(),
    }),
  };
});

const guest: User = { id: "g1", email: "", guest: true };
const member: User = { id: "u1", email: "a@b.com", guest: false };

describe("session epoch", () => {
  it("does not let a late guest hydrate wipe login history", async () => {
    let releaseMe!: (user: User | null) => void;
    me.mockImplementationOnce(
      () =>
        new Promise<User | null>((resolve) => {
          releaseMe = resolve;
        }),
    );
    resetToHistory.mockImplementation(async (onChange: (c: ChatState) => void) => {
      onChange({
        messages: [{ id: "1", role: "user", content: "saved", createdAt: "t" }],
        pending: false,
        lastUserMessage: null,
        hasMore: false,
      });
    });

    let user: User | null = null;
    let chat: ChatState = emptyChat();
    const hydrate = hydrateSession(
      (next) => {
        user = next;
      },
      (next) => {
        chat = next;
      },
    );

    await applySignedIn(
      member,
      (next) => {
        user = next;
      },
      (next) => {
        chat = next;
      },
    );
    expect(user?.email).toBe("a@b.com");
    expect(chat.messages.map((m) => m.content)).toContain("saved");

    releaseMe(guest);
    await hydrate;

    expect(user?.email).toBe("a@b.com");
    expect(chat.messages.map((m) => m.content)).toContain("saved");
  });
});
