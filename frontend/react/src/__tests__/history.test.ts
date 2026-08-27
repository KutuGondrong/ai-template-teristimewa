import { describe, expect, it } from "vitest";
import { mapHistoryMessage } from "../shared/infrastructure/rest";

describe("mapHistoryMessage", () => {
  it("maps snake_case backend payload to chat message", () => {
    expect(
      mapHistoryMessage({
        id: "abc",
        role: "user",
        content: "halo",
        created_at: "2026-01-01T00:00:00Z",
      }),
    ).toEqual({
      id: "abc",
      role: "user",
      content: "halo",
      createdAt: "2026-01-01T00:00:00Z",
    });
  });

  it("keeps assistant role so history bubbles render", () => {
    expect(mapHistoryMessage({ id: "2", role: "assistant", content: "hi" }).role).toBe("assistant");
  });
});
