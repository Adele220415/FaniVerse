import { useState } from "react"
import { useNavigate } from "react-router-dom"
import { Search } from "lucide-react"
import BottomTabBar from "../../components/BottomTabBar"

const sections = [
  {
    title: "Beginner Fan Hub",
    path: "/beginner-hub",
    items: [
      {
        title: "Intro to Anime",
        tag: "Anime",
        img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=160&h=110&fit=crop&auto=format",
      },
      {
        title: "Marvel 101",
        tag: "Marvel",
        img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=160&h=110&fit=crop&auto=format",
      },
      {
        title: "Gaming Glossary",
        tag: "Gaming",
        img: "https://images.unsplash.com/photo-1636953056323-9c09fdd74fa6?w=160&h=110&fit=crop&auto=format",
      },
    ],
  },
  {
    title: "Resources",
    path: "/resources",
    items: [
      {
        title: "K-Pop Deep Dive",
        tag: "K-Pop",
        img: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=160&h=110&fit=crop&auto=format",
      },
      {
        title: "SW Timeline",
        tag: "Star Wars",
        img: "https://images.unsplash.com/photo-1472457897821-70d3819a0e24?w=160&h=110&fit=crop&auto=format",
      },
      {
        title: "DC Comics Lore",
        tag: "Comics",
        img: "https://images.unsplash.com/photo-1612404730960-5c71577fca11?w=160&h=110&fit=crop&auto=format",
      },
    ],
  },
  {
    title: "Deep Dive",
    path: "/deep-dive",
    items: [
      {
        title: "AoT: Hidden Lore",
        tag: "Anime",
        img: "https://images.unsplash.com/photo-1561731216-c3a4d99437d5?w=160&h=110&fit=crop&auto=format",
      },
      {
        title: "Elden Ring Lore",
        tag: "Gaming",
        img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=160&h=110&fit=crop&auto=format",
      },
      {
        title: "Multiverse Theory",
        tag: "Marvel",
        img: "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=160&h=110&fit=crop&auto=format",
      },
    ],
  },
]

export default function ExploreScreen() {
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
      <div style={{ padding: "20px 20px 0" }}>
        <h2
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 22,
            fontWeight: 700,
            color: "var(--text)",
            margin: "0 0 16px",
          }}
        >
          Explore
        </h2>
        <div style={{ position: "relative", marginBottom: 4 }}>
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
            placeholder="Search fandoms, content, events..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onFocus={() => query === "" && navigate("/search")}
            style={{ paddingLeft: 42 }}
          />
        </div>
      </div>

      <div
        style={{
          flex: 1,
          overflowY: "auto",
          paddingBottom: 80,
          paddingTop: 20,
        }}
      >
        {sections.map((section) => (
          <div key={section.title} style={{ marginBottom: 28 }}>
            <div
              style={{
                padding: "0 20px 12px",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
              }}
            >
              <h3
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 16,
                  fontWeight: 600,
                  color: "var(--text)",
                  margin: 0,
                }}
              >
                {section.title}
              </h3>
              <button
                onClick={() => navigate(section.path)}
                style={{
                  background: "none",
                  border: "none",
                  color: "#7C5CFF",
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13,
                  cursor: "pointer",
                }}
              >
                See all
              </button>
            </div>
            <div
              style={{
                display: "flex",
                gap: 12,
                overflowX: "auto",
                padding: "0 20px",
                scrollbarWidth: "none",
              }}
            >
              {section.items.map((item, i) => (
                <div
                  key={i}
                  onClick={() => navigate("/content-detail")}
                  style={{
                    flexShrink: 0,
                    width: 155,
                    background: "var(--surface)",
                    borderRadius: 12,
                    border: "1px solid var(--border)",
                    overflow: "hidden",
                    cursor: "pointer",
                  }}
                >
                  <div
                    style={{
                      height: 95,
                      background: "var(--surface-2)",
                      overflow: "hidden",
                    }}
                  >
                    <img
                      src={item.img}
                      alt={item.title}
                      style={{
                        width: "100%",
                        height: "100%",
                        objectFit: "cover",
                      }}
                    />
                  </div>
                  <div style={{ padding: "10px 12px" }}>
                    <span
                      className="badge-violet"
                      style={{ marginBottom: 6, display: "inline-block" }}
                    >
                      {item.tag}
                    </span>
                    <div
                      style={{
                        fontFamily: "Space Grotesk, sans-serif",
                        fontSize: 13,
                        fontWeight: 600,
                        color: "var(--text)",
                      }}
                    >
                      {item.title}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        ))}
      </div>

      <BottomTabBar />
    </div>
  )
}
