import TopBar from "../../components/TopBar"
import { Download, Trash2 } from "lucide-react"

const items = [
  {
    title: "Attack on Titan: Full Timeline",
    tag: "Anime",
    size: "1.2 MB",
    downloaded: true,
  },
  {
    title: "Marvel Phase 6 Guide",
    tag: "Marvel",
    size: "840 KB",
    downloaded: true,
  },
  {
    title: "Elden Ring Lore Deep Dive",
    tag: "Gaming",
    size: "2.1 MB",
    downloaded: false,
  },
]

export default function OfflineContentScreen() {
  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title="Offline Content" />

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 13,
            color: "var(--muted)",
            margin: "0 0 16px",
          }}
        >
          Content saved for offline reading
        </p>
        {items.map((item, i) => (
          <div
            key={i}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 14,
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              padding: 14,
              marginBottom: 10,
            }}
          >
            <div style={{ flex: 1 }}>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                  marginBottom: 4,
                }}
              >
                {item.title}
              </div>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span className="badge-violet" style={{ fontSize: 10 }}>
                  {item.tag}
                </span>
                <span
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 12,
                    color: "var(--muted)",
                  }}
                >
                  {item.size}
                </span>
              </div>
            </div>
            {item.downloaded ? (
              <button
                style={{
                  background: "none",
                  border: "none",
                  cursor: "pointer",
                  color: "#FF6B5C",
                }}
              >
                <Trash2 size={18} />
              </button>
            ) : (
              <button
                style={{
                  background: "rgba(124,92,255,0.15)",
                  border: "1px solid rgba(124,92,255,0.3)",
                  borderRadius: 8,
                  width: 34,
                  height: 34,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  cursor: "pointer",
                  color: "#7C5CFF",
                }}
              >
                <Download size={16} />
              </button>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
