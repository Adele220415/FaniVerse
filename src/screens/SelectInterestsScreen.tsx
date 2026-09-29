import { useState } from "react"
import BackButton from "../components/BackButton"
import FandomCard from "../components/FandomCard"
import { fandomPicks } from "../data/fandomPicks"

const interests = [
  { id: "anime", label: "Anime", emoji: "⛩️" },
  { id: "gaming", label: "Gaming", emoji: "🎮" },
  { id: "marvel", label: "Marvel", emoji: "🦸" },
  { id: "starwars", label: "Star Wars", emoji: "⚔️" },
  { id: "comics", label: "Comics", emoji: "💥" },
  { id: "kpop", label: "K-Pop", emoji: "🎤" },
  { id: "scifi", label: "Sci-Fi", emoji: "🚀" },
  { id: "dnd", label: "D&D", emoji: "🎲" },
  { id: "hiphop", label: "Hip-Hop", emoji: "🎧" },
  { id: "sports", label: "Sports", emoji: "⚡" },
  { id: "horror", label: "Horror", emoji: "👻" },
  { id: "fantasy", label: "Fantasy", emoji: "🧙" },
]

export default function SelectInterestsScreen({
  onDone,
  onBack,
  onSeeAll,
}: {
  onDone: () => void
  onBack: () => void
  onSeeAll: () => void
}) {
  const [selected, setSelected] = useState<Set<string>>(new Set())

  const toggle = (id: string) =>
    setSelected((s) => {
      const n = new Set(s)
      n.has(id) ? n.delete(id) : n.add(id)
      return n
    })

  return (
    <div
      className="flex flex-col flex-1 min-h-0 px-6 pb-8"
      style={{ background: "var(--app-bg)" }}
    >
      <div className="pt-14 pb-6">
        <BackButton onClick={onBack} style={{ marginBottom: 14 }} />
        <h1
          style={{
            fontFamily: "Space Grotesk",
            fontSize: 26,
            fontWeight: 700,
            color: "var(--text)",
            margin: 0,
          }}
        >
          What are you into?
        </h1>
        <p style={{ fontSize: 14, color: "var(--muted)", margin: "6px 0 0" }}>
          Pick your fandoms — select as many as you like
        </p>
      </div>

      <div className="flex-1 min-h-0 overflow-y-auto pb-4">
        <div
          className="flex flex-wrap gap-3"
          style={{ alignContent: "flex-start" }}
        >
          {interests.map(({ id, label, emoji }) => {
            const active = selected.has(id)
            return (
              <button
                key={id}
                onClick={() => toggle(id)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  padding: "10px 16px",
                  borderRadius: 50,
                  border: `1.5px solid ${active ? "#7C5CFF" : "var(--border)"}`,
                  background: active
                    ? "rgba(124,92,255,0.15)"
                    : "var(--surface)",
                  color: active ? "#7C5CFF" : "var(--text)",
                  fontSize: 14,
                  fontFamily: "Inter",
                  fontWeight: 500,
                  cursor: "pointer",
                  transition: "all 0.15s",
                }}
              >
                <span>{emoji}</span>
                <span>{label}</span>
              </button>
            )
          })}
        </div>

        <div style={{ marginTop: 26 }}>
          <div
            className="flex items-center justify-between"
            style={{ marginBottom: 12 }}
          >
            <h2
              style={{
                fontFamily: "Space Grotesk",
                fontSize: 17,
                fontWeight: 600,
                color: "var(--text)",
                margin: 0,
              }}
            >
              Find your fandoms
            </h2>
            <button
              onClick={onSeeAll}
              style={{
                background: "none",
                border: "none",
                padding: 0,
                color: "#7C5CFF",
                fontFamily: "Inter",
                fontSize: 13,
                fontWeight: 500,
                cursor: "pointer",
              }}
            >
              See all
            </button>
          </div>

          <div className="grid grid-cols-2 gap-3">
            {fandomPicks.slice(0, 6).map((card) => (
              <FandomCard key={card.title} card={card} onClick={onDone} />
            ))}
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-3 pt-4 shrink-0">
        <button
          onClick={onDone}
          style={{
            background: "#7C5CFF",
            color: "#fff",
            fontFamily: "Space Grotesk",
            fontWeight: 600,
            fontSize: 16,
            padding: "14px",
            borderRadius: 8,
            border: "none",
            cursor: "pointer",
            transition: "all 0.15s",
          }}
        >
          Continue {selected.size > 0 ? `(${selected.size} selected)` : ""}
        </button>
        <button
          onClick={onDone}
          style={{
            background: "none",
            border: "none",
            color: "var(--muted)",
            fontSize: 14,
            cursor: "pointer",
          }}
        >
          Skip for now
        </button>
      </div>
    </div>
  )
}
