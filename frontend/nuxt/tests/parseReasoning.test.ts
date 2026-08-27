import { describe, expect, it } from "vitest";
import { parseAssistantContent, stripReasoning } from "~/shared/domain/parseReasoning";

const thinkOpen = "<" + "think" + ">";
const thinkClose = "</" + "think" + ">";

describe("parseAssistantContent", () => {
  it("returns idle for empty content", () => {
    expect(parseAssistantContent("")).toEqual({
      phase: "idle",
      thinking: "",
      response: "",
    });
  });

  it("treats plain text as response", () => {
    expect(parseAssistantContent("Halo!")).toEqual({
      phase: "responding",
      thinking: "",
      response: "Halo!",
    });
  });

  it("detects in-progress reasoning stream", () => {
    expect(parseAssistantContent(`${thinkOpen}Let me check`)).toEqual({
      phase: "thinking",
      thinking: "Let me check",
      response: "",
    });
  });

  it("detects closed reasoning without answer yet", () => {
    expect(parseAssistantContent(`${thinkOpen}done${thinkClose}`)).toEqual({
      phase: "thinking",
      thinking: "done",
      response: "",
    });
  });

  it("splits reasoning from final answer", () => {
    expect(
      parseAssistantContent(`${thinkOpen}hidden${thinkClose}Jawaban ini`),
    ).toEqual({
      phase: "responding",
      thinking: "hidden",
      response: "Jawaban ini",
    });
  });

  it("supports redacted_thinking tags", () => {
    expect(
      parseAssistantContent("<think>plan</think>Hi"),
    ).toEqual({
      phase: "responding",
      thinking: "plan",
      response: "Hi",
    });
  });

  it("buffers partial reasoning tags during stream", () => {
    expect(parseAssistantContent("<redacted_thin")).toEqual({
      phase: "thinking",
      thinking: "",
      response: "",
    });
  });

  it("strips leading whitespace after reasoning block", () => {
    expect(
      parseAssistantContent(`${thinkOpen}plan${thinkClose}\n\nJawaban`),
    ).toEqual({
      phase: "responding",
      thinking: "plan",
      response: "Jawaban",
    });
  });
});

describe("stripReasoning", () => {
  it("removes reasoning blocks from stored content", () => {
    expect(stripReasoning(`${thinkOpen}secret${thinkClose}Only this`)).toBe("Only this");
  });
});
