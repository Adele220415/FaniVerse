import { useEffect, useState } from "react"

import SettingsScreen from "../main/SettingsScreen"
import type { ResourcePage } from "../general/ResourceScreen"

type View = "main" | "edit" | "settings"

const u = (id: string, w: number, h: number) =>
  `https://images.unsplash.com/${id}?w=${w}&h=${h}&fit=crop&auto=format`

const A = {
  me: "photo-1519345182560-3f2917c472ef",

  yuki: "photo-1544005313-94ddf0286df2",

  sana: "photo-1438761681033-6461ffad8d80",

  mia: "photo-1494790108377-be9c29b29330",

  kenji: "photo-1500648767791-00dcc994a43e",

  diego: "photo-1507003211169-0a1dd7228f2d",

  leo: "photo-1519345182560-3f2917c472ef",
}

type Suggestion = {
  id: string

  name: string

  handle: string

  avatar: string

  mutuals: string[]
}

const suggestions: Suggestion[] = [
  {
    id: "yuki",

    name: "Yuki Tanaka",

    handle: "yukicore",

    avatar: A.yuki,

    mutuals: [A.mia, A.leo],
  },

  {
    id: "sana",

    name: "Sana Ito",

    handle: "sanaverse",

    avatar: A.sana,

    mutuals: [A.kenji, A.diego],
  },

  {
    id: "diego",

    name: "Diego Ramos",

    handle: "diegoplays",

    avatar: A.diego,

    mutuals: [A.yuki, A.mia],
  },
]

const posts = [
  {
    id: "p1",

    time: "2h",

    text: "Finally cleared the new raid — that final boss fight was unreal. Who's down for a run tonight?",

    photo: "photo-1542751371-adc38448a05e",

    likes: 128,

    replies: 14,

    reposts: 6,
  },

  {
    id: "p2",

    time: "5h",

    text: "Ranking every superhero movie ending, part 2 drops tomorrow 👀",

    likes: 74,

    replies: 9,

    reposts: 3,
  },
]

const tabs = ["Posts", "Replies", "Media", "Reposts"] as const

type Tab = typeof tabs[number]

function VerifiedBadge({ size = 16 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path
        d="M12 1.5l2.38 2.1 3.2-.42 1.1 3.03 3.03 1.1-.42 3.2L23.5 12l-2.1 2.38.42 3.2-3.03 1.1-1.1 3.03-3.2-.42L12 22.5l-2.38-2.1-3.2.42-1.1-3.03-3.03-1.1.42-3.2L.5 12l2.1-2.38-.42-3.2 3.03-1.1 1.1-3.03 3.2.42L12 1.5z"
        fill="#1D9BF0"
      />
      <path
        d="M7.5 12.2l3 3 6-6.4"
        stroke="#fff"
        strokeWidth="2"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  )
}

