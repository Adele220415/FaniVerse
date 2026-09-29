import { useState } from "react"
import { useNavigate } from "react-router-dom"

const badges = [
  { id: "star", emoji: "⭐", label: "Star Fan" },
  { id: "flame", emoji: "🔥", label: "On Fire" },
  { id: "crystal", emoji: "💎", label: "Crystal" },
  { id: "rocket", emoji: "🚀", label: "Explorer" },
  { id: "crown", emoji: "👑", label: "Legend" },
  { id: "lightning", emoji: "⚡", label: "Hero" },
  { id: "dragon", emoji: "🐉", label: "Dragon" },
  { id: "comet", emoji: "☄️", label: "Comet" },
  { id: "galaxy", emoji: "🌌", label: "Galaxy" },
]

export default function SelectBadgeScreen() {
  const navigate = useNavigate()
  const [selected, setSelected] = useState<string | null>(null)

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
          Pick your badge
        </h1>
        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 14,
            color: "var(--muted)",
            margin: 0,
          }}
        >
          This flair shows next to your name in the community
        </p>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "0 24px" }}>
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(3, 1fr)",
            gap: 14,
          }}
        >
          {badges.map((badge) => (
            <button
              key={badge.id}
              onClick={() => setSelected(badge.id)}
              style={{
                background:
                  selected === badge.id
                    ? "rgba(124,92,255,0.15)"
                    : "var(--surface)",
                border: `2px solid ${
                  selected === badge.id ? "#7C5CFF" : "var(--border)"
                }`,
                borderRadius: 16,
                padding: "20px 12px",
                cursor: "pointer",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 8,
                transition: "all 0.15s",
              }}
            >
              <span style={{ fontSize: 36 }}>{badge.emoji}</span>
              <span
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 12,
                  fontWeight: 500,
                  color: selected === badge.id ? "#7C5CFF" : "var(--muted)",
                }}
              >
                {badge.label}
              </span>
            </button>
          ))}
        </div>
      </div>

      <div
        style={{
          padding: "20px 24px 28px",
          borderTop: "1px solid var(--border)",
          background: "var(--app-bg)",
        }}
      >
        <button className="btn-primary" onClick={() => navigate("/home")}>
          {selected ? "Continue" : "Skip"}
        </button>
      </div>
    </div>
  )
}
