"use client";

import { useState, useEffect, useCallback } from "react";
import { TASKS, REQUIRED_TASK_COUNT } from "@/lib/tasks";

type TaskStatus = Record<string, boolean>;

export default function GetKeyPage() {
  const [taskStatus, setTaskStatus] = useState<TaskStatus>({});
  const [loading,    setLoading]    = useState(true);
  const [genLoading, setGenLoading] = useState(false);
  const [key,        setKey]        = useState<string | null>(null);
  const [error,      setError]      = useState<string | null>(null);
  const [copied,     setCopied]     = useState(false);

  // Görev durumlarını çek
  const fetchStatus = useCallback(async () => {
    try {
      const res = await fetch("/api/task");
      const data = await res.json();
      if (data.tasks) setTaskStatus(data.tasks);
    } catch { /* ignore */ }
    setLoading(false);
  }, []);

  useEffect(() => { fetchStatus(); }, [fetchStatus]);

  const doneCount = Object.values(taskStatus).filter(Boolean).length;
  const allDone   = doneCount >= REQUIRED_TASK_COUNT;

  // Göreve git + tamamlandı kaydet
  const handleTask = async (taskId: string, url: string) => {
    // Önce dış linke yönlendir
    window.open(url, "_blank", "noopener");

    // 3 saniye sonra sunucuya bildir
    setTimeout(async () => {
      try {
        await fetch("/api/task", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ taskId }),
        });
        await fetchStatus();
      } catch { /* ignore */ }
    }, 3000);
  };

  // Key üret
  const handleGenerate = async () => {
    setGenLoading(true);
    setError(null);
    try {
      const res  = await fetch("/api/generate", { method: "POST" });
      const data = await res.json();
      if (data.ok && data.key) {
        setKey(data.key);
      } else {
        setError(data.error || "Bir hata oluştu.");
      }
    } catch {
      setError("Bağlantı hatası.");
    }
    setGenLoading(false);
  };

  // Key kopyala
  const handleCopy = () => {
    if (!key) return;
    navigator.clipboard.writeText(key).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  };

  // ── STYLES ──────────────────────────────────────────────────────────────
  const S = {
    page: {
      minHeight: "100vh",
      background: "linear-gradient(135deg, #0a0a0f 0%, #0f0f1a 100%)",
      display: "flex",
      flexDirection: "column" as const,
      alignItems: "center",
      padding: "32px 16px",
    },
    header: {
      textAlign: "center" as const,
      marginBottom: "32px",
    },
    tag: {
      fontSize: "11px",
      letterSpacing: "3px",
      color: "#e63946",
      fontWeight: 700,
      textTransform: "uppercase" as const,
      marginBottom: "8px",
    },
    h1: {
      fontSize: "28px",
      fontWeight: 800,
    },
    sub: {
      color: "#5a5a70",
      fontSize: "13px",
      marginTop: "6px",
    },
    card: {
      background: "#111118",
      border: "1px solid #1e1e2e",
      borderRadius: "16px",
      padding: "24px",
      width: "100%",
      maxWidth: "460px",
      boxShadow: "0 0 40px rgba(230,57,70,0.06)",
    },
    sectionTitle: {
      fontSize: "13px",
      fontWeight: 700,
      color: "#6b6b80",
      textTransform: "uppercase" as const,
      letterSpacing: "2px",
      marginBottom: "16px",
    },
    taskRow: (done: boolean) => ({
      display: "flex",
      alignItems: "center",
      gap: "12px",
      background: done ? "rgba(46,204,113,0.06)" : "#0d0d14",
      border: `1px solid ${done ? "rgba(46,204,113,0.2)" : "#1a1a28"}`,
      borderRadius: "10px",
      padding: "14px 16px",
      marginBottom: "10px",
      cursor: done ? "default" : "pointer",
      transition: "border-color 0.15s, background 0.15s",
    }),
    taskIcon: {
      fontSize: "22px",
      flexShrink: 0,
    },
    taskInfo: {
      flex: 1,
    },
    taskTitle: {
      fontSize: "14px",
      fontWeight: 600,
      color: "#dde0ee",
    },
    taskDesc: {
      fontSize: "12px",
      color: "#5a5a70",
      marginTop: "2px",
    },
    taskBadge: (done: boolean) => ({
      flexShrink: 0,
      fontSize: "11px",
      fontWeight: 700,
      padding: "4px 10px",
      borderRadius: "20px",
      background: done ? "rgba(46,204,113,0.15)" : "rgba(230,57,70,0.1)",
      color: done ? "#2ecc71" : "#e63946",
      letterSpacing: "0.5px",
    }),
    divider: {
      height: "1px",
      background: "#1a1a28",
      margin: "20px 0",
    },
    progress: {
      display: "flex",
      alignItems: "center",
      justifyContent: "space-between",
      marginBottom: "12px",
    },
    progressText: {
      fontSize: "13px",
      color: "#6b6b80",
    },
    progressCount: {
      fontSize: "13px",
      fontWeight: 700,
      color: "#e0e0ee",
    },
    progressBar: {
      height: "6px",
      background: "#1a1a28",
      borderRadius: "3px",
      overflow: "hidden",
      marginBottom: "20px",
    },
    progressFill: {
      height: "100%",
      width: `${(doneCount / REQUIRED_TASK_COUNT) * 100}%`,
      background: allDone ? "#2ecc71" : "#e63946",
      borderRadius: "3px",
      transition: "width 0.4s ease",
    },
    btn: (disabled: boolean) => ({
      width: "100%",
      padding: "14px",
      background: disabled ? "#1a1a28" : "#e63946",
      color: disabled ? "#3a3a4a" : "#fff",
      fontWeight: 700,
      fontSize: "15px",
      borderRadius: "10px",
      cursor: disabled ? "not-allowed" : "pointer",
      transition: "opacity 0.15s",
      border: "none",
    }),
    keyBox: {
      marginTop: "16px",
      background: "#0a0a0f",
      border: "1px solid #2ecc71",
      borderRadius: "10px",
      padding: "16px",
      textAlign: "center" as const,
    },
    keyLabel: {
      fontSize: "11px",
      color: "#2ecc71",
      letterSpacing: "2px",
      fontWeight: 700,
      marginBottom: "8px",
    },
    keyText: {
      fontSize: "20px",
      fontWeight: 800,
      letterSpacing: "2px",
      color: "#fff",
      marginBottom: "12px",
    },
    copyBtn: {
      padding: "8px 20px",
      background: copied ? "rgba(46,204,113,0.15)" : "rgba(255,255,255,0.08)",
      color: copied ? "#2ecc71" : "#c0c0d0",
      border: `1px solid ${copied ? "rgba(46,204,113,0.3)" : "#2a2a3a"}`,
      borderRadius: "8px",
      fontSize: "13px",
      fontWeight: 600,
      cursor: "pointer",
      transition: "all 0.15s",
    },
    errorBox: {
      marginTop: "12px",
      background: "rgba(230,57,70,0.08)",
      border: "1px solid rgba(230,57,70,0.2)",
      borderRadius: "8px",
      padding: "10px 14px",
      fontSize: "13px",
      color: "#e63946",
    },
    noteBox: {
      marginTop: "16px",
      background: "rgba(255,255,255,0.03)",
      borderRadius: "8px",
      padding: "10px 14px",
      fontSize: "12px",
      color: "#4a4a5a",
      lineHeight: 1.6,
    },
  };

  if (loading) {
    return (
      <div style={{ ...S.page, justifyContent: "center" }}>
        <div style={{ color: "#3a3a4a", fontSize: "14px" }}>Yükleniyor...</div>
      </div>
    );
  }

  return (
    <div style={S.page}>
      <div style={S.header}>
        <div style={S.tag}>Universal Hub</div>
        <h1 style={S.h1}>🔑 Key Al</h1>
        <p style={S.sub}>Görevleri tamamla, 24 saatlik key'ini al.</p>
      </div>

      <div style={S.card}>

        {/* Görev listesi */}
        <div style={S.sectionTitle}>Görevler</div>

        {TASKS.map((task) => {
          const done = !!taskStatus[task.id];
          return (
            <div
              key={task.id}
              style={S.taskRow(done)}
              onClick={() => !done && handleTask(task.id, task.url)}
              onMouseOver={(e) => {
                if (!done) (e.currentTarget as HTMLDivElement).style.borderColor = "#e63946";
              }}
              onMouseOut={(e) => {
                if (!done) (e.currentTarget as HTMLDivElement).style.borderColor = "#1a1a28";
              }}
            >
              <span style={S.taskIcon}>{task.icon}</span>
              <div style={S.taskInfo}>
                <div style={S.taskTitle}>{task.title}</div>
                <div style={S.taskDesc}>{task.description}</div>
              </div>
              <div style={S.taskBadge(done)}>
                {done ? "✓ TAMAM" : "GİT →"}
              </div>
            </div>
          );
        })}

        <div style={S.divider} />

        {/* İlerleme */}
        <div style={S.progress}>
          <span style={S.progressText}>İlerleme</span>
          <span style={S.progressCount}>{doneCount} / {REQUIRED_TASK_COUNT}</span>
        </div>
        <div style={S.progressBar}>
          <div style={S.progressFill} />
        </div>

        {/* Key üret butonu */}
        {!key && (
          <button
            style={S.btn(!allDone || genLoading)}
            disabled={!allDone || genLoading}
            onClick={handleGenerate}
          >
            {genLoading ? "Üretiliyor..." : allDone ? "🔑 Key Üret" : `${doneCount}/${REQUIRED_TASK_COUNT} Görev Tamamlandı`}
          </button>
        )}

        {/* Hata */}
        {error && <div style={S.errorBox}>⚠ {error}</div>}

        {/* Key kutusu */}
        {key && (
          <div style={S.keyBox}>
            <div style={S.keyLabel}>SENİN KEY'İN</div>
            <div style={S.keyText}>{key}</div>
            <button style={S.copyBtn} onClick={handleCopy}>
              {copied ? "✓ Kopyalandı!" : "Kopyala"}
            </button>
          </div>
        )}

        {/* Bilgi notu */}
        <div style={S.noteBox}>
          ⏱ Key 24 saat geçerlidir. Süresi dolunca görevleri tekrar yapman gerekir.<br />
          🔒 Key bilgisayarına bağlanır, başka cihazda çalışmaz.<br />
          💾 Executor key'i otomatik kaydeder, bir daha sormaz.
        </div>

      </div>
    </div>
  );
}
