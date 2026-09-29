import TopBar from "../../components/TopBar"

const notifications = [
  {
    type: "price",
    icon: "💸",
    title: "Price drop alert",
    body: "Iron Man Helmet Replica dropped to $129.99",
    time: "2 min ago",
    unread: true,
  },
  {
    type: "event",
    icon: "📅",
    title: "New event nearby",
    body: "Anime Fest LA 2026 added in Los Angeles",
    time: "1 hr ago",
    unread: true,
  },
  {
    type: "system",
    icon: "🔔",
    title: "Welcome to Fandom Verse",
    body: "Your profile is ready. Start exploring!",
    time: "Yesterday",
    unread: false,
  },
  {
    type: "event",
    icon: "📅",
    title: "Reminder",
    body: "PAX West is in 7 days — get your tickets!",
    time: "2 days ago",
    unread: false,
  },
  {
    type: "price",
    icon: "💸",
    title: "Price drop alert",
    body: "BTS ARMY Bomb is now $39.99",
    time: "3 days ago",
    unread: false,
  },
]

export default function NotificationsScreen() {
  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title="Notifications" />

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        {notifications.map((n, i) => (
          <div
            key={i}
            style={{
              display: "flex",
              gap: 14,
              padding: "14px 16px",
              background: n.unread ? "rgba(124,92,255,0.07)" : "var(--surface)",
              borderRadius: 14,
              border: `1px solid ${
                n.unread ? "rgba(124,92,255,0.2)" : "var(--border)"
              }`,
              marginBottom: 10,
            }}
          >
            <div
              style={{
                width: 40,
                height: 40,
                borderRadius: 12,
                background: "var(--surface-2)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 20,
                flexShrink: 0,
              }}
            >
              {n.icon}
            </div>
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
                {n.title}
              </div>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13,
                  color: "var(--muted)",
                  marginBottom: 4,
                  lineHeight: 1.4,
                }}
              >
                {n.body}
              </div>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 11,
                  color: "var(--muted-3)",
                }}
              >
                {n.time}
              </div>
            </div>
            {n.unread && (
              <div
                style={{
                  width: 8,
                  height: 8,
                  borderRadius: 4,
                  background: "#7C5CFF",
                  flexShrink: 0,
                  marginTop: 4,
                }}
              />
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
