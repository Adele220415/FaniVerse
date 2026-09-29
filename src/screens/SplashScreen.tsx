import { useEffect } from "react"

export default function SplashScreen({ onDone }: { onDone: () => void }) {
  useEffect(() => {
    const t = setTimeout(onDone, 2000)
    return () => clearTimeout(t)
  }, [onDone])

  return (
    <div
      className="flex flex-col items-center justify-center flex-1"
      style={{ background: "var(--app-bg)" }}
    >
      <div className="flex flex-col items-center gap-4">
        <div
          className="flex items-center justify-center"
          style={{
            width: 80,
            height: 80,
            background: "#7C5CFF",
            borderRadius: 24,
          }}
        >
          <svg width="44" height="44" viewBox="0 0 44 44" fill="none">
            <path
              d="M22 6L8 14V30L22 38L36 30V14L22 6Z"
              stroke="white"
              strokeWidth="2.5"
              strokeLinejoin="round"
            />
            <circle cx="22" cy="22" r="6" fill="white" />
            <path
              d="M22 16V12M22 32V28M14 22H10M34 22H30"
              stroke="white"
              strokeWidth="2"
              strokeLinecap="round"
            />
          </svg>
        </div>
        <div className="flex flex-col items-center gap-1">
          <span
            style={{
              fontFamily: "Space Grotesk",
              fontSize: 28,
              fontWeight: 700,
              color: "var(--text)",
              letterSpacing: "-0.5px",
            }}
          >
            Fandom Verse
          </span>
          <span style={{ fontSize: 14, color: "var(--muted)" }}>
            Your universe. Your community.
          </span>
        </div>
      </div>
      <div className="absolute bottom-16 flex gap-1.5">
        {[0, 1, 2].map((i) => (
          <div
            key={i}
            style={{
              width: i === 0 ? 24 : 6,
              height: 6,
              borderRadius: 3,
              background: i === 0 ? "#7C5CFF" : "var(--border)",
              transition: "all 0.3s",
            }}
          />
        ))}
      </div>
    </div>
  )
}
