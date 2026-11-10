# Universal Hub — Key Sitesi

Vercel + Vercel KV (Redis) üzerinde çalışan key sistemi.

---

## Kurulum (5 adım)

### 1. Vercel'e Deploy et

```bash
# Vercel CLI ile
npm i -g vercel
cd keysite
vercel --prod
```

Ya da GitHub'a push et → vercel.com'dan "New Project" → repo'yu seç → deploy.

### 2. Vercel KV (Redis) oluştur

1. Vercel Dashboard → Storage → Create Database → KV
2. Projeye bağla → Environment Variables otomatik eklenir

### 3. Görevleri ayarla

`lib/tasks.ts` dosyasını aç, URL'leri kendi kanalın/videon/discord'unla değiştir:

```ts
url: "https://www.youtube.com/@SENIN_KANALIN",
url: "https://www.youtube.com/watch?v=SENIN_VIDEON",
url: "https://discord.gg/SENIN_DISCORD",
```

### 4. loader.lua'yı güncelle

`loader.lua` içindeki URL'i kendi Vercel URL'inle değiştir:

```lua
local VERIFY_URL = "https://SENIN_UYGULAMAN.vercel.app/api/verify"
local KEY_SITE   = "https://SENIN_UYGULAMAN.vercel.app/getkey"
```

### 5. Executor'da kullan

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/b86138092-maker/universalhub/refs/heads/main/loader.lua", true))()
```

---

## Nasıl çalışır?

```
Kullanıcı loader'ı çalıştırır
  ↓
Key var mı? → /api/verify (HWID ile)
  ↓ Yok
Key sitesine git → Görevleri tamamla
  ↓
/api/task (her görev için)
  ↓
Hepsi tamam → /api/generate → Key üretilir (24h)
  ↓
Kullanıcı key'i loader'a girer
  ↓
/api/verify → Geçerliyse script yüklenir
```

## API Endpoints

| Endpoint | Method | Açıklama |
|----------|--------|----------|
| `/api/task` | GET | Görev durumlarını getir (IP bazlı) |
| `/api/task` | POST `{taskId}` | Görevi tamamlandı işaretle |
| `/api/generate` | POST | Key üret (tüm görevler tamam olmalı) |
| `/api/verify` | GET `?key=&hwid=` | Key doğrula (loader kullanır) |

## Key kuralları

- **24 saat geçerlidir**, sonra yeniden görev yapılması gerekir
- **HWID'e bağlıdır** — ilk kullanılan bilgisayara kilitlenir
- **IP başına günde 1 key** üretilir
