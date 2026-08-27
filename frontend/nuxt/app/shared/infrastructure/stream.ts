export type StreamHandlers = {
  onToken: (chunk: string) => void;
  onDone?: () => void;
};

type StreamPayload = {
  token?: string;
  content?: string;
  error?: string;
  done?: boolean;
};

export async function streamChat(
  apiUrl: string,
  message: string,
  handlers: StreamHandlers,
): Promise<void> {
  const res = await fetch(`${apiUrl}/api/chat`, {
    method: "POST",
    credentials: "include",
    headers: { "Content-Type": "application/json", Accept: "text/event-stream" },
    body: JSON.stringify({ message }),
  });

  if (!res.ok || !res.body) {
    throw new Error(`chat_failed_${res.status}`);
  }

  const reader = res.body.getReader();
  const decoder = new TextDecoder();
  let buffer = "";

  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    buffer += decoder.decode(value, { stream: true });
    const parts = buffer.split("\n");
    buffer = parts.pop() ?? "";
    for (const line of parts) {
      const trimmed = line.trim();
      if (!trimmed || trimmed.startsWith(":")) continue;
      if (trimmed.startsWith("data:")) {
        const payload = trimmed.slice(5).trim();
        if (payload === "[DONE]") {
          handlers.onDone?.();
          return;
        }
        try {
          const json = JSON.parse(payload) as StreamPayload;
          if (json.error) {
            throw new Error(json.error);
          }
          if (json.done) {
            handlers.onDone?.();
            return;
          }
          const chunk = json.token ?? json.content ?? "";
          if (chunk) handlers.onToken(chunk);
        } catch (err) {
          if (err instanceof SyntaxError) {
            handlers.onToken(payload);
            continue;
          }
          throw err;
        }
      } else {
        handlers.onToken(trimmed);
      }
    }
  }
  handlers.onDone?.();
}
