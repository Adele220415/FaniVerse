import { useState } from "react"
import { useNavigate } from "react-router-dom"
import { ChevronRight } from "lucide-react"

const slides = [
  {
    emoji: "🌌",
    title: "Dive into your fandoms",
    subtitle:
      "Discover content, lore, and community across every universe you love.",
    color: "#7C5CFF",
    img: "https://images.unsplash.com/photo-1636953056323-9c09fdd74fa6?w=390&h=320&fit=crop&auto=format",
    imgAlt: "Colorful galaxy nebula illustration",
  },
  {
    emoji: "⚡",
    title: "Events near you",
    subtitle:
      "Find conventions, screenings, and fan meetups happening in your city.",
    color: "#FF6B5C",
    img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=390&h=320&fit=crop&auto=format",
    imgAlt: "Convention crowd with lights",
  },
  {
    emoji: "🛍️",
    title: "Shop exclusive merch",
    subtitle:
      "Browse curated collectibles, apparel, and limited editions from your favorite franchises.",
    color: "#7C5CFF",
    img: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=390&h=320&fit=crop&auto=format",
    imgAlt: "Collectible merchandise on shelf",
  },
]

export default function OnboardingScreen() {
  const [current, setCurrent] = useState(0)
  const navigate = useNavigate()

  const next = () => {
    if (current < slides.length - 1) setCurrent(current + 1)
    else navigate("/select-type")
  }

  const slide = slides[current]

  return (
    <div
      style={{
        height: "100%",
        display: "flex",
        flexDirection: "column",
        background: "var(--app-bg)",
        position: "relative",
      }}
    >
      {/* Skip */}
      <div
        style={{
          padding: "16px 20px",
          display: "flex",
          justifyContent: "flex-end",
        }}
      >
        <button
          onClick={() => navigate("/select-type")}
          style={{
            background: "none",
            border: "none",
            color: "var(--muted)",
            fontFamily: "Inter, sans-serif",
            fontSize: 14,
            cursor: "pointer",
          }}
        >
          Skip
        </button>
      </div>

      {/* Illustration */}
      <div
        style={{
          flex: 1,
          margin: "0 20px",
          borderRadius: 20,
          overflow: "hidden",
          background: "var(--surface)",
          position: "relative",
        }}
      >
        <img
          src={slide.img}
          alt={slide.imgAlt}
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
        <div
          style={{
            position: "absolute",
            inset: 0,
            background:
              "linear-gradient(to bottom, transparent 40%, var(--app-bg) 100%)",
          }}
        />
        {/* Emoji badge */}
        <div
          style={{
            position: "absolute",
            top: 20,
            left: 20,
            background: "rgba(18,18,20,0.7)",
            backdropFilter: "blur(8px)",
            borderRadius: 14,
            padding: "8px 14px",
            fontSize: 28,
          }}
        >
          {slide.emoji}
        </div>
      </div>

      {/* Content */}
      <div style={{ padding: "24px 24px 32px" }}>
        <h1
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 26,
            fontWeight: 700,
            color: "var(--text)",
            margin: "0 0 10px",
            letterSpacing: "-0.4px",
          }}
        >
          {slide.title}
        </h1>
        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 15,
            color: "var(--muted)",
            margin: "0 0 28px",
            lineHeight: 1.6,
          }}
        >
          {slide.subtitle}
        </p>

        {/* Dots */}
        <div style={{ display: "flex", gap: 6, marginBottom: 24 }}>
          {slides.map((_, i) => (
            <div
              key={i}
              style={{
                height: 4,
                borderRadius: 2,
                background: i === current ? "#7C5CFF" : "var(--border)",
                width: i === current ? 24 : 8,
                transition: "all 0.25s",
              }}
            />
          ))}
        </div>

        <button
          className="btn-primary"
          onClick={next}
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
          }}
        >
          {current < slides.length - 1 ? "Next" : "Get started"}
          <ChevronRight size={18} />
        </button>
      </div>
    </div>
  )
}
