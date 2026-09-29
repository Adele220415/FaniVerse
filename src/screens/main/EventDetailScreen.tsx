import { useNavigate } from "react-router-dom"
import {
  ArrowLeft,
  Bookmark,
  MapPin,
  Calendar,
  ExternalLink,
} from "lucide-react"

export default function EventDetailScreen() {
  const navigate = useNavigate()

  return (
    <div
      style={{ height: "100%", background: "var(--app-bg)", overflowY: "auto" }}
    >
      {/* Hero */}
      <div
        style={{
          position: "relative",
          height: 220,
          background: "var(--surface-2)",
          overflow: "hidden",
        }}
      >
        <img
          src="https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=390&h=220&fit=crop&auto=format"
          alt="Anime Expo 2026"
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
        <div
          style={{
            position: "absolute",
            inset: 0,
            background:
              "linear-gradient(to bottom, rgba(18,18,20,0.5) 0%, transparent 40%, var(--app-bg) 100%)",
          }}
        />
        <button
          onClick={() => navigate(-1)}
          style={{
            position: "absolute",
            top: 16,
            left: 16,
            background: "rgba(18,18,20,0.7)",
            backdropFilter: "blur(8px)",
            border: "1px solid rgba(255,255,255,0.1)",
            borderRadius: 8,
            width: 36,
            height: 36,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            color: "var(--text)",
          }}
        >
          <ArrowLeft size={18} />
        </button>
        <button
          style={{
            position: "absolute",
            top: 16,
            right: 16,
            background: "rgba(18,18,20,0.7)",
            backdropFilter: "blur(8px)",
            border: "1px solid rgba(255,255,255,0.1)",
            borderRadius: 8,
            width: 36,
            height: 36,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            color: "var(--text)",
          }}
        >
          <Bookmark size={18} />
        </button>
      </div>

      <div style={{ padding: "20px 20px 100px" }}>
        <span
          className="badge-violet"
          style={{ marginBottom: 12, display: "inline-block" }}
        >
          Anime
        </span>
        <h1
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 24,
            fontWeight: 700,
            color: "var(--text)",
            margin: "0 0 16px",
          }}
        >
          Anime Expo 2026
        </h1>

        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 10,
            marginBottom: 20,
          }}
        >
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 12,
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
              color: "var(--muted)",
            }}
          >
            <Calendar size={16} color="#7C5CFF" />
            July 4–7, 2026 · 10:00 AM – 8:00 PM
          </div>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 12,
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
              color: "var(--muted)",
            }}
          >
            <MapPin size={16} color="#7C5CFF" />
            Los Angeles Convention Center, CA
          </div>
        </div>

        <div
          style={{ height: 1, background: "var(--border)", margin: "16px 0" }}
        />

        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 15,
            color: "var(--muted-2)",
            lineHeight: 1.7,
            margin: "0 0 24px",
          }}
        >
          Anime Expo is North America's largest anime convention, celebrating
          Japanese pop culture in all its forms — from anime and manga to music,
          gaming, and art. Featuring exclusive panels, world premieres, and
          interactive experiences with your favorite studios and creators.
        </p>
        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 15,
            color: "var(--muted-2)",
            lineHeight: 1.7,
            margin: "0 0 28px",
          }}
        >
          This year's lineup includes meet-and-greets with voice actors,
          exclusive merchandise drops, cosplay competitions, and a dedicated
          gaming hall with demos from top publishers.
        </p>
      </div>

      {/* Fixed bottom */}
      <div
        style={{
          position: "sticky",
          bottom: 0,
          background: "var(--app-bg)",
          borderTop: "1px solid var(--border)",
          padding: "16px 20px",
          display: "flex",
          gap: 12,
        }}
      >
        <button
          className="btn-secondary"
          style={{ flex: 0, padding: "14px 18px", gap: 6 }}
        >
          <MapPin size={16} /> Map
        </button>
        <button
          className="btn-primary"
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
          }}
        >
          Get tickets <ExternalLink size={16} />
        </button>
      </div>
    </div>
  )
}
