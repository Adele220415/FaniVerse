import { useNavigate } from "react-router-dom"
import { MapPin, ChevronDown } from "lucide-react"
import BottomTabBar from "../../components/BottomTabBar"

const events = [
  {
    id: 1,
    title: "Anime Expo 2026",
    date: "Jul 4–7, 2026",
    city: "Los Angeles, CA",
    tag: "Anime",
    img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=390&h=180&fit=crop&auto=format",
  },
  {
    id: 2,
    title: "Comic-Con NYC",
    date: "Oct 10–13, 2026",
    city: "New York, NY",
    tag: "Comics",
    img: "https://images.unsplash.com/photo-1612404730960-5c71577fca11?w=390&h=180&fit=crop&auto=format",
  },
  {
    id: 3,
    title: "PAX West 2026",
    date: "Sep 1–4, 2026",
    city: "Seattle, WA",
    tag: "Gaming",
    img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=390&h=180&fit=crop&auto=format",
  },
  {
    id: 4,
    title: "KCON USA 2026",
    date: "Aug 8–10, 2026",
    city: "Los Angeles, CA",
    tag: "K-Pop",
    img: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=390&h=180&fit=crop&auto=format",
  },
  {
    id: 5,
    title: "Star Wars Celebration",
    date: "Apr 18–21, 2027",
    city: "Chicago, IL",
    tag: "Star Wars",
    img: "https://images.unsplash.com/photo-1472457897821-70d3819a0e24?w=390&h=180&fit=crop&auto=format",
  },
]

export default function EventsScreen() {
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
      <div style={{ padding: "20px 20px 16px" }}>
        <h2
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 22,
            fontWeight: 700,
            color: "var(--text)",
            margin: "0 0 14px",
          }}
        >
          Events
        </h2>
        <button
          style={{
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 10,
            padding: "10px 14px",
            display: "flex",
            alignItems: "center",
            gap: 8,
            cursor: "pointer",
            color: "var(--text)",
            fontFamily: "Inter, sans-serif",
            fontSize: 14,
          }}
        >
          <MapPin size={16} color="var(--muted)" />
          All cities
          <ChevronDown
            size={14}
            color="var(--muted)"
            style={{ marginLeft: "auto" }}
          />
        </button>
      </div>

      <div
        style={{
          flex: 1,
          overflowY: "auto",
          padding: "0 20px",
          paddingBottom: 80,
        }}
      >
        {events.map((ev) => (
          <div
            key={ev.id}
            onClick={() => navigate(`/events/${ev.id}`)}
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 16,
              overflow: "hidden",
              marginBottom: 14,
              cursor: "pointer",
              transition: "border-color 0.15s",
            }}
          >
            <div
              style={{
                height: 140,
                background: "var(--surface-2)",
                overflow: "hidden",
                position: "relative",
              }}
            >
              <img
                src={ev.img}
                alt={ev.title}
                style={{ width: "100%", height: "100%", objectFit: "cover" }}
              />
              <div style={{ position: "absolute", top: 12, left: 12 }}>
                <span className="badge-violet">{ev.tag}</span>
              </div>
            </div>
            <div style={{ padding: "14px 16px" }}>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 16,
                  fontWeight: 700,
                  color: "var(--text)",
                  marginBottom: 6,
                }}
              >
                {ev.title}
              </div>
              <div
                style={{
                  display: "flex",
                  gap: 16,
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13,
                  color: "var(--muted)",
                }}
              >
                <span>📅 {ev.date}</span>
                <span>📍 {ev.city}</span>
              </div>
            </div>
          </div>
        ))}
      </div>

      <BottomTabBar />
    </div>
  )
}
