import type { AxiosInstance } from "axios";
import type { Message, Role, User } from "../domain/types";

type AuthPayload = { id: string; email?: string; guest?: boolean; type?: string };

function toUser(data: AuthPayload): User {
  const guest = data.guest === true || data.type === "guest" || !data.email;
  return { id: String(data.id), email: data.email ?? "", guest };
}

export function createAuthApi(http: AxiosInstance) {
  return {
    async me(): Promise<User | null> {
      try {
        const { data } = await http.get<AuthPayload>("/api/auth/me");
        return toUser(data);
      } catch {
        return null;
      }
    },
    async login(email: string, password: string): Promise<User> {
      const { data } = await http.post<AuthPayload>("/api/auth/login", { email, password });
      return toUser(data);
    },
    async signup(email: string, password: string): Promise<User> {
      const { data } = await http.post<AuthPayload>("/api/auth/signup", { email, password });
      return toUser(data);
    },
    async logout(): Promise<void> {
      await http.post("/api/auth/logout");
    },
  };
}

type MessagePayload = {
  id?: unknown;
  role?: unknown;
  content?: unknown;
  createdAt?: unknown;
  created_at?: unknown;
};

type MessagesPayload = MessagePayload[] | { items?: MessagePayload[]; has_more?: boolean; hasMore?: boolean };

export type HistoryPage = {
  items: Message[];
  hasMore: boolean;
};

function asRole(value: unknown): Role {
  return value === "user" || value === "assistant" || value === "system" || value === "error"
    ? value
    : "assistant";
}

export function mapHistoryMessage(raw: MessagePayload): Message {
  return {
    id: String(raw.id ?? ""),
    role: asRole(raw.role),
    content: String(raw.content ?? ""),
    createdAt: String(raw.createdAt ?? raw.created_at ?? ""),
  };
}

function messagesFrom(data: MessagesPayload): HistoryPage {
  if (Array.isArray(data)) {
    return { items: data.map(mapHistoryMessage), hasMore: false };
  }
  const items = Array.isArray(data?.items) ? data.items.map(mapHistoryMessage) : [];
  return { items, hasMore: data?.has_more === true || data?.hasMore === true };
}

export function createHistoryApi(http: AxiosInstance) {
  return {
    async load(limit = 10, before?: string): Promise<HistoryPage> {
      const { data } = await http.get<MessagesPayload>("/api/messages", {
        params: before ? { limit, before } : { limit },
      });
      return messagesFrom(data);
    },
  };
}
