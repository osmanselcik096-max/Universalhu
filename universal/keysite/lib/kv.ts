// Vercel KV (Redis) wrapper
// KV_REST_API_URL ve KV_REST_API_TOKEN env değişkenleri Vercel dashboard'dan otomatik gelir.
// Yerel test için .env.local'e ekle.

import { kv } from "@vercel/kv";

export { kv };

// Key formatı: UHUB-XXXXXXXX (8 karakter hex)
export function generateKeyString(): string {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  let key = "UHUB-";
  for (let i = 0; i < 8; i++) {
    key += chars[Math.floor(Math.random() * chars.length)];
  }
  return key;
}

// KV'de key kaydı:
// key:<UHUB-XXX> = { valid: true, hwid: null | string, createdAt: number, expiresAt: number }

export interface KeyRecord {
  valid: boolean;
  hwid: string | null;
  createdAt: number;
  expiresAt: number; // unix timestamp ms, 0 = süresiz
}

// Görev kaydı (IP bazlı, 24 saatte bir sıfırlanır):
// task_done:<taskId>:<ip> = "1"  (TTL: 86400 saniye)

export const TASK_TTL = 60 * 60 * 24; // 24 saat (saniye)

// Key TTL: 24 saat
export const KEY_TTL_MS = 1000 * 60 * 60 * 24;
