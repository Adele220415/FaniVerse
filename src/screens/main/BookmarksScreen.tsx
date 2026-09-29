import { useState } from "react"
import { useNavigate } from "react-router-dom"
import TopBar from "../../components/TopBar"

type Tab = "Articles" | "Stories" | "Media"

type DataItem = {
  title: string
  tag: string
  img: string
}

const data: Record<Tab, DataItem[]> = {
  Articles: [
    {
      title: "The Complete Attack on Titan Timeline",
      tag: "Anime",
      img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=60&h=60&fit=crop&auto=format",
    },
    {
      title: "Marvel Phase 6: Everything We Know",
      tag: "Marvel",
      img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=60&h=60&fit=crop&auto=format",
    },
    {
      title: "Top 10 Gaming Moments of 2026",
      tag: "Gaming",
      img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=60&h=60&fit=crop&auto=format",
    },
  ],
  Stories: [
    {
      title: "My first Anime Expo experience",
      tag: "Anime",
      img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=60&h=60&fit=crop&auto=format",
    },
    {
      title: "K-Pop: 3 years as an ARMY",
      tag: "K-Pop",
      img: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=60&h=60&fit=crop&auto=format",
    },
  ],
  Media: [
    {
      title: "Elden Ring Shadow of the Erdtree Trailer",
      tag: "Gaming",
      img: "https://images.unsplash.com/photo-1636953056323-9c09fdd74fa6?w=60&h=60&fit=crop&auto=format",
    },
  ],
}

export default function BookmarksScreen() {
  const navigate = useNavigate()
  const [tab, setTab] = useState<Tab>("Articles")

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title="Bookmarks" />

      {/* Tabs */}
      <div
        style={{
          display: "flex",
          gap: 6,
          padding: "12px 20px",
          borderBottom: "1px solid var(--border)",
        }}
      >
        {(["Articles", "Stories", "Media"] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`fv-chip ${tab === t ? "active" : ""}`}
          >
            {t}
          </button>
        ))}
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        {data[tab].map((item, i) => (
          <div
            key={i}
            onClick={() => navigate("/content-detail")}
            style={{
              display: "flex",
              gap: 14,
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              padding: 14,
              marginBottom: 10,
              cursor: "pointer",
            }}
          >
            <img
              src={item.img}
              alt={item.title}
              style={{
                width: 52,
                height: 52,
                borderRadius: 10,
                objectFit: "cover",
                background: "var(--surface-2)",
                flexShrink: 0,
              }}
            />
            <div>
              <span
                className="badge-violet"
                style={{
                  marginBottom: 6,
                  display: "inline-block",
                  fontSize: 10,
                }}
              >
                {item.tag}
              </span>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                  lineHeight: 1.3,
                }}
              >
                {item.title}
              </div>
            </div>
          </div>
        ))}
        {data[tab].length === 0 && (
          <div
            style={{
              textAlign: "center",
              padding: "60px 0",
              color: "var(--muted)",
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
            }}
          >
            No bookmarks yet
          </div>
        )}
      </div>
    </div>
  )
}
