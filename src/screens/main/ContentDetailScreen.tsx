import { useNavigate } from "react-router-dom"
import { ArrowLeft, Bookmark, Share2 } from "lucide-react"

export default function ContentDetailScreen() {
  const navigate = useNavigate()

  return (
    <div
      style={{ height: "100%", background: "var(--app-bg)", overflowY: "auto" }}
    >
      {/* Hero */}
      <div
        style={{
          position: "relative",
          height: 220,
          background: "var(--surface-2)",
          overflow: "hidden",
        }}
      >
        <img
          src="https://images.unsplash.com/photo-1578632767115-351597cf2477?w=390&h=220&fit=crop&auto=format"
          alt="Article"
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
        <div
          style={{
            position: "absolute",
            inset: 0,
            background:
              "linear-gradient(to bottom, rgba(18,18,20,0.4), transparent 30%, var(--app-bg) 100%)",
          }}
        />
        <button
          onClick={() => navigate(-1)}
          style={{
            position: "absolute",
            top: 16,
            left: 16,
            background: "rgba(18,18,20,0.7)",
            backdropFilter: "blur(8px)",
            border: "1px solid rgba(255,255,255,0.1)",
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
        <button
          style={{
            position: "absolute",
            top: 16,
            right: 16,
            background: "rgba(18,18,20,0.7)",
            backdropFilter: "blur(8px)",
            border: "1px solid rgba(255,255,255,0.1)",
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
          <Bookmark size={18} />
        </button>
      </div>

      <div style={{ padding: "20px 20px 60px" }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 10,
            marginBottom: 14,
          }}
        >
          <span className="badge-violet">Anime</span>
          <span
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 12,
              color: "var(--muted)",
            }}
          >
            Sep 24, 2026 · 8 min read
          </span>
        </div>

        <h1
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 22,
            fontWeight: 700,
            color: "var(--text)",
            margin: "0 0 20px",
            lineHeight: 1.3,
          }}
        >
          The Complete Attack on Titan Timeline: Explained
        </h1>

        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 15,
            color: "var(--muted-2)",
            lineHeight: 1.8,
            margin: "0 0 16px",
          }}
        >
          Attack on Titan's story spans thousands of years — from the origin of
          the Titans in ancient Eldia to the final confrontation at Fort Salta.
          Understanding the full timeline requires piecing together fragments
          from multiple flashbacks, unreliable narrators, and the memories
          passed through royal bloodlines.
        </p>

        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 15,
            color: "var(--muted-2)",
            lineHeight: 1.8,
            margin: "0 0 16px",
          }}
        >
          This guide breaks down every major era chronologically, from the
          Founder Ymir's transformation and the ancient Eldian Empire to the
          Rumbling and its aftermath, giving you a clear picture of how the
          present-day events connect to millennia of history.
        </p>

        <div
          style={{
            background: "var(--surface)",
            borderRadius: 12,
            padding: 16,
            border: "1px solid var(--border)",
            marginBottom: 16,
          }}
        >
          <div
            style={{
              fontFamily: "Space Grotesk, sans-serif",
              fontSize: 14,
              fontWeight: 600,
              color: "#7C5CFF",
              marginBottom: 8,
            }}
          >
            Key Era: The Founder Ymir (c. 2,000 years ago)
          </div>
          <p
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
              color: "var(--muted)",
              margin: 0,
              lineHeight: 1.6,
            }}
          >
            A slave girl named Ymir discovers the Source of All Living Matter,
            becoming the first Titan. This single event sets off the chain of
            history that shapes every character 2,000 years later.
          </p>
        </div>

        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 15,
            color: "var(--muted-2)",
            lineHeight: 1.8,
          }}
        >
          The story's brilliance lies in how Isayama retroactively
          recontextualizes every scene from Season 1 — what appeared to be a
          post-apocalyptic survival story was, all along, a tragedy about cycles
          of hatred and the weight of inherited trauma.
        </p>
      </div>
    </div>
  )
}
