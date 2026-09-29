import { useNavigate } from "react-router-dom"
import {
  Heart,
  Bookmark,
  ShoppingBag,
  WifiOff,
  Settings,
  ChevronRight,
  Edit2,
} from "lucide-react"
import BottomTabBar from "../../components/BottomTabBar"

const menuItems = [
  {
    icon: Heart,
    label: "Liked Fandoms",
    path: "/select-interests",
    color: "#FF6B5C",
  },
  { icon: Bookmark, label: "Bookmarks", path: "/bookmarks", color: "#7C5CFF" },
  {
    icon: ShoppingBag,
    label: "Purchase History",
    path: "/purchase-history",
    color: "#4CAF50",
  },
  {
    icon: WifiOff,
    label: "Offline Content",
    path: "/offline-content",
    color: "#FF9800",
  },
  {
    icon: Settings,
    label: "Settings",
    path: "/settings",
    color: "var(--muted)",
  },
]

export default function ProfileScreen() {
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
          padding: "24px 20px 20px",
          display: "flex",
          alignItems: "flex-start",
          justifyContent: "space-between",
        }}
      >
        <h2
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 22,
            fontWeight: 700,
            color: "var(--text)",
            margin: 0,
          }}
        >
          Profile
        </h2>
        <button
          onClick={() => navigate("/edit-profile")}
          style={{
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            width: 36,
            height: 36,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            color: "var(--text)",
          }}
        >
          <Edit2 size={16} />
        </button>
      </div>

      <div style={{ flex: 1, overflowY: "auto", paddingBottom: 80 }}>
        {/* Avatar block */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 16,
            padding: "0 20px 24px",
          }}
        >
          <div style={{ position: "relative" }}>
            <img
              src="https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=80&h=80&fit=crop&auto=format"
              alt="Alex Rivera"
              style={{
                width: 72,
                height: 72,
                borderRadius: 22,
                objectFit: "cover",
                border: "2px solid #7C5CFF",
              }}
            />
            <div
              style={{
                position: "absolute",
                bottom: -4,
                right: -4,
                background: "var(--app-bg)",
                borderRadius: 10,
                padding: 2,
              }}
            >
              <span style={{ fontSize: 18 }}>⭐</span>
            </div>
          </div>
          <div>
            <h3
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 19,
                fontWeight: 700,
                color: "var(--text)",
                margin: "0 0 3px",
              }}
            >
              Alex Rivera
            </h3>
            <div
              style={{
                display: "flex",
                gap: 8,
                alignItems: "center",
                marginBottom: 6,
              }}
            >
              <span className="badge-violet">Star Fan</span>
            </div>
            <p
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
                margin: 0,
              }}
            >
              Anime · Gaming · Marvel enthusiast
            </p>
          </div>
        </div>

        {/* Stats row */}
        <div
          style={{
            display: "flex",
            padding: "0 20px",
            marginBottom: 24,
            gap: 12,
          }}
        >
          {[
            ["142", "Fandoms"],
            ["38", "Bookmarks"],
            ["12", "Events"],
          ].map(([val, label]) => (
            <div
              key={label}
              style={{
                flex: 1,
                background: "var(--surface)",
                borderRadius: 12,
                padding: "14px 10px",
                textAlign: "center",
                border: "1px solid var(--border)",
              }}
            >
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 20,
                  fontWeight: 700,
                  color: "#7C5CFF",
                }}
              >
                {val}
              </div>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 12,
                  color: "var(--muted)",
                  marginTop: 2,
                }}
              >
                {label}
              </div>
            </div>
          ))}
        </div>

        {/* Menu */}
        <div style={{ padding: "0 20px" }}>
          <div
            style={{
              background: "var(--surface)",
              borderRadius: 16,
              border: "1px solid var(--border)",
              overflow: "hidden",
            }}
          >
            {menuItems.map((item, i) => {
              const Icon = item.icon
              return (
                <button
                  key={item.label}
                  onClick={() => navigate(item.path)}
                  style={{
                    width: "100%",
                    display: "flex",
                    alignItems: "center",
                    gap: 14,
                    padding: "16px 18px",
                    background: "none",
                    border: "none",
                    borderBottom:
                      i < menuItems.length - 1
                        ? "1px solid var(--border)"
                        : "none",
                    cursor: "pointer",
                    textAlign: "left",
                  }}
                >
                  <div
                    style={{
                      width: 36,
                      height: 36,
                      borderRadius: 10,
                      background: `${item.color}18`,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                      flexShrink: 0,
                    }}
                  >
                    <Icon size={18} color={item.color} />
                  </div>
                  <span
                    style={{
                      fontFamily: "Inter, sans-serif",
                      fontSize: 15,
                      color: "var(--text)",
                      flex: 1,
                    }}
                  >
                    {item.label}
                  </span>
                  <ChevronRight size={16} color="var(--muted)" />
                </button>
              )
            })}
          </div>
        </div>
      </div>

      <BottomTabBar />
    </div>
  )
}
