import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "Universal Hub — Key Sistemi",
  description: "Görevleri tamamla, ücretsiz key al.",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="tr">
      <body>{children}</body>
    </html>
  );
}
