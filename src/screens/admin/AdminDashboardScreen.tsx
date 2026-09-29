import { useNavigate } from "react-router-dom"
import {
  Users,
  CalendarDays,
  ShoppingBag,
  FileText,
  Tag,
  ChevronRight,
  Shield,
} from "lucide-react"

const stats = [
  { label: "Total Users", value: "14,382", icon: Users, color: "#7C5CFF" },
  { label: "Events", value: "47", icon: CalendarDays, color: "#4CAF50" },
  { label: "Products", value: "218", icon: ShoppingBag, color: "#FF9800" },
  { label: "Content Items", value: "1,204", icon: FileText, color: "#FF6B5C" },
]

const navItems = [
  { label: "Manage Content", path: "/admin/content", icon: FileText },
  { label: "Manage Events", path: "/admin/events", icon: CalendarDays },
  {
    label: "Manage Merchandise",
    path: "/admin/merchandise",
    icon: ShoppingBag,
  },
  { label: "Manage Users", path: "/admin/users", icon: Users },
  { label: "Manage Categories", path: "/admin/categories", icon: Tag },
]

export default function AdminDashboardScreen() {
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
          padding: "20px 20px 16px",
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          borderBottom: "1px solid var(--border)",
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div
            style={{
              width: 34,
              height: 34,
              borderRadius: 10,
              background: "rgba(255,107,92,0.15)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Shield size={18} color="#FF6B5C" />
          </div>
          <div>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 16,
                fontWeight: 700,
                color: "var(--text)",
              }}
            >
              Admin Panel
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 12,
                color: "var(--muted)",
              }}
            >
              Fandom Verse
            </div>
          </div>
        </div>
        <button
          onClick={() => navigate("/select-type")}
          style={{
            background: "none",
            border: "none",
            color: "#FF6B5C",
            fontFamily: "Inter, sans-serif",
            fontSize: 13,
            cursor: "pointer",
          }}
        >
          Log out
        </button>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "20px 20px" }}>
        {/* Stats grid */}
        <div
          style={{
            display: "grid",
            gridTemplateColumns: "1fr 1fr",
            gap: 12,
            marginBottom: 24,
          }}
        >
          {stats.map((stat) => {
            const Icon = stat.icon
            return (
              <div
                key={stat.label}
                style={{
                  background: "var(--surface)",
                  border: "1px solid var(--border)",
                  borderRadius: 14,
                  padding: "16px 14px",
                }}
              >
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    marginBottom: 10,
                  }}
                >
                  <div
                    style={{
                      width: 30,
                      height: 30,
                      borderRadius: 8,
                      background: `${stat.color}18`,
                      display: "flex",
                      alignItems: "center",
                      justifyContent: "center",
                    }}
                  >
                    <Icon size={16} color={stat.color} />
                  </div>
                </div>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 22,
                    fontWeight: 700,
                    color: stat.color,
                    marginBottom: 3,
                  }}
                >
                  {stat.value}
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 12,
                    color: "var(--muted)",
                  }}
                >
                  {stat.label}
                </div>
              </div>
            )
          })}
        </div>

        {/* Nav links */}
        <div
          style={{
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 16,
            overflow: "hidden",
          }}
        >
          {navItems.map((item, i) => {
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
                  padding: "15px 18px",
                  background: "none",
                  border: "none",
                  borderBottom:
                    i < navItems.length - 1
                      ? "1px solid var(--border)"
                      : "none",
                  cursor: "pointer",
                  textAlign: "left",
                }}
              >
                <Icon size={18} color="var(--muted)" />
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
  )
}
