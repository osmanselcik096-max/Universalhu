import Link from "next/link";

export default function Home() {
  return (
    <main style={{
      minHeight: "100vh",
      display: "flex",
      flexDirection: "column",
      alignItems: "center",
      justifyContent: "center",
      padding: "24px",
      background: "linear-gradient(135deg, #0a0a0f 0%, #0f0f1a 100%)",
    }}>

      {/* Logo / başlık */}
      <div style={{ textAlign: "center", marginBottom: "48px" }}>
        <div style={{
          fontSize: "13px",
          letterSpacing: "4px",
          color: "#e63946",
          fontWeight: 700,
          textTransform: "uppercase",
          marginBottom: "12px",
        }}>
          Roblox Script Hub
        </div>
        <h1 style={{
          fontSize: "clamp(32px, 6vw, 56px)",
          fontWeight: 900,
          letterSpacing: "-1px",
          lineHeight: 1.1,
        }}>
          UNIVERSAL{" "}
          <span style={{ color: "#e63946" }}>HUB</span>
        </h1>
        <p style={{
          marginTop: "16px",
          color: "#6b6b80",
          fontSize: "15px",
          maxWidth: "400px",
        }}>
          ESP, Aimbot, Auto Farm ve daha fazlası.<br />
          Görevleri tamamla, ücretsiz key al.
        </p>
      </div>

      {/* Kart */}
      <div style={{
        background: "#111118",
        border: "1px solid #1e1e2e",
        borderRadius: "16px",
        padding: "32px",
        maxWidth: "420px",
        width: "100%",
        boxShadow: "0 0 40px rgba(230,57,70,0.08)",
      }}>
        <h2 style={{ fontSize: "18px", fontWeight: 700, marginBottom: "8px" }}>
          Key nasıl alınır?
        </h2>
        <p style={{ color: "#6b6b80", fontSize: "14px", marginBottom: "24px", lineHeight: 1.6 }}>
          Aşağıdaki görevleri tamamla, 24 saatlik ücretsiz key'ini al.
          Key her 24 saatte bir yenilenir.
        </p>

        <div style={{ display: "flex", flexDirection: "column", gap: "12px" }}>
          {[
            { icon: "🔴", text: "YouTube kanalına abone ol" },
            { icon: "👍", text: "Son videoya like at" },
            { icon: "💬", text: "Discord'a katıl" },
          ].map((item, i) => (
            <div key={i} style={{
              display: "flex",
              alignItems: "center",
              gap: "12px",
              background: "#0d0d14",
              borderRadius: "10px",
              padding: "12px 16px",
              border: "1px solid #1a1a28",
            }}>
              <span style={{ fontSize: "20px" }}>{item.icon}</span>
              <span style={{ fontSize: "14px", color: "#c0c0d0" }}>{item.text}</span>
            </div>
          ))}
        </div>

        <Link href="/getkey">
          <button style={{
            marginTop: "24px",
            width: "100%",
            padding: "14px",
            background: "#e63946",
            color: "#fff",
            fontWeight: 700,
            fontSize: "15px",
            borderRadius: "10px",
            letterSpacing: "0.5px",
            transition: "opacity 0.15s",
          }}
            onMouseOver={(e) => (e.currentTarget.style.opacity = "0.85")}
            onMouseOut={(e) => (e.currentTarget.style.opacity = "1")}
          >
            🔑 Key Al →
          </button>
        </Link>
      </div>

      {/* Footer */}
      <p style={{
        marginTop: "32px",
        color: "#2e2e3e",
        fontSize: "12px",
      }}>
        Universal Hub © 2026 — Tüm hakları saklıdır.
      </p>
    </main>
  );
}
