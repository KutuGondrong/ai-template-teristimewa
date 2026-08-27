import { describe, expect, it } from "vitest";
import { parseAssistantContent, stripReasoning } from "@/shared/domain/parseReasoning";

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

  it("splits reasoning from final answer", () => {
    expect(
      parseAssistantContent(`${thinkOpen}hidden${thinkClose}Jawaban ini`),
    ).toEqual({
      phase: "responding",
      thinking: "hidden",
      response: "Jawaban ini",
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
