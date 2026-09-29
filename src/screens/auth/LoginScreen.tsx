import { useState } from "react"
import { useNavigate } from "react-router-dom"
import { Eye, EyeOff } from "lucide-react"

export default function LoginScreen() {
  const navigate = useNavigate()
  const [showPass, setShowPass] = useState(false)

  return (
    <div
      style={{
        height: "100%",
        overflowY: "auto",
        background: "var(--app-bg)",
        padding: "40px 24px 32px",
      }}
    >
      <div style={{ marginBottom: 32 }}>
        <h1
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 28,
            fontWeight: 700,
            color: "var(--text)",
            margin: "0 0 8px",
          }}
        >
          Welcome back
        </h1>
        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 15,
            color: "var(--muted)",
            margin: 0,
          }}
        >
          Sign in to your Fandom Verse account
        </p>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
        <input className="fv-input" type="email" placeholder="Email address" />

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

        <div style={{ textAlign: "right" }}>
          <button
            onClick={() => navigate("/forgot-password")}
            style={{
              background: "none",
              border: "none",
              color: "#7C5CFF",
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              cursor: "pointer",
            }}
          >
            Forgot password?
          </button>
        </div>

        <button
          className="btn-primary"
          onClick={() => navigate("/select-interests")}
          style={{ marginTop: 4 }}
        >
          Log in
        </button>

        <div className="divider-text" style={{ margin: "8px 0" }}>
          or continue with
        </div>

        <button className="btn-secondary">
          <svg width="18" height="18" viewBox="0 0 48 48">
            <path
              fill="#FFC107"
              d="M43.611 20.083H42V20H24v8h11.303C33.979 32.117 29.446 35 24 35c-6.075 0-11-4.925-11-11s4.925-11 11-11c2.745 0 5.251.988 7.188 2.612l5.657-5.657C33.183 7.387 28.839 5 24 5 12.954 5 4 13.954 4 25s8.954 20 20 20 20-8.954 20-20c0-1.341-.138-2.65-.389-3.917z"
            />
            <path
              fill="#FF3D00"
              d="m6.306 14.691 6.571 4.819C14.655 15.108 18.961 12 24 12c2.745 0 5.251.988 7.188 2.612l5.657-5.657C33.183 6.387 28.839 4 24 4 16.318 4 9.656 8.337 6.306 14.691z"
            />
            <path
              fill="#4CAF50"
              d="M24 44c4.7 0 8.981-1.618 12.319-4.278l-5.961-5.031A12.968 12.968 0 0 1 24 36c-5.419 0-10.035-2.956-12.382-7.297l-6.478 4.989C8.857 39.793 15.906 44 24 44z"
            />
            <path
              fill="#1976D2"
              d="M43.611 20.083H42V20H24v8h11.303a13.047 13.047 0 0 1-4.466 5.691l5.961 5.031C38.908 36.574 44 31.111 44 25c0-1.341-.138-2.65-.389-3.917z"
            />
          </svg>
          Continue with Google
        </button>

        <button className="btn-secondary">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="white">
            <path d="M18.71 19.5c-.83 1.24-1.71 2.45-3.05 2.47-1.34.03-1.77-.79-3.29-.79-1.53 0-2 .77-3.27.82-1.31.05-2.3-1.32-3.14-2.53C4.25 17 2.94 12.45 4.7 9.39c.87-1.52 2.43-2.48 4.12-2.51 1.28-.02 2.5.87 3.29.87.78 0 2.26-1.07 3.8-.91.65.03 2.47.26 3.64 1.98-.09.06-2.17 1.28-2.15 3.81.03 3.02 2.65 4.03 2.68 4.04-.03.07-.42 1.44-1.38 2.83M13 3.5c.73-.83 1.94-1.46 2.94-1.5.13 1.17-.34 2.35-1.04 3.19-.69.85-1.83 1.51-2.95 1.42-.15-1.15.41-2.35 1.05-3.11z" />
          </svg>
          Continue with Apple
        </button>

        <p
          style={{
            textAlign: "center",
            fontFamily: "Inter, sans-serif",
            fontSize: 13,
            color: "var(--muted)",
            margin: "8px 0 0",
          }}
        >
          Don't have an account?{" "}
          <button
            onClick={() => navigate("/register")}
            style={{
              background: "none",
              border: "none",
              color: "#7C5CFF",
              cursor: "pointer",
              fontFamily: "inherit",
              fontSize: "inherit",
            }}
          >
            Create one
          </button>
        </p>
      </div>
    </div>
  )
}
