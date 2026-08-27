export type Role = "user" | "assistant" | "system" | "error";

export interface Message {
  id: string;
  role: Role;
  content: string;
  createdAt: string;
  failed?: boolean;
}

export interface User {
  id: string;
  email: string;
  guest: boolean;
}

export interface LlmActive {
  slug: string;
  name: string;
  version: string;
  vendor: string;
  license: string;
  about_en: string;
  about_id: string;
  weight: string;
  ram_min_gb: number;
  cpu_min_cores: number;
  disk_min_gb: number;
  gpu: string;
}
