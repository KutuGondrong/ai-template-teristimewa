export type ReasoningPhase = "idle" | "thinking" | "responding";

export type ParsedAssistant = {
  phase: ReasoningPhase;
  thinking: string;
  response: string;
};

const THINK = "think";
const THINK_OPEN_TAGS = [`<${THINK}>`, `<redacted_${THINK}ing>`];
const THINK_OPEN = new RegExp(
  `^[\\s\\n]*(?:<${THINK}>|<redacted_${THINK}ing>)`,
  "i",
);
const THINK_CLOSE = new RegExp(`(?:</${THINK}>|</redacted_${THINK}ing>)`, "i");

function isPartialThinkOpen(raw: string): boolean {
  const head = raw.replace(/^[\s\n]+/, "").toLowerCase();
  if (!head.startsWith("<")) return false;
  return THINK_OPEN_TAGS.some((tag) => tag.startsWith(head) && head.length < tag.length);
}

/** Split streamed assistant text into temporary reasoning vs visible answer. */
export function parseAssistantContent(raw: string): ParsedAssistant {
  if (!raw) {
    return { phase: "idle", thinking: "", response: "" };
  }

  if (isPartialThinkOpen(raw)) {
    return { phase: "thinking", thinking: "", response: "" };
  }

  const openMatch = raw.match(THINK_OPEN);
  if (!openMatch) {
    return { phase: "responding", thinking: "", response: raw };
  }

  const afterOpen = raw.slice(openMatch[0].length);
  const closeMatch = afterOpen.match(THINK_CLOSE);

  if (!closeMatch || closeMatch.index === undefined) {
    return { phase: "thinking", thinking: afterOpen, response: "" };
  }

  const thinking = afterOpen.slice(0, closeMatch.index);
  const response = afterOpen.slice(closeMatch.index + closeMatch[0].length);

  if (!response.trim()) {
    return { phase: "thinking", thinking, response: "" };
  }

  return { phase: "responding", thinking, response: response.replace(/^\s+/, "") };
}

/** Visible assistant text with reasoning blocks removed. */
export function stripReasoning(raw: string): string {
  return parseAssistantContent(raw).response.trim();
}
