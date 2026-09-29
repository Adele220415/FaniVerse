import { useNavigate } from "react-router-dom"
import TopBar from "../../components/TopBar"

const items = [
  {
    title: "AoT: The Truth Behind the Walls",
    tag: "Anime",
    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=160&h=110&fit=crop&auto=format",
    excerpt:
      "The walls are made of colossal titans — but who built them and why?",
  },
  {
    title: "Elden Ring's Erdtree: What Is It?",
    tag: "Gaming",
    img: "https://images.unsplash.com/photo-1636953056323-9c09fdd74fa6?w=160&h=110&fit=crop&auto=format",
    excerpt:
      "The Erdtree is the manifestation of the Elden Ring itself — but its origins predate the Golden Order.",
  },
  {
    title: "Marvel Multiverse: Every Variant Ranked",
    tag: "Marvel",
    img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=160&h=110&fit=crop&auto=format",
    excerpt:
      "From Sacred Timeline variants to incursion threats — the full guide.",
  },
  {
    title: "Star Wars: The Sith Rule of Two Origin",
    tag: "Star Wars",
    img: "https://images.unsplash.com/photo-1472457897821-70d3819a0e24?w=160&h=110&fit=crop&auto=format",
    excerpt:
      "Darth Bane created the Rule of Two to purge infighting — but was he wrong?",
  },
]

export default function DeepDiveScreen() {
  const navigate = useNavigate()

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title="Deep Dive" />

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 14,
            color: "var(--muted)",
            margin: "0 0 20px",
            lineHeight: 1.5,
          }}
        >
          Advanced lore, hidden trivia, and behind-the-scenes analysis for
          dedicated fans.
        </p>

        <div
          style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}
        >
          {items.map((item, i) => (
            <div
              key={i}
              onClick={() => navigate("/content-detail")}
              style={{
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 14,
                overflow: "hidden",
                cursor: "pointer",
              }}
            >
              <div
                style={{
                  position: "relative",
                  height: 100,
                  background: "var(--surface-2)",
                  overflow: "hidden",
                }}
              >
                <img
                  src={item.img}
                  alt={item.title}
                  style={{ width: "100%", height: "100%", objectFit: "cover" }}
                />
                <div style={{ position: "absolute", top: 8, left: 8 }}>
                  <span className="badge-coral">Deep Dive</span>
                </div>
              </div>
              <div style={{ padding: "10px 12px" }}>
                <span
                  className="badge-violet"
                  style={{
                    fontSize: 10,
                    marginBottom: 6,
                    display: "inline-block",
                  }}
                >
                  {item.tag}
                </span>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 13,
                    fontWeight: 700,
                    color: "var(--text)",
                    marginBottom: 5,
                    lineHeight: 1.3,
                  }}
                >
                  {item.title}
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 11,
                    color: "var(--muted)",
                    lineHeight: 1.4,
                  }}
                >
                  {item.excerpt}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
