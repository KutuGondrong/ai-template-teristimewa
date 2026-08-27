import {
  createAuthApi,
  createChatUseCase,
  createHttp,
  emptyChat,
  readStoredUser,
  writeStoredUser,
  type ChatState,
  type User,
} from "~/shared";

let boot = 0;

export function useSession() {
  const config = useRuntimeConfig();
  const apiUrl = config.public.apiUrl as string;
  const http = createHttp(apiUrl);
  const authApi = createAuthApi(http);
  const chatApi = createChatUseCase(http, apiUrl);

  const user = useState<User | null>("user", () => null);
  const chat = useState<ChatState>("chat", () => emptyChat());

  function ifCurrent(token: number) {
    return (next: ChatState) => {
      if (token !== boot) return;
      chat.value = next;
    };
  }

  async function bootstrap() {
    const token = ++boot;
    const stored = readStoredUser();
    if (stored) user.value = stored;
    const me = await authApi.me();
    if (token !== boot) return;
    user.value = me;
    writeStoredUser(me);
    await chatApi.resetToHistory(ifCurrent(token));
  }

  async function applySignedIn(next: User) {
    const token = ++boot;
    writeStoredUser(next);
    user.value = next;
    chat.value = emptyChat();
    await chatApi.resetToHistory(ifCurrent(token));
  }

  async function applySignedOut() {
    const token = ++boot;
    await authApi.logout();
    writeStoredUser(null);
    if (token !== boot) return;
    user.value = await authApi.me();
    chat.value = emptyChat();
    await chatApi.resetToHistory(ifCurrent(token));
  }

  return { user, chat, authApi, chatApi, bootstrap, applySignedIn, applySignedOut, apiUrl };
}
