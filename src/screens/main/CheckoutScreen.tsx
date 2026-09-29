import { useNavigate } from "react-router-dom"
import { ArrowLeft } from "lucide-react"

const items = [
  { name: "Levi Ackerman Figure", price: 89.99, qty: 1 },
  { name: "Demon Slayer Cloak", price: 79.99, qty: 2 },
]

export default function CheckoutScreen() {
  const navigate = useNavigate()
  const subtotal = items.reduce((acc, i) => acc + i.price * i.qty, 0)

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
          padding: "20px 20px 16px",
          display: "flex",
          alignItems: "center",
          gap: 14,
          borderBottom: "1px solid var(--border)",
        }}
      >
        <button
          onClick={() => navigate(-1)}
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
          <ArrowLeft size={18} />
        </button>
        <h2
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 18,
            fontWeight: 700,
            color: "var(--text)",
            margin: 0,
          }}
        >
          Checkout
        </h2>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "20px 20px" }}>
        <div
          style={{
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 14,
            overflow: "hidden",
            marginBottom: 16,
          }}
        >
          {items.map((item, i) => (
            <div
              key={i}
              style={{
                display: "flex",
                justifyContent: "space-between",
                padding: "14px 16px",
                borderBottom:
                  i < items.length - 1 ? "1px solid var(--border)" : "none",
              }}
            >
              <div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 14,
                    color: "var(--text)",
                    marginBottom: 2,
                  }}
                >
                  {item.name}
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 12,
                    color: "var(--muted)",
                  }}
                >
                  Qty: {item.qty}
                </div>
              </div>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                }}
              >
                ${(item.price * item.qty).toFixed(2)}
              </div>
            </div>
          ))}
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              padding: "16px",
              background: "var(--surface-2)",
            }}
          >
            <span
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 16,
                fontWeight: 700,
                color: "var(--text)",
              }}
            >
              Total
            </span>
            <span
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 18,
                fontWeight: 700,
                color: "#7C5CFF",
              }}
            >
              ${subtotal.toFixed(2)}
            </span>
          </div>
        </div>

        <div
          style={{
            background: "rgba(255,107,92,0.08)",
            border: "1px solid rgba(255,107,92,0.2)",
            borderRadius: 12,
            padding: 14,
            marginBottom: 24,
          }}
        >
          <p
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              color: "#FF6B5C",
              margin: 0,
              lineHeight: 1.5,
            }}
          >
            ⚡ Simulated checkout — no real payment will be processed.
          </p>
        </div>
      </div>

      <div
        style={{ padding: "16px 20px", borderTop: "1px solid var(--border)" }}
      >
        <button
          className="btn-primary"
          onClick={() => navigate("/order-confirmation")}
        >
          Confirm order
        </button>
      </div>
    </div>
  )
}
