import type { FandomPick } from "../data/fandomPicks"

export default function FandomCard({
  card,
  onClick,
}: {
  card: FandomPick
  onClick?: () => void
}) {
  return (
    <button
      onClick={onClick}
      style={{
        textAlign: "left",
        padding: 0,
        overflow: "hidden",
        borderRadius: 12,
        border: "1px solid var(--border)",
        background: "var(--surface)",
        cursor: "pointer",
        transition: "all 0.15s",
      }}
    >
      <img
        src={card.img}
        alt={card.title}
        style={{
          width: "100%",
          height: 84,
          objectFit: "cover",
          display: "block",
          background: "var(--surface)",
        }}
      />
      <div style={{ padding: "10px 10px 12px" }}>
        <div style={{ fontSize: 11, marginBottom: 4 }}>
          <span style={{ color: "#7C5CFF", fontWeight: 600 }}>{card.type}</span>
          <span style={{ color: "var(--muted)" }}> / {card.fandom}</span>
        </div>
        <div
          style={{
            fontFamily: "Space Grotesk",
            fontSize: 13,
            fontWeight: 600,
            lineHeight: 1.3,
            color: "var(--text)",
          }}
        >
          {card.title}
        </div>
      </div>
    </button>
  )
}
