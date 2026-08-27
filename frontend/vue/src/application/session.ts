import { ref } from "vue";
import {
  createAuthApi,
  createChatUseCase,
  createHttp,
  emptyChat,
  readStoredUser,
  writeStoredUser,
  type ChatState,
  type User,
} from "@/shared";

const apiUrl = import.meta.env.VITE_API_URL ?? "http://127.0.0.1:8000";
const http = createHttp(apiUrl);
export const authApi = createAuthApi(http);
export const chatApi = createChatUseCase(http, apiUrl);

export const user = ref<User | null>(null);
export const chat = ref<ChatState>(emptyChat());

let boot = 0;

function setChat(next: ChatState) {
  chat.value = next;
}

function ifCurrent(token: number) {
  return (next: ChatState) => {
    if (token !== boot) return;
    setChat(next);
  };
}

export async function bootstrapSession() {
  const token = ++boot;
  const stored = readStoredUser();
  if (stored) user.value = stored;
  const me = await authApi.me();
  if (token !== boot) return;
  user.value = me;
  writeStoredUser(me);
  await chatApi.resetToHistory(ifCurrent(token));
}

export async function applySignedIn(next: User) {
  const token = ++boot;
  writeStoredUser(next);
  user.value = next;
  setChat(emptyChat());
  await chatApi.resetToHistory(ifCurrent(token));
}

export async function applySignedOut() {
  const token = ++boot;
  await authApi.logout();
  writeStoredUser(null);
  if (token !== boot) return;
  user.value = await authApi.me();
  setChat(emptyChat());
  await chatApi.resetToHistory(ifCurrent(token));
}
