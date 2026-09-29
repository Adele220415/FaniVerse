import { useEffect, useRef, useState, type CSSProperties } from "react"

import CommunityTab from "./CommunityTab"

const categories = ["All", "Anime", "Gaming", "Marvel", "K-Pop", "Sci-Fi"]

const communities = [
  {
    name: "Anime",

    members: "2.1M members",

    color: "#FF6B5C",

    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=120&h=120&fit=crop&auto=format",
  },

  {
    name: "Gaming",

    members: "3.4M members",

    color: "#7C5CFF",

    img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=120&h=120&fit=crop&auto=format",
  },

  {
    name: "Marvel",

    members: "5.2M members",

    color: "#e23636",

    img: "https://images.unsplash.com/photo-1608889335941-32ac5f2041b9?w=120&h=120&fit=crop&auto=format",
  },

  {
    name: "K-Pop",

    members: "1.8M members",

    color: "#FF6B5C",

    img: "https://images.unsplash.com/photo-1571380401583-72ca84994796?w=120&h=120&fit=crop&auto=format",
  },

  {
    name: "Sci-Fi",

    members: "960K members",

    color: "#22c55e",

    img: "https://images.unsplash.com/photo-1446776877081-d282a0f896e2?w=120&h=120&fit=crop&auto=format",
  },

  {
    name: "Star Wars",

    members: "4.1M members",

    color: "#7C5CFF",

    img: "https://images.unsplash.com/photo-1606041008023-472dfb5e530f?w=120&h=120&fit=crop&auto=format",
  },
]

const content = [
  {
    tag: "Anime",

    title: "Attack on Titan: The Final Chapter breakdown",

    type: "Article",

    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&h=140&fit=crop&auto=format",
  },

  {
    tag: "Gaming",

    title: "Shadow of the Erdtree — every secret location",

    type: "Video",

    img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=200&h=140&fit=crop&auto=format",
  },

  {
    tag: "Marvel",

    title: "X-Men 97 series review — nostalgia perfected",

    type: "Article",

    img: "https://images.unsplash.com/photo-1608889335941-32ac5f2041b9?w=200&h=140&fit=crop&auto=format",
  },

  {
    tag: "K-Pop",

    title: "BLACKPINK world tour 2026 dates confirmed",

    type: "News",

    img: "https://images.unsplash.com/photo-1571380401583-72ca84994796?w=200&h=140&fit=crop&auto=format",
  },

  {
    tag: "Sci-Fi",

    title: "Dune: Messiah adaptation — what to expect",

    type: "Podcast",

    img: "https://images.unsplash.com/photo-1446776877081-d282a0f896e2?w=200&h=140&fit=crop&auto=format",
  },

  {
    tag: "Gaming",

    title: "GTA VI character lore deep dive",

    type: "Video",

    img: "https://images.unsplash.com/photo-1493711662062-fa541adb3fc8?w=200&h=140&fit=crop&auto=format",
  },
]

const typeColors: Record<string, string> = {
  Article: "#7C5CFF",

  Video: "#FF6B5C",

  News: "#22c55e",

  Podcast: "#f59e0b",
}

const latestPosts = [
  {
    fandom: "Anime",

    title: "Top 10 must-watch series of 2026",

    time: "2h ago",

    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=64&h=64&fit=crop&auto=format",
  },

  {
    fandom: "Gaming",

    title: "The hidden lore behind Elden Ring's ending",

    time: "4h ago",

    img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=64&h=64&fit=crop&auto=format",
  },

  {
    fandom: "Marvel",

    title: "Every Easter egg in the new Secret Wars trailer",

    time: "6h ago",

    img: "https://images.unsplash.com/photo-1612036782180-6f0b6cd846fe?w=64&h=64&fit=crop&auto=format",
  },
]

const sectionTitle: CSSProperties = {
  fontFamily: "Space Grotesk",

  fontSize: 16,

  fontWeight: 600,

  color: "var(--text)",
}

const avatarStyle = (color: string): CSSProperties => ({
  width: 38,

  height: 38,

  borderRadius: "50%",

  padding: 1.5,

  background: `linear-gradient(45deg, ${color}, #7C5CFF)`,

  flexShrink: 0,
})

const avatarImg: CSSProperties = {
  width: "100%",

  height: "100%",

  borderRadius: "50%",

  objectFit: "cover",

  border: "2px solid var(--surface)",
}

