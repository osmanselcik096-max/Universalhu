// POST /api/generate
// Tüm görevler tamamlandıysa yeni bir key üretir ve KV'ye kaydeder.
// Aynı IP'ye 24 saatte bir key verilir.

import { NextRequest, NextResponse } from "next/server";
import { kv, generateKeyString, KEY_TTL_MS, KeyRecord, TASK_TTL } from "@/lib/kv";
import { TASKS, REQUIRED_TASK_COUNT } from "@/lib/tasks";

function getIP(req: NextRequest): string {
  return (
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
    req.headers.get("x-real-ip") ||
    "unknown"
  );
}

export async function POST(req: NextRequest) {
  try {
    const ip = getIP(req);

    // Son 24 saatte bu IP'e zaten key verildi mi?
    const recentKey = await kv.get<string>(`ip_key:${ip}`);
    if (recentKey) {
      // Hâlâ geçerli key'i döndür
      return NextResponse.json({ ok: true, key: recentKey, cached: true });
    }

    // Tüm görevler tamamlandı mı?
    let doneCount = 0;
    for (const task of TASKS) {
      const val = await kv.get(`task_done:${task.id}:${ip}`);
      if (val) doneCount++;
    }

    if (doneCount < REQUIRED_TASK_COUNT) {
      return NextResponse.json(
        { error: `Önce tüm görevleri tamamla (${doneCount}/${REQUIRED_TASK_COUNT})` },
        { status: 403 }
      );
    }

    // Key üret
    const newKey = generateKeyString();
    const record: KeyRecord = {
      valid: true,
      hwid: null,
      createdAt: Date.now(),
      expiresAt: Date.now() + KEY_TTL_MS,
    };

    // key:<UHUB-XXX> → record (TTL: 24h saniye cinsinden)
    await kv.set(`key:${newKey}`, record, { ex: TASK_TTL });

    // ip_key:<ip> → key string (TTL: 24h, aynı IP tekrar alamasın)
    await kv.set(`ip_key:${ip}`, newKey, { ex: TASK_TTL });

    return NextResponse.json({ ok: true, key: newKey, cached: false });
  } catch (err) {
    console.error(err);
    return NextResponse.json({ error: "Sunucu hatası" }, { status: 500 });
  }
}
