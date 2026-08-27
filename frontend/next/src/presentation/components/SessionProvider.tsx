"use client";

import {
  createContext,
  useContext,
  useState,
  type Dispatch,
  type ReactNode,
  type SetStateAction,
} from "react";
import type { ChatState, User } from "@/src/shared";
import { initialChat } from "@/src/application/session";

type Ctx = {
  user: User | null;
  setUser: Dispatch<SetStateAction<User | null>>;
  chat: ChatState;
  setChat: Dispatch<SetStateAction<ChatState>>;
};

const SessionContext = createContext<Ctx | null>(null);

export function SessionProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [chat, setChat] = useState<ChatState>(initialChat);
  return (
    <SessionContext.Provider value={{ user, setUser, chat, setChat }}>{children}</SessionContext.Provider>
  );
}

export function useSession() {
  const ctx = useContext(SessionContext);
  if (!ctx) throw new Error("SessionProvider missing");
  return ctx;
}
