import { useNavigate } from "react-router-dom"
import { ChevronRight } from "lucide-react"
import TopBar from "../../components/TopBar"

const orders = [
  { id: "#FV-20260924-8821", date: "Sep 24, 2026", items: 2, total: 249.97 },
  { id: "#FV-20260901-5410", date: "Sep 1, 2026", items: 1, total: 89.99 },
  { id: "#FV-20260815-2293", date: "Aug 15, 2026", items: 3, total: 318.97 },
]

export default function PurchaseHistoryScreen() {
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
      <TopBar title="Purchase History" />

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        {orders.map((order, i) => (
          <button
            key={i}
            onClick={() => navigate("/order-confirmation")}
            style={{
              width: "100%",
              display: "flex",
              alignItems: "center",
              gap: 14,
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              padding: 16,
              marginBottom: 10,
              cursor: "pointer",
              textAlign: "left",
            }}
          >
            <div style={{ flex: 1 }}>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 700,
                  color: "#7C5CFF",
                  marginBottom: 4,
                }}
              >
                {order.id}
              </div>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13,
                  color: "var(--muted)",
                  marginBottom: 4,
                }}
              >
                {order.date} · {order.items} item{order.items > 1 ? "s" : ""}
              </div>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 16,
                  fontWeight: 700,
                  color: "var(--text)",
                }}
              >
                ${order.total.toFixed(2)}
              </div>
            </div>
            <ChevronRight size={18} color="var(--muted)" />
          </button>
        ))}
      </div>
    </div>
  )
}
