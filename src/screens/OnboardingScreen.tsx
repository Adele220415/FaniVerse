import { useState } from "react"
import BackButton from "../components/BackButton"

const slides = [
  {
    emoji: "🌌",
    headline: "Your fandoms, all in one place",
    sub: "Anime, gaming, Marvel, K-pop — explore every universe you love.",
    img: "https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=390&h=320&fit=crop&auto=format",
  },
  {
    emoji: "🎟️",
    headline: "Never miss a convention",
    sub: "Events near you, tickets, maps — the fan calendar you always wanted.",
    img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=390&h=320&fit=crop&auto=format",
  },
  {
    emoji: "🛍️",
    headline: "Shop exclusive merch",
    sub: "Limited drops, wishlist tracking, and simulated checkout in seconds.",
    img: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=390&h=320&fit=crop&auto=format",
  },
]

export default function OnboardingScreen({
  onDone,
  onBack,
}: {
  onDone: () => void
  onBack: () => void
}) {
  const [idx, setIdx] = useState(0)
  const slide = slides[idx]

  return (
    <div
      className="flex flex-col flex-1 relative"
      style={{ background: "var(--app-bg)" }}
    >
      <BackButton
        onClick={onBack}
        style={{ position: "absolute", top: 56, left: 24, zIndex: 10 }}
      />
      <button
        onClick={onDone}
        className="absolute top-14 right-6 z-10"
        style={{
          color: "var(--muted)",
          fontSize: 14,
          fontFamily: "Inter",
          background: "none",
          border: "none",
          cursor: "pointer",
        }}
      >
        Skip
      </button>

      <div
        className="flex-shrink-0"
        style={{
          height: 340,
          background: "var(--surface)",
          overflow: "hidden",
          position: "relative",
        }}
      >
        <img
          src={slide.img}
          alt=""
          style={{
            width: "100%",
            height: "100%",
            objectFit: "cover",
            opacity: 0.55,
          }}
        />
        <div
          style={{
            position: "absolute",
            inset: 0,
            background:
              "linear-gradient(to bottom, transparent 40%, var(--app-bg) 100%)",
          }}
        />
        <div
          style={{
            position: "absolute",
            bottom: 24,
            left: 24,
            fontSize: 48,
          }}
        >
          {slide.emoji}
        </div>
      </div>

      <div className="flex flex-col flex-1 px-6 pt-6 pb-10">
        <div className="flex flex-col gap-3 flex-1">
          <h1
            style={{
              fontFamily: "Space Grotesk",
              fontSize: 28,
              fontWeight: 700,
              color: "var(--text)",
              lineHeight: 1.2,
              margin: 0,
            }}
          >
            {slide.headline}
          </h1>
          <p
            style={{
              fontSize: 15,
              color: "var(--muted)",
              lineHeight: 1.6,
              margin: 0,
            }}
          >
            {slide.sub}
          </p>
        </div>

        <div className="flex items-center justify-between mt-6">
          <div className="flex gap-1.5">
            {slides.map((_, i) => (
              <div
                key={i}
                style={{
                  width: i === idx ? 24 : 6,
                  height: 6,
                  borderRadius: 3,
                  background: i === idx ? "#7C5CFF" : "var(--border)",
                  transition: "all 0.3s",
                }}
              />
            ))}
          </div>
          <button
            onClick={() =>
              idx < slides.length - 1 ? setIdx(idx + 1) : onDone()
            }
            style={{
              background: "#7C5CFF",
              color: "#fff",
              fontFamily: "Space Grotesk",
              fontWeight: 600,
              fontSize: 15,
              padding: "12px 28px",
              borderRadius: 8,
              border: "none",
              cursor: "pointer",
            }}
          >
            {idx < slides.length - 1 ? "Next" : "Let's go"}
          </button>
        </div>
      </div>
    </div>
  )
}
