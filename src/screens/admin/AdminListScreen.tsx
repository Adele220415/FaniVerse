import { useNavigate, useParams } from "react-router-dom"
import { Plus, Edit2, Trash2, Search } from "lucide-react"
import TopBar from "../../components/TopBar"

type DataItem = {
  title: string
  meta: string
  img: string
}

const dataSets: Record<string, DataItem[]> = {
  content: [
    {
      title: "Attack on Titan: Full Timeline",
      meta: "Anime · 1,240 views",
      img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=50&h=50&fit=crop&auto=format",
    },
    {
      title: "Marvel Phase 6 Guide",
      meta: "Marvel · 3,890 views",
      img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=50&h=50&fit=crop&auto=format",
    },
    {
      title: "Elden Ring Lore Deep Dive",
      meta: "Gaming · 2,100 views",
      img: "https://images.unsplash.com/photo-1636953056323-9c09fdd74fa6?w=50&h=50&fit=crop&auto=format",
    },
  ],
  events: [
    {
      title: "Anime Expo 2026",
      meta: "Jul 4–7 · Los Angeles",
      img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=50&h=50&fit=crop&auto=format",
    },
    {
      title: "PAX West 2026",
      meta: "Sep 1–4 · Seattle",
      img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=50&h=50&fit=crop&auto=format",
    },
  ],
  merchandise: [
    {
      title: "Levi Ackerman Figure",
      meta: "Anime · $89.99",
      img: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=50&h=50&fit=crop&auto=format",
    },
    {
      title: "Iron Man Helmet Replica",
      meta: "Marvel · $149.99",
      img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=50&h=50&fit=crop&auto=format",
    },
  ],
  users: [
    {
      title: "Alex Rivera",
      meta: "Fan · Joined Sep 2026",
      img: "https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=50&h=50&fit=crop&auto=format",
    },
    {
      title: "Jordan Park",
      meta: "Fan · Joined Aug 2026",
      img: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop&auto=format",
    },
    {
      title: "Maya Chen",
      meta: "Admin · Joined Jan 2025",
      img: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=50&h=50&fit=crop&auto=format",
    },
  ],
  categories: [
    {
      title: "Anime",
      meta: "34 content items",
      img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=50&h=50&fit=crop&auto=format",
    },
    {
      title: "Gaming",
      meta: "28 content items",
      img: "https://images.unsplash.com/photo-1636953056323-9c09fdd74fa6?w=50&h=50&fit=crop&auto=format",
    },
    {
      title: "Marvel",
      meta: "19 content items",
      img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=50&h=50&fit=crop&auto=format",
    },
  ],
}

export default function AdminListScreen() {
  const navigate = useNavigate()
  const { type = "content" } = useParams<{ type: string }>()
  const items = dataSets[type] ?? []
  const label = type.charAt(0).toUpperCase() + type.slice(1)

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar
        title={`Manage ${label}`}
        right={
          <button
            onClick={() => navigate(`/admin/${type}/new`)}
            style={{
              background: "#FF6B5C",
              border: "none",
              borderRadius: 8,
              width: 32,
              height: 32,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: "pointer",
            }}
          >
            <Plus size={16} color="white" />
          </button>
        }
      />

      <div
        style={{
          padding: "12px 20px",
          borderBottom: "1px solid var(--border)",
        }}
      >
        <div style={{ position: "relative" }}>
          <Search
            size={15}
            color="var(--muted)"
            style={{
              position: "absolute",
              left: 13,
              top: "50%",
              transform: "translateY(-50%)",
            }}
          />
          <input
            className="fv-input"
            placeholder={`Search ${label.toLowerCase()}...`}
            style={{ paddingLeft: 40, padding: "11px 12px 11px 40px" }}
          />
        </div>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "12px 20px" }}>
        {items.map((item, i) => (
          <div
            key={i}
            style={{
              display: "flex",
              alignItems: "center",
              gap: 14,
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 12,
              padding: 14,
              marginBottom: 10,
            }}
          >
            <img
              src={item.img}
              alt={item.title}
              style={{
                width: 44,
                height: 44,
                borderRadius: 10,
                objectFit: "cover",
                background: "var(--surface-2)",
                flexShrink: 0,
              }}
            />
            <div style={{ flex: 1 }}>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                  marginBottom: 3,
                }}
              >
                {item.title}
              </div>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 12,
                  color: "var(--muted)",
                }}
              >
                {item.meta}
              </div>
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <button
                onClick={() => navigate(`/admin/${type}/edit`)}
                style={{
                  background: "rgba(124,92,255,0.15)",
                  border: "none",
                  borderRadius: 7,
                  width: 30,
                  height: 30,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  cursor: "pointer",
                  color: "#7C5CFF",
                }}
              >
                <Edit2 size={13} />
              </button>
              <button
                style={{
                  background: "rgba(255,107,92,0.15)",
                  border: "none",
                  borderRadius: 7,
                  width: 30,
                  height: 30,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  cursor: "pointer",
                  color: "#FF6B5C",
                }}
              >
                <Trash2 size={13} />
              </button>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
