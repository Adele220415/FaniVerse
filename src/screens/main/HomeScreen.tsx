import { useNavigate } from "react-router-dom"
import { Bell, MessageCircle, TrendingUp, BookOpen } from "lucide-react"
import BottomTabBar from "../../components/BottomTabBar"

const trendingFandoms = [
  {
    id: 1,
    name: "Attack on Titan",
    tag: "Anime",
    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&h=130&fit=crop&auto=format",
  },
  {
    id: 2,
    name: "Elden Ring",
    tag: "Gaming",
    img: "https://images.unsplash.com/photo-1636953056323-9c09fdd74fa6?w=200&h=130&fit=crop&auto=format",
  },
  {
    id: 3,
    name: "Marvel Phase 6",
    tag: "Marvel",
    img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=200&h=130&fit=crop&auto=format",
  },
  {
    id: 4,
    name: "The Acolyte",
    tag: "Star Wars",
    img: "https://images.unsplash.com/photo-1472457897821-70d3819a0e24?w=200&h=130&fit=crop&auto=format",
  },
  {
    id: 5,
    name: "BTS Universe",
    tag: "K-Pop",
    img: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=200&h=130&fit=crop&auto=format",
  },
]

export default function HomeScreen() {
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
      {/* Header */}
      <div
        style={{
          padding: "20px 20px 12px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
        }}
      >
        <div>
          <p
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              color: "var(--muted)",
              margin: "0 0 2px",
            }}
          >
            Good evening 👋
          </p>
          <h2
            style={{
              fontFamily: "Space Grotesk, sans-serif",
              fontSize: 20,
              fontWeight: 700,
              color: "var(--text)",
              margin: 0,
            }}
          >
            Alex Rivera
          </h2>
        </div>
        <button
          onClick={() => navigate("/notifications")}
          style={{
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 12,
            width: 40,
            height: 40,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            color: "var(--text)",
            position: "relative",
          }}
        >
          <Bell size={18} />
          <div
            style={{
              position: "absolute",
              top: 8,
              right: 8,
              width: 8,
              height: 8,
              background: "#FF6B5C",
              borderRadius: 4,
              border: "2px solid var(--app-bg)",
            }}
          />
        </button>
      </div>

      {/* Scrollable content */}
      <div style={{ flex: 1, overflowY: "auto", paddingBottom: 80 }}>
        {/* Trending Fandoms */}
        <div style={{ marginBottom: 28 }}>
          <div
            style={{
              padding: "0 20px 12px",
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
            }}
          >
            <h3
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 16,
                fontWeight: 600,
                color: "var(--text)",
                margin: 0,
                display: "flex",
                alignItems: "center",
                gap: 6,
              }}
            >
              <TrendingUp size={16} color="#7C5CFF" /> Trending Fandoms
            </h3>
            <button
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
            {trendingFandoms.map((f) => (
              <div
                key={f.id}
                onClick={() => navigate("/content-detail")}
                style={{
                  flexShrink: 0,
                  width: 160,
                  borderRadius: 12,
                  overflow: "hidden",
                  background: "var(--surface)",
                  cursor: "pointer",
                  border: "1px solid var(--border)",
                }}
              >
                <div
                  style={{
                    height: 100,
                    background: "var(--surface-2)",
                    overflow: "hidden",
                  }}
                >
                  <img
                    src={f.img}
                    alt={f.name}
                    style={{
                      width: "100%",
                      height: "100%",
                      objectFit: "cover",
                    }}
                  />
                </div>
                <div style={{ padding: "10px 12px" }}>
                  <div style={{ marginBottom: 4 }}>
                    <span className="badge-violet">{f.tag}</span>
                  </div>
                  <div
                    style={{
                      fontFamily: "Space Grotesk, sans-serif",
                      fontSize: 13,
                      fontWeight: 600,
                      color: "var(--text)",
                    }}
                  >
                    {f.name}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Quick access cards */}
        <div
          style={{
            padding: "0 20px",
            display: "flex",
            gap: 12,
            marginBottom: 28,
          }}
        >
          <button
            onClick={() => navigate("/explore")}
            style={{
              flex: 1,
              background: "rgba(124,92,255,0.12)",
              border: "1px solid rgba(124,92,255,0.3)",
              borderRadius: 16,
              padding: 20,
              cursor: "pointer",
              textAlign: "left",
            }}
          >
            <BookOpen size={24} color="#7C5CFF" style={{ marginBottom: 10 }} />
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 15,
                fontWeight: 700,
                color: "var(--text)",
                marginBottom: 4,
              }}
            >
              Beginner Fan Hub
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 12,
                color: "var(--muted)",
              }}
            >
              Start your fandom journey
            </div>
          </button>
          <button
            onClick={() => navigate("/deep-dive")}
            style={{
              flex: 1,
              background: "rgba(255,107,92,0.1)",
              border: "1px solid rgba(255,107,92,0.25)",
              borderRadius: 16,
              padding: 20,
              cursor: "pointer",
              textAlign: "left",
            }}
          >
            <TrendingUp
              size={24}
              color="#FF6B5C"
              style={{ marginBottom: 10 }}
            />
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 15,
                fontWeight: 700,
                color: "var(--text)",
                marginBottom: 4,
              }}
            >
              Deep Dive
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 12,
                color: "var(--muted)",
              }}
            >
              Lore & hidden trivia
            </div>
          </button>
        </div>

        {/* Upcoming events teaser */}
        <div style={{ padding: "0 20px", marginBottom: 28 }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              justifyContent: "space-between",
              marginBottom: 12,
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
              Upcoming Events
            </h3>
            <button
              onClick={() => navigate("/events")}
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
          {[
            {
              title: "Anime Expo 2026",
              date: "Jul 4–7",
              city: "Los Angeles",
              img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=60&h=60&fit=crop&auto=format",
            },
            {
              title: "Comic-Con NYC",
              date: "Oct 10–13",
              city: "New York",
              img: "https://images.unsplash.com/photo-1612404730960-5c71577fca11?w=60&h=60&fit=crop&auto=format",
            },
          ].map((ev, i) => (
            <div
              key={i}
              onClick={() => navigate("/events/1")}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 14,
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 12,
                padding: 14,
                marginBottom: 10,
                cursor: "pointer",
              }}
            >
              <img
                src={ev.img}
                alt={ev.title}
                style={{
                  width: 52,
                  height: 52,
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
                  {ev.title}
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 12,
                    color: "var(--muted)",
                  }}
                >
                  {ev.date} · {ev.city}
                </div>
              </div>
              <span className="badge-coral">Soon</span>
            </div>
          ))}
        </div>
      </div>

      {/* FAB */}
      <button
        onClick={() => navigate("/ai-chat")}
        style={{
          position: "absolute",
          bottom: 84,
          right: 20,
          width: 52,
          height: 52,
          background: "#7C5CFF",
          borderRadius: 16,
          border: "none",
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: "0 4px 20px rgba(124,92,255,0.4)",
          zIndex: 40,
        }}
      >
        <MessageCircle size={22} color="white" />
      </button>

      <BottomTabBar />
    </div>
  )
}
