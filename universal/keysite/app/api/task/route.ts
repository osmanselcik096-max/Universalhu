// POST /api/task
// Body: { taskId: string }
// Kullanıcının IP'sini alır, görevi tamamlandı olarak işaretler.
// 24 saat boyunca tekrar yapılamaz.

import { NextRequest, NextResponse } from "next/server";
import { kv, TASK_TTL } from "@/lib/kv";
import { TASKS } from "@/lib/tasks";

function getIP(req: NextRequest): string {
  return (
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
    req.headers.get("x-real-ip") ||
    "unknown"
  );
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json();
    const { taskId } = body as { taskId?: string };

    if (!taskId) {
      return NextResponse.json({ error: "taskId gerekli" }, { status: 400 });
    }

    const task = TASKS.find((t) => t.id === taskId);
    if (!task) {
      return NextResponse.json({ error: "Görev bulunamadı" }, { status: 404 });
    }

    const ip = getIP(req);
    const kvKey = `task_done:${taskId}:${ip}`;

    // Zaten yapıldı mı?
    const existing = await kv.get(kvKey);
    if (existing) {
      return NextResponse.json({ ok: true, alreadyDone: true });
    }

    // Kaydet, TTL: 24 saat
    await kv.set(kvKey, "1", { ex: TASK_TTL });

    return NextResponse.json({ ok: true, alreadyDone: false });
  } catch (err) {
    console.error(err);
    return NextResponse.json({ error: "Sunucu hatası" }, { status: 500 });
  }
}

// GET /api/task?taskId=xxx  — tamamlandı mı kontrol et
export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const taskId = searchParams.get("taskId");
    const ip = getIP(req);

    if (!taskId) {
      // Tüm görevlerin durumunu döndür
      const results: Record<string, boolean> = {};
      for (const task of TASKS) {
        const val = await kv.get(`task_done:${task.id}:${ip}`);
        results[task.id] = !!val;
      }
      return NextResponse.json({ tasks: results });
    }

    const val = await kv.get(`task_done:${taskId}:${ip}`);
    return NextResponse.json({ done: !!val });
  } catch (err) {
    console.error(err);
    return NextResponse.json({ error: "Sunucu hatası" }, { status: 500 });
  }
}
