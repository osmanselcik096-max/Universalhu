// GET /api/verify?key=UHUB-XXXXXXXX&hwid=XXXX
// Loader.lua bu endpoint'i çağırır.
// HWID (Hardware ID) ile key'i eşleştirir — aynı key farklı bilgisayarda çalışmaz.

import { NextRequest, NextResponse } from "next/server";
import { kv, KeyRecord } from "@/lib/kv";

export async function GET(req: NextRequest) {
  try {
    const { searchParams } = new URL(req.url);
    const key  = searchParams.get("key")?.trim().toUpperCase();
    const hwid = searchParams.get("hwid")?.trim() || "unknown";

    if (!key) {
      return NextResponse.json({ valid: false, reason: "Key boş" }, { status: 400 });
    }

    const record = await kv.get<KeyRecord>(`key:${key}`);

    if (!record) {
      return NextResponse.json({ valid: false, reason: "Key bulunamadı veya süresi doldu" });
    }

    if (!record.valid) {
      return NextResponse.json({ valid: false, reason: "Key iptal edildi" });
    }

    // Süre kontrolü
    if (record.expiresAt > 0 && Date.now() > record.expiresAt) {
      await kv.del(`key:${key}`);
      return NextResponse.json({ valid: false, reason: "Key süresi doldu" });
    }

    // HWID bağlama: ilk kullanımda kaydet
    if (!record.hwid) {
      record.hwid = hwid;
      const ttlRemaining = Math.floor((record.expiresAt - Date.now()) / 1000);
      await kv.set(`key:${key}`, record, {
        ex: ttlRemaining > 0 ? ttlRemaining : undefined,
      });
    } else if (record.hwid !== hwid) {
      return NextResponse.json({
        valid: false,
        reason: "Bu key başka bir bilgisayara bağlı",
      });
    }

    return NextResponse.json({ valid: true, hwid: record.hwid });
  } catch (err) {
    console.error(err);
    return NextResponse.json({ valid: false, reason: "Sunucu hatası" }, { status: 500 });
  }
}
