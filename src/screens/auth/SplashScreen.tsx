import { useEffect } from "react"
import { useNavigate } from "react-router-dom"

export default function SplashScreen() {
  const navigate = useNavigate()

  useEffect(() => {
    const t = setTimeout(() => navigate("/onboarding"), 2200)
    return () => clearTimeout(t)
  }, [navigate])

  return (
    <div
      style={{
        height: "100%",
        display: "flex",
        flexDirection: "column",
        alignItems: "center",
        justifyContent: "center",
        background: "var(--app-bg)",
        gap: 16,
      }}
    >
      {/* Logo mark */}
      <div style={{ position: "relative", marginBottom: 8 }}>
        <div
          style={{
            width: 80,
            height: 80,
            borderRadius: 22,
            background: "#7C5CFF",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <svg width="44" height="44" viewBox="0 0 44 44" fill="none">
            <path
              d="M22 6L38 16V28L22 38L6 28V16L22 6Z"
              fill="white"
              fillOpacity="0.15"
            />
            <path
              d="M22 10L34 17.5V27.5L22 35L10 27.5V17.5L22 10Z"
              stroke="white"
              strokeWidth="1.5"
              strokeLinejoin="round"
            />
            <circle cx="22" cy="22" r="6" fill="white" />
            <circle cx="22" cy="12" r="2.5" fill="white" fillOpacity="0.7" />
            <circle cx="30.5" cy="27" r="2.5" fill="white" fillOpacity="0.7" />
            <circle cx="13.5" cy="27" r="2.5" fill="white" fillOpacity="0.7" />
          </svg>
        </div>
        {/* Glow */}
        <div
          style={{
            position: "absolute",
            inset: -12,
            borderRadius: 34,
            background:
              "radial-gradient(circle, rgba(124,92,255,0.25) 0%, transparent 70%)",
            pointerEvents: "none",
          }}
        />
      </div>

      <div style={{ textAlign: "center" }}>
        <h1
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 30,
            fontWeight: 700,
            color: "var(--text)",
            margin: 0,
            letterSpacing: "-0.5px",
          }}
        >
          Fandom Verse
        </h1>
        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 14,
            color: "var(--muted)",
            margin: "6px 0 0",
          }}
        >
          Your universe of fandoms
        </p>
      </div>

      {/* Loading dots */}
      <div style={{ display: "flex", gap: 6, marginTop: 32 }}>
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            style={{
              width: 6,
              height: 6,
              borderRadius: 3,
              background: "#7C5CFF",
              animation: `pulse 1.2s ease-in-out ${i * 0.2}s infinite`,
              opacity: 0.6,
            }}
          />
        ))}
      </div>

      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 0.3; transform: scale(0.8); }
          50% { opacity: 1; transform: scale(1); }
        }
      `}</style>
    </div>
  )
}
