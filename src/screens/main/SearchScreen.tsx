import { useState } from "react"
import { useNavigate } from "react-router-dom"
import { Search, ArrowLeft } from "lucide-react"

const results = [
  {
    type: "Article",
    title: "Attack on Titan: Full Lore Guide",
    tag: "Anime",
    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=60&h=60&fit=crop&auto=format",
    path: "/content-detail",
  },
  {
    type: "Event",
    title: "Anime Expo 2026",
    tag: "Convention",
    img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=60&h=60&fit=crop&auto=format",
    path: "/events/1",
  },
  {
    type: "Product",
    title: "Levi Ackerman Figure",
    tag: "Merch",
    img: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=60&h=60&fit=crop&auto=format",
    path: "/shop/1",
  },
  {
    type: "Story",
    title: "My first Anime Expo",
    tag: "Anime",
    img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=60&h=60&fit=crop&auto=format",
    path: "/content-detail",
  },
]

const typeColors: Record<string, string> = {
  Article: "#7C5CFF",
  Event: "#4CAF50",
  Product: "#FF9800",
  Story: "#FF6B5C",
}

export default function SearchScreen() {
  const navigate = useNavigate()
  const [query, setQuery] = useState("")

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          padding: "16px 20px",
          display: "flex",
          gap: 10,
          borderBottom: "1px solid var(--border)",
        }}
      >
        <button
          onClick={() => navigate(-1)}
          style={{
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            width: 44,
            height: 44,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            color: "var(--text)",
            flexShrink: 0,
          }}
        >
          <ArrowLeft size={18} />
        </button>
        <div style={{ position: "relative", flex: 1 }}>
          <Search
            size={16}
            color="var(--muted)"
            style={{
              position: "absolute",
              left: 14,
              top: "50%",
              transform: "translateY(-50%)",
            }}
          />
          <input
            className="fv-input"
            placeholder="Search fandoms, events, merch..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            autoFocus
            style={{ paddingLeft: 42, height: 44 }}
          />
        </div>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        {query && (
          <p
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              color: "var(--muted)",
              margin: "0 0 16px",
            }}
          >
            Results for "{query}"
          </p>
        )}
        {results.map((r, i) => (
          <div
            key={i}
            onClick={() => navigate(r.path)}
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
              src={r.img}
              alt={r.title}
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
              <div
                style={{
                  display: "flex",
                  gap: 8,
                  alignItems: "center",
                  marginBottom: 5,
                }}
              >
                <span
                  style={{
                    background: `${typeColors[r.type]}20`,
                    color: typeColors[r.type],
                    fontSize: 11,
                    fontWeight: 700,
                    padding: "2px 7px",
                    borderRadius: 100,
                    fontFamily: "Inter, sans-serif",
                  }}
                >
                  {r.type}
                </span>
                <span className="badge-violet" style={{ fontSize: 10 }}>
                  {r.tag}
                </span>
              </div>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                }}
              >
                {r.title}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}
