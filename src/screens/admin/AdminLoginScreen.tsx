import { useState } from "react"
import { useNavigate } from "react-router-dom"
import { Shield, Eye, EyeOff } from "lucide-react"

export default function AdminLoginScreen() {
  const navigate = useNavigate()
  const [showPass, setShowPass] = useState(false)

  return (
    <div
      style={{
        height: "100%",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        background: "var(--app-bg)",
        padding: "0 28px",
      }}
    >
      <div
        style={{
          width: 64,
          height: 64,
          borderRadius: 18,
          background: "rgba(255,107,92,0.15)",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          marginBottom: 20,
        }}
      >
        <Shield size={32} color="#FF6B5C" />
      </div>

      <h1
        style={{
          fontFamily: "Space Grotesk, sans-serif",
          fontSize: 26,
          fontWeight: 700,
          color: "var(--text)",
          margin: "0 0 6px",
          textAlign: "center",
        }}
      >
        Admin Login
      </h1>
      <p
        style={{
          fontFamily: "Inter, sans-serif",
          fontSize: 14,
          color: "var(--muted)",
          margin: "0 0 32px",
          textAlign: "center",
        }}
      >
        Fandom Verse Administration
      </p>

      <div
        style={{
          width: "100%",
          display: "flex",
          flexDirection: "column",
          gap: 14,
        }}
      >
        <input className="fv-input" type="email" placeholder="Admin email" />
        <div style={{ position: "relative" }}>
          <input
            className="fv-input"
            type={showPass ? "text" : "password"}
            placeholder="Password"
            style={{ paddingRight: 48 }}
          />
          <button
            onClick={() => setShowPass(!showPass)}
            style={{
              position: "absolute",
              right: 14,
              top: "50%",
              transform: "translateY(-50%)",
              background: "none",
              border: "none",
              cursor: "pointer",
              color: "var(--muted)",
              padding: 4,
            }}
          >
            {showPass ? <EyeOff size={18} /> : <Eye size={18} />}
          </button>
        </div>
        <button
          className="btn-primary"
          onClick={() => navigate("/admin/dashboard")}
          style={{ background: "#FF6B5C", marginTop: 4 }}
          onMouseEnter={(e) => (e.currentTarget.style.background = "#E05546")}
          onMouseLeave={(e) => (e.currentTarget.style.background = "#FF6B5C")}
        >
          Log in
        </button>
        <button
          onClick={() => navigate("/select-type")}
          style={{
            background: "none",
            border: "none",
            color: "var(--muted)",
            fontFamily: "Inter, sans-serif",
            fontSize: 13,
            cursor: "pointer",
          }}
        >
          ← Back to user selection
        </button>
      </div>
    </div>
  )
}
