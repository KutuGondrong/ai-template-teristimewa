import { describe, expect, it } from "vitest";
import { parseAssistantContent, stripReasoning } from "@/src/shared/domain/parseReasoning";

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

  it("splits reasoning from final answer", () => {
    expect(
      parseAssistantContent(`${thinkOpen}hidden${thinkClose}Jawaban ini`),
    ).toEqual({
      phase: "responding",
      thinking: "hidden",
      response: "Jawaban ini",
    });
  });
});

describe("stripReasoning", () => {
  it("removes reasoning blocks from stored content", () => {
    expect(stripReasoning(`${thinkOpen}secret${thinkClose}Only this`)).toBe("Only this");
  });
});
