// Görev tanımları — buraya istediğin görevleri ekle/çıkar

export interface Task {
  id: string;
  title: string;
  description: string;
  icon: string;        // emoji
  url: string;         // kullanıcının gideceği URL
  verifyType: "youtube_sub" | "youtube_like" | "manual" | "click";
  // click = sadece bağlantıya git, butona bas
  // youtube_sub / youtube_like = YouTube API olmadan basit "gittim" onayı
  // manual = admin onaylar (şimdilik yok)
  reward: string;      // göstermelik açıklama
}

export const TASKS: Task[] = [
  {
    id: "yt_sub",
    title: "YouTube'a Abone Ol",
    description: "Kanalımıza abone ol ve geri dön.",
    icon: "🔴",
    url: "https://www.youtube.com/@YOUR_CHANNEL",   // ← kendi kanalın
    verifyType: "youtube_sub",
    reward: "Key için gerekli",
  },
  {
    id: "yt_like",
    title: "Son Videoya Like At",
    description: "Son videomuzı beğen ve geri dön.",
    icon: "👍",
    url: "https://www.youtube.com/watch?v=YOUR_VIDEO_ID", // ← kendi videon
    verifyType: "youtube_like",
    reward: "Key için gerekli",
  },
  {
    id: "discord",
    title: "Discord'a Katıl",
    description: "Discord sunucumuza katıl.",
    icon: "💬",
    url: "https://discord.gg/YOUR_INVITE",          // ← kendi discord'un
    verifyType: "click",
    reward: "Key için gerekli",
  },
];

// Kaç görev tamamlanmalı key alınabilmek için
export const REQUIRED_TASK_COUNT = TASKS.length; // hepsini tamamla
