import { useState } from "react"
import { useNavigate } from "react-router-dom"

const interests = [
  { id: "anime", label: "🎌 Anime" },
  { id: "gaming", label: "🎮 Gaming" },
  { id: "marvel", label: "⚡ Marvel" },
  { id: "starwars", label: "🌌 Star Wars" },
  { id: "comics", label: "💥 Comics" },
  { id: "kpop", label: "🎵 K-Pop" },
  { id: "scifi", label: "🚀 Sci-Fi" },
  { id: "dc", label: "🦇 DC" },
  { id: "fantasy", label: "🐉 Fantasy" },
  { id: "disney", label: "✨ Disney" },
  { id: "lotr", label: "💍 LOTR" },
  { id: "pokemon", label: "🔴 Pokémon" },
]

export default function SelectInterestsScreen() {
  const navigate = useNavigate()
  const [selected, setSelected] = useState<Set<string>>(new Set())

  const toggle = (id: string) => {
    setSelected((prev) => {
      const next = new Set(prev)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return next
    })
  }

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div style={{ padding: "32px 24px 20px" }}>
        <h1
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 26,
            fontWeight: 700,
            color: "var(--text)",
            margin: "0 0 8px",
          }}
        >
          What are you into?
        </h1>
        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 14,
            color: "var(--muted)",
            margin: 0,
          }}
        >
          Pick your fandoms — select as many as you like
        </p>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "0 24px" }}>
        <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
          {interests.map((item) => (
            <button
              key={item.id}
              onClick={() => toggle(item.id)}
              className={`fv-chip ${selected.has(item.id) ? "active" : ""}`}
              style={{ fontSize: 14, padding: "10px 18px" }}
            >
              {item.label}
            </button>
          ))}
        </div>
      </div>

      <div
        style={{
          padding: "20px 24px 28px",
          borderTop: "1px solid var(--border)",
          background: "var(--app-bg)",
          display: "flex",
          flexDirection: "column",
          gap: 10,
        }}
      >
        <button
          className="btn-primary"
          onClick={() => navigate("/select-badge")}
          disabled={selected.size === 0}
          style={{ opacity: selected.size === 0 ? 0.5 : 1 }}
        >
          Continue {selected.size > 0 && `(${selected.size} selected)`}
        </button>
        <button
          onClick={() => navigate("/select-badge")}
          style={{
            background: "none",
            border: "none",
            color: "var(--muted)",
            fontFamily: "Inter, sans-serif",
            fontSize: 13,
            cursor: "pointer",
          }}
        >
          Skip for now
        </button>
      </div>
    </div>
  )
}
