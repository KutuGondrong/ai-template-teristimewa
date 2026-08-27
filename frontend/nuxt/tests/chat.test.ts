import { describe, expect, it, vi } from "vitest";
import { createChatUseCase, createHttp, type ChatState } from "~/shared";

describe("chat use case", () => {
  it("marks pending while streaming and surfaces retry state on failure", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: false,
        status: 500,
        body: null,
      })),
    );

    const http = createHttp("http://localhost:8000");
    const api = createChatUseCase(http, "http://localhost:8000");
    let state: ChatState = { messages: [], pending: false, lastUserMessage: null, hasMore: false };
    await api.send(state, "halo", (next) => {
      state = next;
    });
    expect(state.pending).toBe(false);
    expect(state.messages.some((m) => m.role === "error")).toBe(true);
    expect(state.lastUserMessage).toBe("halo");
  });

  it("turns an in-stream error into retry state", async () => {
    const payload = 'data: {"error":"ollama_down"}\n\n';
    const encoder = new TextEncoder();
    vi.stubGlobal(
      "fetch",
      vi.fn(async () => ({
        ok: true,
        status: 200,
        body: {
          getReader() {
            let sent = false;
            return {
              async read() {
                if (sent) return { done: true, value: undefined };
                sent = true;
                return { done: false, value: encoder.encode(payload) };
              },
            };
          },
        },
      })),
    );

    const http = createHttp("http://localhost:8000");
    const api = createChatUseCase(http, "http://localhost:8000");
    let state: ChatState = { messages: [], pending: false, lastUserMessage: null, hasMore: false };
    await api.send(state, "halo", (next) => {
      state = next;
    });
    expect(state.pending).toBe(false);
    expect(state.messages.some((m) => m.role === "error")).toBe(true);
  });
});
