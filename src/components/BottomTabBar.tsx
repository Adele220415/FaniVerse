import { useNavigate, useLocation } from "react-router-dom"
import { Home, Compass, CalendarDays, ShoppingBag, User } from "lucide-react"

const tabs = [
  { icon: Home, label: "Home", path: "/home" },
  { icon: Compass, label: "Explore", path: "/explore" },
  { icon: CalendarDays, label: "Events", path: "/events" },
  { icon: ShoppingBag, label: "Shop", path: "/shop" },
  { icon: User, label: "Profile", path: "/profile" },
]

export default function BottomTabBar() {
  const navigate = useNavigate()
  const location = useLocation()

  return (
    <div
      style={{
        position: "absolute",
        bottom: 0,
        left: 0,
        right: 0,
        height: 72,
        background: "var(--surface)",
        borderTop: "1px solid var(--border)",
        display: "flex",
        alignItems: "center",
        justifyContent: "space-around",
        paddingBottom: 8,
        zIndex: 50,
      }}
    >
      {tabs.map((tab) => {
        const active = location.pathname.startsWith(tab.path)
        const Icon = tab.icon
        return (
          <button
            key={tab.path}
            onClick={() => navigate(tab.path)}
            style={{
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 4,
              background: "none",
              border: "none",
              cursor: "pointer",
              padding: "6px 12px",
              color: active ? "#7C5CFF" : "var(--muted)",
              transition: "color 0.15s",
            }}
          >
            <Icon size={22} strokeWidth={active ? 2.2 : 1.8} />
            <span
              style={{
                fontSize: 10,
                fontFamily: "Inter, sans-serif",
                fontWeight: active ? 600 : 400,
              }}
            >
              {tab.label}
            </span>
          </button>
        )
      })}
    </div>
  )
}
