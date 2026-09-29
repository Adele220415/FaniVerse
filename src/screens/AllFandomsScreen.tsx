import BackButton from "../components/BackButton"
import FandomCard from "../components/FandomCard"
import { fandomPicks } from "../data/fandomPicks"

export default function AllFandomsScreen({
  onDone,
  onBack,
}: {
  onDone: () => void
  onBack: () => void
}) {
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
          Find your fandoms
        </h1>
        <p style={{ fontSize: 14, color: "var(--muted)", margin: "6px 0 0" }}>
          {fandomPicks.length} picks across the fandoms you love
        </p>
      </div>

      <div className="flex-1 min-h-0 overflow-y-auto pb-4">
        <div className="grid grid-cols-2 gap-3">
          {fandomPicks.map((card) => (
            <FandomCard key={card.title} card={card} onClick={onDone} />
          ))}
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
          Continue
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