export default function ExploreTab() {
  const [filter, setFilter] = useState("All")

  const [query, setQuery] = useState("")

  const [communityView, setCommunityView] = useState<"explore" | "community">(
    "explore",
  )

  const [targetCommunity, setTargetCommunity] = useState<string | null>(null)

  const [active, setActive] = useState(0)

  const trackRef = useRef<HTMLDivElement>(null)

  const CARD_W = 216

  const GAP = 12

  const filtered = content.filter(
    (c) =>
      (filter === "All" || c.tag === filter) &&
      (!query || c.title.toLowerCase().includes(query.toLowerCase())),
  )

  const goTo = (i: number) => {
    const el = trackRef.current

    if (!el || filtered.length === 0) return

    const idx = Math.min(Math.max(i, 0), filtered.length - 1)

    el.scrollTo({ left: idx * (CARD_W + GAP), behavior: "smooth" })

    setActive(idx)
  }

  const onScroll = () => {
    const el = trackRef.current

    if (!el || filtered.length === 0) return

    const i = Math.round(el.scrollLeft / (CARD_W + GAP))

    setActive(Math.min(Math.max(i, 0), filtered.length - 1))
  }

  useEffect(() => {
    setActive(0)
  }, [filter, query])

  if (communityView === "community") {
    return (
      <CommunityTab
        initialName={targetCommunity}
        onBack={() => setCommunityView("explore")}
      />
    )
  }

  return (
    <div
      className="flex flex-col h-full overflow-y-auto"
      style={{ background: "var(--app-bg)" }}
    >
      <div className="px-5 pt-12 pb-4">
        <h2
          style={{
            fontFamily: "Space Grotesk",

            fontSize: 24,

            fontWeight: 700,

            color: "var(--text)",

            margin: "0 0 12px",
          }}
        >
          Explore
        </h2>
        <div style={{ position: "relative" }}>
          <svg
            style={{
              position: "absolute",

              left: 12,

              top: "50%",

              transform: "translateY(-50%)",
            }}
            width="16"
            height="16"
            viewBox="0 0 24 24"
            fill="none"
            stroke="var(--muted)"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <circle cx="11" cy="11" r="8" />
            <line x1="21" y1="21" x2="16.65" y2="16.65" />
          </svg>
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search fandoms, stories, content…"
            style={{
              width: "100%",

              background: "var(--surface)",

              border: "1.5px solid var(--border)",

              borderRadius: 10,

              padding: "11px 14px 11px 38px",

              color: "var(--text)",

              fontSize: 14,

              fontFamily: "Inter",

              outline: "none",

              boxSizing: "border-box",
            }}
            onFocus={(e) => (e.target.style.borderColor = "#7C5CFF")}
            onBlur={(e) => (e.target.style.borderColor = "var(--border)")}
          />
        </div>
      </div>

      {/* Category filters */}
      <div style={{ marginBottom: 14 }}>
        <div
          className="flex items-center gap-2 px-5 overflow-x-auto"
          style={{
            scrollbarWidth: "none",

            paddingTop: 2,

            paddingBottom: 2,
          }}
        >
          {categories.map((c) => (
            <button
              key={c}
              onClick={() => setFilter(c)}
              style={{
                flexShrink: 0,

                whiteSpace: "nowrap",

                padding: "7px 16px",

                borderRadius: 50,

                border: `1.5px solid ${
                  filter === c ? "#7C5CFF" : "var(--border)"
                }`,

                background:
                  filter === c ? "rgba(124,92,255,0.15)" : "var(--surface)",

                color: filter === c ? "#7C5CFF" : "var(--muted)",

                fontSize: 13,

                fontFamily: "Inter",

                fontWeight: 500,

                cursor: "pointer",

                transition: "all 0.15s",
              }}
            >
              {c}
            </button>
          ))}
        </div>
      </div>

      {/* Trending content — horizontal slide carousel */}
      <div style={{ marginBottom: 6 }}>
        <div className="flex items-center justify-between px-5 mb-3">
          <span style={sectionTitle}>Trending Now</span>
          <div style={{ display: "flex", gap: 6 }}>
            <button
              onClick={() => goTo(active - 1)}
              disabled={active <= 0}
              aria-label="Previous slide"
              style={{
                width: 28,

                height: 28,

                borderRadius: "50%",

                border: "1px solid var(--border)",

                background: "var(--surface)",

                color: active <= 0 ? "var(--border-3)" : "var(--text)",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                cursor: active <= 0 ? "default" : "pointer",

                transition: "all 0.2s",
              }}
            >
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.4"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polyline points="15 18 9 12 15 6" />
              </svg>
            </button>
            <button
              onClick={() => goTo(active + 1)}
              disabled={active >= filtered.length - 1}
              aria-label="Next slide"
              style={{
                width: 28,

                height: 28,

                borderRadius: "50%",

                border: "1px solid var(--border)",

                background: "var(--surface)",

                color:
                  active >= filtered.length - 1
                    ? "var(--border-3)"
                    : "var(--text)",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                cursor: active >= filtered.length - 1 ? "default" : "pointer",

                transition: "all 0.2s",
              }}
            >
              <svg
                width="14"
                height="14"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2.4"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polyline points="9 18 15 12 9 6" />
              </svg>
            </button>
          </div>
        </div>

        {filtered.length === 0 ? (
          <div className="px-5">
            <div
              style={{
                background: "var(--surface)",

                border: "1px dashed var(--border)",

                borderRadius: 12,

                padding: "18px 16px",

                fontSize: 13,

                color: "var(--muted)",

                textAlign: "center",

                lineHeight: 1.5,
              }}
            >
              No trending content matches your filters.
            </div>
          </div>
        ) : (
          <div key={`${filter}|${query}`} className="track-slide">
            <div
              ref={trackRef}
              onScroll={onScroll}
              className="flex gap-3 px-5"
              style={{
                overflowX: "auto",

                scrollSnapType: "x mandatory",

                scrollbarWidth: "none",

                paddingBottom: 2,
              }}
            >
              {filtered.map((c, i) => (
                <div
                  key={c.title}
                  className="card-slide"
                  onClick={() => goTo(i)}
                  style={{
                    animationDelay: `${i * 0.07}s`,

                    flexShrink: 0,

                    width: 216,

                    scrollSnapAlign: "start",

                    background: "var(--surface)",

                    borderRadius: 14,

                    overflow: "hidden",

                    border: `1px solid ${
                      active === i ? "rgba(124,92,255,0.55)" : "var(--border)"
                    }`,

                    boxShadow:
                      active === i
                        ? "0 10px 26px rgba(0,0,0,0.45)"
                        : "0 4px 12px rgba(0,0,0,0.25)",

                    cursor: "pointer",

                    transition:
                      "border-color 0.35s, box-shadow 0.35s, transform 0.35s",

                    transform:
                      active === i ? "translateY(-3px)" : "translateY(0)",
                  }}
                >
                  <div
                    style={{
                      height: 116,

                      background: "var(--surface-2)",

                      overflow: "hidden",
                    }}
                  >
                    <img
                      src={c.img}
                      alt={c.title}
                      style={{
                        width: "100%",

                        height: "100%",

                        objectFit: "cover",

                        transform: active === i ? "scale(1.08)" : "scale(1)",

                        transition:
                          "transform 0.7s cubic-bezier(0.22, 1, 0.36, 1)",
                      }}
                    />
                  </div>
                  <div style={{ padding: "10px 11px 13px" }}>
                    <div style={{ display: "flex", gap: 4, marginBottom: 6 }}>
                      <span
                        style={{
                          fontSize: 10,

                          fontWeight: 600,

                          color: typeColors[c.type] ?? "#7C5CFF",

                          background: "rgba(124,92,255,0.1)",

                          padding: "2px 7px",

                          borderRadius: 4,
                        }}
                      >
                        {c.type}
                      </span>
                      <span
                        style={{
                          fontSize: 10,

                          color: "var(--muted)",

                          background: "var(--surface-2)",

                          padding: "2px 7px",

                          borderRadius: 4,
                        }}
                      >
                        {c.tag}
                      </span>
                    </div>
                    <p
                      style={{
                        fontSize: 13.5,

                        fontWeight: 500,

                        color: "var(--text)",

                        margin: 0,

                        lineHeight: 1.4,

                        display: "-webkit-box",

                        WebkitLineClamp: 3,

                        WebkitBoxOrient: "vertical",

                        overflow: "hidden",
                      }}
                    >
                      {c.title}
                    </p>
                  </div>
                </div>
              ))}
            </div>

            <div
              style={{
                display: "flex",

                justifyContent: "center",

                gap: 6,

                marginTop: 12,
              }}
            >
              {filtered.map((_, i) => (
                <button
                  key={i}
                  onClick={() => goTo(i)}
                  aria-label={`Go to slide ${i + 1}`}
                  style={{
                    height: 6,

                    width: active === i ? 20 : 6,

                    borderRadius: 6,

                    border: "none",

                    padding: 0,

                    background:
                      active === i ? "#7C5CFF" : "var(--border-strong)",

                    cursor: "pointer",

                    transition:
                      "width 0.35s cubic-bezier(0.22, 1, 0.36, 1), background 0.35s",
                  }}
                />
              ))}
            </div>
          </div>
        )}
      </div>

      <div style={{ height: 20 }} />

      {/* Communities prompt */}
      <div className="px-5 pb-4">
        <div
          onClick={() => {
            setTargetCommunity(null)

            setCommunityView("community")
          }}
          style={{
            background: "var(--surface)",

            border: "1px dashed var(--border-3)",

            borderRadius: 12,

            padding: "16px",

            fontSize: 13,

            color: "var(--muted)",

            textAlign: "center",

            lineHeight: 1.5,

            cursor: "pointer",

            transition: "border-color 0.15s",
          }}
          onMouseEnter={(e) => (e.currentTarget.style.borderColor = "#7C5CFF")}
          onMouseLeave={(e) =>
            (e.currentTarget.style.borderColor = "var(--border-3)")
          }
        >
          Tap into the communities to see what's going on.
          <span
            style={{
              display: "block",

              marginTop: 6,

              color: "#7C5CFF",

              fontWeight: 600,

              fontSize: 13,
            }}
          >
            Open Community →
          </span>
        </div>
      </div>

      {/* Latest Posts — disabled (commented out, not removed)
      <div className="px-5 pb-4">
        <span style={sectionTitle}>Latest Posts</span>
        <div className="flex flex-col gap-3 mt-3">
          {latestPosts.map((p) => (
            <div
              key={p.title}
              style={{
                display: "flex",
                gap: 12,
                background: "var(--surface)",
                borderRadius: 12,
                padding: 12,
                cursor: "pointer",
                border: "1px solid var(--border)",
              }}
            >
              <img
                src={p.img}
                alt=""
                style={{
                  width: 52,
                  height: 52,
                  borderRadius: 8,
                  objectFit: "cover",
                  flexShrink: 0,
                }}
              />
              <div className="flex flex-col justify-center gap-1">
                <span
                  style={{
                    display: "inline-block",
                    fontSize: 11,
                    fontWeight: 600,
                    color: "#7C5CFF",
                    background: "rgba(124,92,255,0.12)",
                    padding: "2px 7px",
                    borderRadius: 4,
                    alignSelf: "flex-start",
                  }}
                >
                  {p.fandom}
                </span>
                <span
                  style={{
                    fontSize: 14,
                    fontWeight: 500,
                    color: "var(--text)",
                    lineHeight: 1.35,
                  }}
                >
                  {p.title}
                </span>
                <span style={{ fontSize: 12, color: "var(--muted)" }}>{p.time}</span>
              </div>
            </div>
          ))}
        </div>
      </div>
      */}

      {/* Discover communities */}
      <div className="px-5 pb-4">
        <span style={sectionTitle}>Discover Communities</span>
        <div className="flex flex-col gap-3 mt-3">
          {communities.map((c) => {
            return (
              <div
                key={c.name}
                onClick={() => {
                  setTargetCommunity(c.name)

                  setCommunityView("community")
                }}
                style={{
                  display: "flex",

                  alignItems: "center",

                  gap: 12,

                  background: "var(--surface)",

                  border: "1px solid var(--border)",

                  borderRadius: 12,

                  padding: 12,

                  cursor: "pointer",

                  transition: "border-color 0.15s",
                }}
                onMouseEnter={(e) =>
                  (e.currentTarget.style.borderColor = "#7C5CFF")
                }
                onMouseLeave={(e) =>
                  (e.currentTarget.style.borderColor = "var(--border)")
                }
              >
                <div style={{ ...avatarStyle(c.color), width: 44, height: 44 }}>
                  <img src={c.img} alt={c.name} style={avatarImg} />
                </div>
                <div className="flex flex-col" style={{ flex: 1, minWidth: 0 }}>
                  <span
                    style={{
                      fontSize: 14,

                      fontWeight: 600,

                      color: "var(--text)",
                    }}
                  >
                    {c.name}
                  </span>
                  <span style={{ fontSize: 12, color: "var(--muted)" }}>
                    {c.members}
                  </span>
                </div>
                <svg
                  width="16"
                  height="16"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="var(--muted)"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  style={{ flexShrink: 0 }}
                >
                  <path d="M9 18l6-6-6-6" />
                </svg>
              </div>
            )
          })}
        </div>
      </div>

      <div style={{ height: 24 }} />
    </div>
  )
}
