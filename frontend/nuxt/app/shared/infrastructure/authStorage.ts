import type { User } from "../domain/types";

const KEY = "ai.session.user";

function parseUser(raw: string): User | null {
  try {
    const data = JSON.parse(raw) as { id?: unknown; email?: unknown; guest?: unknown };
    if (typeof data?.id !== "string" && typeof data?.id !== "number") return null;
    const email = typeof data.email === "string" ? data.email : "";
    const guest = data.guest === true || !email;
    return { id: String(data.id), email, guest };
  } catch {
    return null;
  }
}

export function readStoredUser(): User | null {
  if (typeof window === "undefined") return null;
  try {
    const raw = localStorage.getItem(KEY);
    return raw ? parseUser(raw) : null;
  } catch {
    return null;
  }
}

export function writeStoredUser(user: User | null): void {
  if (typeof window === "undefined") return;
  try {
    if (!user || user.guest || !user.email) {
      localStorage.removeItem(KEY);
      return;
    }
    localStorage.setItem(KEY, JSON.stringify({ id: user.id, email: user.email, guest: false }));
  } catch {
    /* private mode */
  }
}
