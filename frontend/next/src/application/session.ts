import {
  createAuthApi,
  createChatUseCase,
  createHttp,
  emptyChat,
  readStoredUser,
  writeStoredUser,
  type ChatState,
  type User,
} from "@/src/shared";

const apiUrl = process.env.NEXT_PUBLIC_API_URL ?? "http://127.0.0.1:8000";
const http = createHttp(apiUrl);

export const authApi = createAuthApi(http);
export const chatApi = createChatUseCase(http, apiUrl);

export const initialChat: ChatState = emptyChat();

type SetUser = (user: User | null) => void;
type SetChat = (chat: ChatState) => void;

let boot = 0;

function ifCurrent(token: number, setChat: SetChat): SetChat {
  return (next) => {
    if (token !== boot) return;
    setChat(next);
  };
}

export async function hydrateSession(setUser: SetUser, setChat: SetChat): Promise<void> {
  const token = ++boot;
  const stored = readStoredUser();
  if (stored) setUser(stored);
  const me = await authApi.me();
  if (token !== boot) return;
  setUser(me);
  writeStoredUser(me);
  await chatApi.resetToHistory(ifCurrent(token, setChat));
}

export async function applySignedIn(user: User, setUser: SetUser, setChat: SetChat): Promise<void> {
  const token = ++boot;
  writeStoredUser(user);
  setUser(user);
  setChat(emptyChat());
  await chatApi.resetToHistory(ifCurrent(token, setChat));
}

export async function applySignedOut(setUser: SetUser, setChat: SetChat): Promise<void> {
  const token = ++boot;
  await authApi.logout();
  writeStoredUser(null);
  if (token !== boot) return;
  setUser(await authApi.me());
  setChat(emptyChat());
  await chatApi.resetToHistory(ifCurrent(token, setChat));
}
