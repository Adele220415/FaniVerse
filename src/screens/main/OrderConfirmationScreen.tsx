import { useNavigate } from "react-router-dom"
import { CheckCircle2 } from "lucide-react"

export default function OrderConfirmationScreen() {
  const navigate = useNavigate()

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        padding: "0 24px",
        textAlign: "center",
      }}
    >
      <div
        style={{
          width: 80,
          height: 80,
          borderRadius: 24,
          background: "rgba(124,92,255,0.15)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          marginBottom: 20,
        }}
      >
        <CheckCircle2 size={44} color="#7C5CFF" />
      </div>

      <h1
        style={{
          fontFamily: "Space Grotesk, sans-serif",
          fontSize: 26,
          fontWeight: 700,
          color: "var(--text)",
          margin: "0 0 10px",
        }}
      >
        Order confirmed!
      </h1>
      <p
        style={{
          fontFamily: "Inter, sans-serif",
          fontSize: 15,
          color: "var(--muted)",
          margin: "0 0 32px",
          lineHeight: 1.6,
        }}
      >
        Your simulated order has been placed. You'll receive a confirmation
        email shortly.
      </p>

      <div
        style={{
          width: "100%",
          background: "var(--surface)",
          borderRadius: 14,
          padding: 20,
          border: "1px solid var(--border)",
          marginBottom: 28,
          textAlign: "left",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            marginBottom: 10,
          }}
        >
          <span
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              color: "var(--muted)",
            }}
          >
            Order ID
          </span>
          <span
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              fontWeight: 600,
              color: "var(--text)",
            }}
          >
            #FV-20260924-8821
          </span>
        </div>
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            marginBottom: 10,
          }}
        >
          <span
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              color: "var(--muted)",
            }}
          >
            Items
          </span>
          <span
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              fontWeight: 600,
              color: "var(--text)",
            }}
          >
            2 items
          </span>
        </div>
        <div style={{ display: "flex", justifyContent: "space-between" }}>
          <span
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              color: "var(--muted)",
            }}
          >
            Total
          </span>
          <span
            style={{
              fontFamily: "Space Grotesk, sans-serif",
              fontSize: 16,
              fontWeight: 700,
              color: "#7C5CFF",
            }}
          >
            $249.97
          </span>
        </div>
      </div>

      <button className="btn-primary" onClick={() => navigate("/shop")}>
        Back to shop
      </button>
    </div>
  )
}
