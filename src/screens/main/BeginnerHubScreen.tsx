import { useState } from "react"
import { useNavigate } from "react-router-dom"
import TopBar from "../../components/TopBar"

type Tab = "Profiles" | "Stories" | "Glossary"

const profiles = [
  {
    name: "Attack on Titan",
    desc: "Humanity fights for survival against giant humanoid Titans in a walled world.",
    tag: "Anime",
    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=60&h=60&fit=crop&auto=format",
  },
  {
    name: "Marvel Universe",
    desc: "A vast interconnected universe of superheroes spanning comics, film, and TV.",
    tag: "Marvel",
    img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=60&h=60&fit=crop&auto=format",
  },
  {
    name: "Star Wars Galaxy",
    desc: "An epic space opera following the Force, the Jedi, and the battle for the galaxy.",
    tag: "Star Wars",
    img: "https://images.unsplash.com/photo-1472457897821-70d3819a0e24?w=60&h=60&fit=crop&auto=format",
  },
]

const stories = [
  {
    title: "My first Anime Expo",
    author: "Mika H.",
    tag: "Anime",
    img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=60&h=60&fit=crop&auto=format",
  },
  {
    title: "How I got into comics at 30",
    author: "Jordan T.",
    tag: "Comics",
    img: "https://images.unsplash.com/photo-1612404730960-5c71577fca11?w=60&h=60&fit=crop&auto=format",
  },
]

const glossary = [
  {
    term: "Anime",
    def: "Animation originating from Japan, often hand-drawn and covering a wide range of genres.",
  },
  {
    term: "Canon",
    def: "Story content officially recognized as part of a franchise's continuity.",
  },
  {
    term: "Cosplay",
    def: "Costume play where fans dress as characters from media.",
  },
  {
    term: "Fandom",
    def: "A community of fans united by shared enthusiasm for a work or creator.",
  },
  {
    term: "Lore",
    def: "The background information and world-building details of a fictional universe.",
  },
  {
    term: "Manga",
    def: "Japanese comics and graphic novels, typically read right to left.",
  },
  {
    term: "Ship",
    def: "To support a romantic pairing between two characters.",
  },
]

export default function BeginnerHubScreen() {
  const navigate = useNavigate()
  const [tab, setTab] = useState<Tab>("Profiles")

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title="Beginner Fan Hub" />

      <div
        style={{
          display: "flex",
          gap: 6,
          padding: "12px 20px",
          borderBottom: "1px solid var(--border)",
        }}
      >
        {(["Profiles", "Stories", "Glossary"] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`fv-chip ${tab === t ? "active" : ""}`}
          >
            {t}
          </button>
        ))}
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        {tab === "Profiles" &&
          profiles.map((p, i) => (
            <div
              key={i}
              onClick={() => navigate("/content-detail")}
              style={{
                display: "flex",
                gap: 14,
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 14,
                padding: 14,
                marginBottom: 10,
                cursor: "pointer",
              }}
            >
              <img
                src={p.img}
                alt={p.name}
                style={{
                  width: 52,
                  height: 52,
                  borderRadius: 10,
                  objectFit: "cover",
                  background: "var(--surface-2)",
                  flexShrink: 0,
                }}
              />
              <div>
                <div
                  style={{
                    display: "flex",
                    gap: 8,
                    alignItems: "center",
                    marginBottom: 4,
                  }}
                >
                  <span
                    style={{
                      fontFamily: "Space Grotesk, sans-serif",
                      fontSize: 14,
                      fontWeight: 600,
                      color: "var(--text)",
                    }}
                  >
                    {p.name}
                  </span>
                  <span className="badge-violet" style={{ fontSize: 10 }}>
                    {p.tag}
                  </span>
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 13,
                    color: "var(--muted)",
                    lineHeight: 1.4,
                  }}
                >
                  {p.desc}
                </div>
              </div>
            </div>
          ))}

        {tab === "Stories" &&
          stories.map((s, i) => (
            <div
              key={i}
              onClick={() => navigate("/content-detail")}
              style={{
                display: "flex",
                gap: 14,
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 14,
                padding: 14,
                marginBottom: 10,
                cursor: "pointer",
              }}
            >
              <img
                src={s.img}
                alt={s.title}
                style={{
                  width: 52,
                  height: 52,
                  borderRadius: 10,
                  objectFit: "cover",
                  background: "var(--surface-2)",
                  flexShrink: 0,
                }}
              />
              <div>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 14,
                    fontWeight: 600,
                    color: "var(--text)",
                    marginBottom: 4,
                  }}
                >
                  {s.title}
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 12,
                    color: "var(--muted)",
                  }}
                >
                  by {s.author}
                </div>
              </div>
            </div>
          ))}

        {tab === "Glossary" && (
          <div>
            {glossary.map((item, i) => (
              <div
                key={i}
                style={{
                  borderBottom:
                    i < glossary.length - 1
                      ? "1px solid var(--border)"
                      : "none",
                  padding: "14px 0",
                }}
              >
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 15,
                    fontWeight: 700,
                    color: "#7C5CFF",
                    marginBottom: 4,
                  }}
                >
                  {item.term}
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 14,
                    color: "var(--muted-2)",
                    lineHeight: 1.5,
                  }}
                >
                  {item.def}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}