function ActionIcons({
  replies,

  likes,

  reposts,
}: {
  replies: number

  likes: number

  reposts: number
}) {
  const item = (path: React.ReactNode, n?: number) => (
    <span
      style={{
        display: "flex",

        alignItems: "center",

        gap: 5,

        color: "var(--muted)",

        fontSize: 13,
      }}
    >
      <svg
        width="17"
        height="17"
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        {path}
      </svg>
      {n !== undefined ? n : null}
    </span>
  )

  return (
    <div style={{ display: "flex", gap: 18, marginTop: 12 }}>
      {item(
        <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" />,

        replies,
      )}
      {item(
        <path d="M20.8 4.6a5.5 5.5 0 00-7.8 0L12 5.7l-1-1.1a5.5 5.5 0 00-7.8 7.8l1 1.1L12 21.2l7.8-7.7 1-1.1a5.5 5.5 0 000-7.8z" />,

        likes,
      )}
      {item(
        <>
          <path d="M17 1l4 4-4 4" />
          <path d="M3 21v-4a4 4 0 014-4h14" />
          <path d="M7 23l-4-4 4-4" />
        </>,

        reposts,
      )}
      <span style={{ marginLeft: "auto" }}>
        {item(<path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z" />)}
      </span>
    </div>
  )
}

export default function ProfileTab({
  openSettings,

  onSettingsOpened,

  onOpenResource,
}: {
  openSettings?: boolean

  onSettingsOpened?: () => void

  onOpenResource?: (page: ResourcePage) => void
}) {
  const [view, setView] = useState<View>("main")

  const [name, setName] = useState("Alex Kim")

  const [bio, setBio] = useState(
    "Anime fanatic & gaming enthusiast. Collector of rare merch and hidden lore.",
  )

  const [tab, setTab] = useState<Tab>("Posts")

  const [dismissed, setDismissed] = useState<string[]>([])

  const [following, setFollowing] = useState<string[]>([])

  useEffect(() => {
    if (openSettings) {
      setView("settings")

      onSettingsOpened?.()
    }
  }, [openSettings])

  if (view === "settings") {
    return (
      <SettingsScreen
        onBack={() => setView("main")}
        onOpenResource={onOpenResource}
      />
    )
  }

  if (view === "edit") {
    const interests = ["Anime", "Gaming", "Marvel", "K-Pop", "Star Wars"]

    const [sel, setSel] = useState(new Set(["Anime", "Gaming"]))

    const toggle = (i: string) =>
      setSel((s) => {
        const n = new Set(s)

        n.has(i) ? n.delete(i) : n.add(i)

        return n
      })

    return (
      <div
        className="flex flex-col h-full overflow-y-auto px-5"
        style={{ background: "var(--app-bg)" }}
      >
        <div className="flex items-center gap-3 pt-12 pb-6">
          <button
            onClick={() => setView("main")}
            style={{
              background: "none",

              border: "none",

              color: "var(--muted)",

              cursor: "pointer",
            }}
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M19 12H5M12 5l-7 7 7 7" />
            </svg>
          </button>
          <h2
            style={{
              fontFamily: "Space Grotesk",

              fontSize: 20,

              fontWeight: 700,

              color: "var(--text)",

              margin: 0,
            }}
          >
            Edit Profile
          </h2>
        </div>

        <div className="flex flex-col items-center mb-6">
          <div
            style={{
              width: 80,

              height: 80,

              borderRadius: "50%",

              background: "#7C5CFF",

              display: "flex",

              alignItems: "center",

              justifyContent: "center",

              fontSize: 32,

              position: "relative",

              cursor: "pointer",
            }}
          >
            🧑‍🚀
            <div
              style={{
                position: "absolute",

                bottom: 0,

                right: 0,

                width: 24,

                height: 24,

                borderRadius: "50%",

                background: "var(--text)",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                fontSize: 12,
              }}
            >
              📷
            </div>
          </div>
        </div>

        <div className="flex flex-col gap-4">
          <div className="flex flex-col gap-1.5">
            <label
              style={{ fontSize: 13, fontWeight: 500, color: "var(--muted)" }}
            >
              Name
            </label>
            <input
              value={name}
              onChange={(e) => setName(e.target.value)}
              style={{
                background: "var(--surface)",

                border: "1.5px solid var(--border)",

                borderRadius: 8,

                padding: "12px 14px",

                color: "var(--text)",

                fontSize: 15,

                fontFamily: "Inter",

                outline: "none",
              }}
              onFocus={(e) => (e.target.style.borderColor = "#7C5CFF")}
              onBlur={(e) => (e.target.style.borderColor = "var(--border)")}
            />
          </div>
          <div className="flex flex-col gap-1.5">
            <label
              style={{ fontSize: 13, fontWeight: 500, color: "var(--muted)" }}
            >
              Bio
            </label>
            <textarea
              value={bio}
              onChange={(e) => setBio(e.target.value)}
              rows={3}
              style={{
                background: "var(--surface)",

                border: "1.5px solid var(--border)",

                borderRadius: 8,

                padding: "12px 14px",

                color: "var(--text)",

                fontSize: 15,

                fontFamily: "Inter",

                outline: "none",

                resize: "none",
              }}
              onFocus={(e) => (e.target.style.borderColor = "#7C5CFF")}
              onBlur={(e) => (e.target.style.borderColor = "var(--border)")}
            />
          </div>
          <div className="flex flex-col gap-2">
            <label
              style={{ fontSize: 13, fontWeight: 500, color: "var(--muted)" }}
            >
              Fandom interests
            </label>
            <div className="flex flex-wrap gap-2">
              {interests.map((i) => (
                <button
                  key={i}
                  onClick={() => toggle(i)}
                  style={{
                    padding: "7px 14px",

                    borderRadius: 50,

                    border: `1.5px solid ${
                      sel.has(i) ? "#7C5CFF" : "var(--border)"
                    }`,

                    background: sel.has(i)
                      ? "rgba(124,92,255,0.15)"
                      : "var(--surface)",

                    color: sel.has(i) ? "#7C5CFF" : "var(--muted)",

                    fontSize: 13,

                    cursor: "pointer",

                    fontFamily: "Inter",
                  }}
                >
                  {i}
                </button>
              ))}
            </div>
          </div>
          <button
            onClick={() => setView("main")}
            style={{
              background: "#7C5CFF",

              color: "#fff",

              fontFamily: "Space Grotesk",

              fontWeight: 600,

              fontSize: 16,

              padding: "14px",

              borderRadius: 8,

              border: "none",

              cursor: "pointer",

              marginTop: 8,
            }}
          >
            Save changes
          </button>
        </div>
      </div>
    )
  }

  const visible = suggestions.filter((s) => !dismissed.includes(s.id))

  const circleBtn = (
    label: string,

    onClick: () => void,

    icon: React.ReactNode,

    size = 38,
  ) => (
    <button
      key={label}
      aria-label={label}
      onClick={onClick}
      style={{
        width: size,

        height: size,

        borderRadius: 10,

        background: "transparent",

        border: "none",

        display: "flex",

        alignItems: "center",

        justifyContent: "center",

        cursor: "pointer",

        color: "var(--text)",
      }}
    >
      {icon}
    </button>
  )

  return (
    <div
      className="flex flex-col h-full overflow-y-auto"
      style={{ background: "var(--app-bg)" }}
    >
      <div
        className="flex items-center justify-end px-4 pt-10 pb-1"
        style={{
          position: "sticky",

          top: 0,

          background: "var(--app-bg)",

          zIndex: 5,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 2 }}>
          {circleBtn(
            "Insights",

            () => {},

            <svg
              width="21"
              height="21"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.9"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <rect x="3" y="3" width="18" height="18" rx="5" />
              <path d="M8 16v-4M12 16V8M16 16v-6" />
            </svg>,
          )}
          {circleBtn(
            "Settings",

            () => setView("settings"),

            <svg
              width="21"
              height="21"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.7"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <circle cx="12" cy="12" r="3" />
              <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 01-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z" />
            </svg>,
          )}
        </div>
      </div>

      <div className="px-5 pt-3">
        <div
          style={{
            display: "flex",

            alignItems: "flex-start",

            justifyContent: "space-between",

            gap: 16,
          }}
        >
          <div style={{ minWidth: 0 }}>
            <h1
              style={{
                fontFamily: "Space Grotesk",

                fontSize: 26,

                fontWeight: 700,

                color: "var(--text)",

                margin: 0,

                letterSpacing: "-0.01em",
              }}
            >
              {name}
            </h1>
            <div
              style={{
                fontSize: 16,

                color: "var(--text)",

                marginTop: 6,

                fontFamily: "Inter",
              }}
            >
              alexkim
            </div>
          </div>

          <div style={{ position: "relative", flexShrink: 0 }}>
            <img
              src={u(A.me, 160, 160)}
              alt="Alex Kim"
              style={{
                width: 72,

                height: 72,

                borderRadius: "50%",

                objectFit: "cover",

                display: "block",
              }}
            />
            <div
              style={{
                position: "absolute",

                left: -10,

                bottom: 2,

                width: 30,

                height: 30,

                borderRadius: "50%",

                background: "var(--app-bg)",

                border: "2px dashed var(--muted)",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                color: "var(--text)",

                cursor: "pointer",
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
              >
                <line x1="12" y1="5" x2="12" y2="19" />
                <line x1="5" y1="12" x2="19" y2="12" />
              </svg>
            </div>
          </div>
        </div>

        <button
          style={{
            marginTop: 16,

            padding: "8px 16px",

            borderRadius: 999,

            border: "1px solid var(--border)",

            background: "transparent",

            color: "var(--muted)",

            fontSize: 13.5,

            fontFamily: "Inter",

            cursor: "pointer",
          }}
        >
          + Add interests
        </button>

        <div
          style={{
            display: "flex",

            alignItems: "center",

            gap: 8,

            marginTop: 20,
          }}
        >
          <div style={{ display: "flex" }}>
            {[A.mia, A.kenji].map((a, i) => (
              <img
                key={a}
                src={u(a, 48, 48)}
                alt=""
                style={{
                  width: 22,

                  height: 22,

                  borderRadius: "50%",

                  objectFit: "cover",

                  border: "2px solid var(--app-bg)",

                  marginLeft: i === 0 ? 0 : -8,

                  position: "relative",

                  zIndex: i === 0 ? 2 : 1,
                }}
              />
            ))}
          </div>
          <span
            style={{ fontSize: 15, color: "var(--muted)", fontFamily: "Inter" }}
          >
            6 followers
          </span>
        </div>

        <div style={{ display: "flex", gap: 10, marginTop: 20 }}>
          <button
            onClick={() => setView("edit")}
            style={{
              flex: 1,

              height: 44,

              borderRadius: 10,

              border: "1px solid var(--border-strong)",

              background: "transparent",

              color: "var(--text)",

              fontSize: 15,

              fontWeight: 500,

              fontFamily: "Inter",

              cursor: "pointer",
            }}
          >
            Edit profile
          </button>
          <button
            style={{
              flex: 1,

              height: 44,

              borderRadius: 10,

              border: "1px solid var(--border-strong)",

              background: "transparent",

              color: "var(--text)",

              fontSize: 15,

              fontWeight: 500,

              fontFamily: "Inter",

              cursor: "pointer",
            }}
          >
            View insights
          </button>
          <button
            aria-label="Share"
            style={{
              width: 44,

              height: 44,

              flexShrink: 0,

              borderRadius: 10,

              border: "1px solid var(--border-strong)",

              background: "transparent",

              display: "flex",

              alignItems: "center",

              justifyContent: "center",

              cursor: "pointer",
            }}
          >
            <svg
              width="19"
              height="19"
              viewBox="0 0 24 24"
              fill="none"
              stroke="var(--text)"
              strokeWidth="1.8"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M12 15V3" />
              <path d="M7 8l5-5 5 5" />
              <path d="M4 14v5a2 2 0 002 2h12a2 2 0 002-2v-5" />
            </svg>
          </button>
        </div>
      </div>

      {visible.length > 0 && (
        <div style={{ marginTop: 28 }}>
          <h3
            style={{
              fontFamily: "Space Grotesk",

              fontSize: 18,

              fontWeight: 700,

              color: "var(--text)",

              margin: "0 0 14px",

              padding: "0 20px",
            }}
          >
            Suggested for you
          </h3>
          <div
            style={{
              display: "flex",

              gap: 12,

              overflowX: "auto",

              padding: "0 20px 4px",
            }}
          >
            {visible.map((s) => {
              const isFollowing = following.includes(s.id)

              return (
                <div
                  key={s.id}
                  style={{
                    position: "relative",

                    flex: "0 0 168px",

                    background: "var(--surface)",

                    border: "1px solid var(--border)",

                    borderRadius: 16,

                    padding: "14px 14px 16px",

                    display: "flex",

                    flexDirection: "column",

                    alignItems: "center",
                  }}
                >
                  <button
                    aria-label="Dismiss"
                    onClick={() => setDismissed((d) => [...d, s.id])}
                    style={{
                      position: "absolute",

                      top: 10,

                      right: 10,

                      background: "none",

                      border: "none",

                      color: "var(--muted)",

                      cursor: "pointer",

                      padding: 2,

                      display: "flex",
                    }}
                  >
                    <svg
                      width="14"
                      height="14"
                      viewBox="0 0 24 24"
                      fill="none"
                      stroke="currentColor"
                      strokeWidth="2"
                      strokeLinecap="round"
                    >
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </svg>
                  </button>

                  <div style={{ position: "relative", marginTop: 6 }}>
                    <img
                      src={u(s.avatar, 140, 140)}
                      alt={s.name}
                      style={{
                        width: 72,

                        height: 72,

                        borderRadius: "50%",

                        objectFit: "cover",

                        display: "block",
                      }}
                    />
                    <span
                      style={{
                        position: "absolute",

                        left: -2,

                        bottom: 2,

                        display: "flex",

                        background: "var(--surface)",

                        borderRadius: "50%",

                        padding: 1,
                      }}
                    >
                      <VerifiedBadge />
                    </span>
                  </div>

                  <div
                    style={{
                      display: "flex",

                      alignItems: "center",

                      gap: 5,

                      marginTop: 12,
                    }}
                  >
                    <span
                      style={{
                        fontFamily: "Space Grotesk",

                        fontSize: 15,

                        fontWeight: 700,

                        color: "var(--text)",
                      }}
                    >
                      {s.name}
                    </span>
                  </div>

                  <div
                    style={{
                      display: "flex",

                      alignItems: "center",

                      gap: 6,

                      marginTop: 6,

                      marginBottom: 14,
                    }}
                  >
                    <span style={{ display: "flex" }}>
                      {s.mutuals.map((m, i) => (
                        <img
                          key={m}
                          src={u(m, 32, 32)}
                          alt=""
                          style={{
                            width: 17,

                            height: 17,

                            borderRadius: "50%",

                            objectFit: "cover",

                            border: "1.5px solid var(--surface)",

                            marginLeft: i === 0 ? 0 : -6,

                            zIndex: i === 0 ? 2 : 1,

                            position: "relative",
                          }}
                        />
                      ))}
                    </span>
                    <span style={{ fontSize: 12.5, color: "var(--muted)" }}>
                      {s.handle}
                    </span>
                  </div>

                  <button
                    onClick={() =>
                      setFollowing((f) =>
                        isFollowing
                          ? f.filter((x) => x !== s.id)
                          : [...f, s.id],
                      )
                    }
                    style={{
                      width: "100%",

                      height: 38,

                      borderRadius: 10,

                      border: "none",

                      background: isFollowing ? "var(--border)" : "var(--text)",

                      color: isFollowing ? "var(--text)" : "var(--app-bg)",

                      fontSize: 14.5,

                      fontWeight: 600,

                      fontFamily: "Inter",

                      cursor: "pointer",
                    }}
                  >
                    {isFollowing ? "Following" : "Follow"}
                  </button>
                </div>
              )
            })}
          </div>
        </div>
      )}

      <div
        style={{
          display: "flex",

          marginTop: 26,

          borderBottom: "1px solid var(--border)",

          position: "sticky",

          top: 56,

          background: "var(--app-bg)",

          zIndex: 4,
        }}
      >
        {tabs.map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            style={{
              flex: 1,

              padding: "13px 0 12px",

              background: "none",

              border: "none",

              cursor: "pointer",

              fontFamily: "Inter",

              fontSize: 15,

              fontWeight: tab === t ? 600 : 500,

              color: tab === t ? "var(--text)" : "var(--muted)",

              position: "relative",
            }}
          >
            {t}
            {tab === t && (
              <span
                style={{
                  position: "absolute",

                  left: "50%",

                  transform: "translateX(-50%)",

                  bottom: -1,

                  width: "56%",

                  height: 2,

                  background: "var(--text)",

                  borderRadius: 2,
                }}
              />
            )}
          </button>
        ))}
      </div>

      <div style={{ paddingBottom: 24 }}>
        {tab === "Posts" &&
          posts.map((p) => (
            <div
              key={p.id}
              style={{
                display: "flex",

                gap: 12,

                padding: "16px 20px",

                borderBottom: "1px solid var(--surface)",
              }}
            >
              <img
                src={u(A.me, 64, 64)}
                alt=""
                style={{
                  width: 40,

                  height: 40,

                  borderRadius: "50%",

                  objectFit: "cover",

                  flexShrink: 0,
                }}
              />
              <div style={{ minWidth: 0, flex: 1 }}>
                <div
                  style={{
                    display: "flex",

                    alignItems: "center",

                    gap: 6,
                  }}
                >
                  <span
                    style={{
                      fontFamily: "Space Grotesk",

                      fontSize: 14.5,

                      fontWeight: 700,

                      color: "var(--text)",
                    }}
                  >
                    {name}
                  </span>
                  <span style={{ fontSize: 13.5, color: "var(--muted)" }}>
                    · {p.time}
                  </span>
                </div>
                <p
                  style={{
                    margin: "5px 0 0",

                    fontSize: 14.5,

                    lineHeight: 1.45,

                    color: "var(--text-2)",

                    fontFamily: "Inter",
                  }}
                >
                  {p.text}
                </p>
                {p.photo && (
                  <img
                    src={u(p.photo, 600, 340)}
                    alt=""
                    style={{
                      width: "100%",

                      height: 170,

                      objectFit: "cover",

                      borderRadius: 12,

                      marginTop: 10,

                      border: "1px solid var(--border)",
                    }}
                  />
                )}
                <ActionIcons
                  replies={p.replies}
                  likes={p.likes}
                  reposts={p.reposts}
                />
              </div>
            </div>
          ))}

        {tab !== "Posts" && (
          <div
            style={{
              display: "flex",

              flexDirection: "column",

              alignItems: "center",

              justifyContent: "center",

              gap: 8,

              padding: "56px 32px",

              textAlign: "center",
            }}
          >
            <div
              style={{
                width: 52,

                height: 52,

                borderRadius: "50%",

                background: "var(--surface)",

                border: "1px solid var(--border)",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",
              }}
            >
              <svg
                width="22"
                height="22"
                viewBox="0 0 24 24"
                fill="none"
                stroke="var(--muted)"
                strokeWidth="1.6"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <rect x="3" y="3" width="18" height="18" rx="4" />
                <circle cx="8.5" cy="8.5" r="1.5" />
                <path d="M21 15l-5-5L5 21" />
              </svg>
            </div>
            <span
              style={{
                fontFamily: "Space Grotesk",

                fontSize: 17,

                fontWeight: 700,

                color: "var(--text)",
              }}
            >
              Nothing here yet
            </span>
            <span style={{ fontSize: 13.5, color: "var(--muted)" }}>
              Your {tab.toLowerCase()} will show up here.
            </span>
          </div>
        )}
      </div>
    </div>
  )
}
