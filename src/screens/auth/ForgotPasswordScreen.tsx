import { useNavigate } from "react-router-dom"
import { ArrowLeft, Mail } from "lucide-react"

export default function ForgotPasswordScreen() {
  const navigate = useNavigate()

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        padding: "20px 24px",
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
          marginBottom: 32,
        }}
      >
        <ArrowLeft size={18} />
      </button>

      <div
        style={{
          width: 56,
          height: 56,
          borderRadius: 16,
          background: "rgba(124,92,255,0.15)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          marginBottom: 20,
        }}
      >
        <Mail size={28} color="#7C5CFF" />
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
        Reset password
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
        Enter your email and we'll send you a link to reset your password.
      </p>

      <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
        <input className="fv-input" type="email" placeholder="Email address" />
        <button className="btn-primary" onClick={() => navigate("/login")}>
          Send reset link
        </button>
      </div>
    </div>
  )
}
