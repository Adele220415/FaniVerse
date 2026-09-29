import { Fragment, useEffect, useRef, useState } from "react"

const u = (id: string, w: number, h: number) =>
  `https://images.unsplash.com/${id}?w=${w}&h=${h}&fit=crop&auto=format`

const A = {
  mia: "photo-1494790108377-be9c29b29330",

  kenji: "photo-1500648767791-00dcc994a43e",

  sana: "photo-1438761681033-6461ffad8d80",

  diego: "photo-1507003211169-0a1dd7228f2d",

  yuki: "photo-1544005313-94ddf0286df2",

  leo: "photo-1519345182560-3f2917c472ef",
}

type MemberPost = {
  author: string

  avatar: string

  title: string

  time: string

  photo: string
}

const fandoms: {
  name: string

  color: string

  members: string

  photo: string

  posts: MemberPost[]
}[] = [
  {
    name: "Anime",

    color: "#FF6B5C",

    members: "2.1M",

    photo: "photo-1581833971358-2c8b550f87b3",

    posts: [
      {
        author: "Mia",

        avatar: A.mia,

        title: "Top 10 must-watch series of 2026",

        time: "2h",

        photo: "photo-1578632767115-351597cf2477",
      },

      {
        author: "Yuki",

        avatar: A.yuki,

        title: "Rating every Studio Ghibli film, part 3",

        time: "5h",

        photo: "photo-1581833971358-2c8b550f87b3",
      },

      {
        author: "Kenji",

        avatar: A.kenji,

        title: "This new arc changed everything 😭",

        time: "9h",

        photo: "photo-1531259683007-016a7b628fc3",
      },
    ],
  },

  {
    name: "Gaming",

    color: "#7C5CFF",

    members: "3.4M",

    photo: "photo-1542751371-adc38448a05e",

    posts: [
      {
        author: "Leo",

        avatar: A.leo,

        title: "Ranked grind day 4 — finally Diamond",

        time: "1h",

        photo: "photo-1542751371-adc38448a05e",
      },

      {
        author: "Diego",

        avatar: A.diego,

        title: "The hidden lore behind Elden Ring's ending",

        time: "4h",

        photo: "photo-1511512578047-dfb367046420",
      },

      {
        author: "Kenji",

        avatar: A.kenji,

        title: "Speedrun record broken again 🤯",

        time: "11h",

        photo: "photo-1561731216-c3a4d99437d5",
      },
    ],
  },

  {
    name: "Marvel",

    color: "#e23636",

    members: "5.2M",

    photo: "photo-1608889335941-32ac5f2041b9",

    posts: [
      {
        author: "Diego",

        avatar: A.diego,

        title: "Every Easter egg in the new Secret Wars trailer",

        time: "3h",

        photo: "photo-1612036782180-6f0b6cd846fe",
      },

      {
        author: "Mia",

        avatar: A.mia,

        title: "X-Men 97 rewatch thread 🧵",

        time: "7h",

        photo: "photo-1608889335941-32ac5f2041b9",
      },

      {
        author: "Sana",

        avatar: A.sana,

        title: "My fan cast for the next big villain",

        time: "13h",

        photo: "photo-1636953056323-9c09fdd74fa6",
      },
    ],
  },

  {
    name: "K-Pop",

    color: "#FF6B5C",

    members: "1.8M",

    photo: "photo-1571380401583-72ca84994796",

    posts: [
      {
        author: "Sana",

        avatar: A.sana,

        title: "Con day! 💜 fancams inside",

        time: "2h",

        photo: "photo-1571380401583-72ca84994796",
      },

      {
        author: "Yuki",

        avatar: A.yuki,

        title: "New comeback concept is everything",

        time: "6h",

        photo: "photo-1493711662062-fa541adb3fc8",
      },

      {
        author: "Mia",

        avatar: A.mia,

        title: "Lightstick unboxing 🎀",

        time: "15h",

        photo: "photo-1612404730960-5c71577fca11",
      },
    ],
  },

  {
    name: "Star Wars",

    color: "#7C5CFF",

    members: "4.1M",

    photo: "photo-1606041008023-472dfb5e530f",

    posts: [
      {
        author: "Yuki",

        avatar: A.yuki,

        title: "May the force be with you — marathon night",

        time: "5h",

        photo: "photo-1606041008023-472dfb5e530f",
      },

      {
        author: "Leo",

        avatar: A.leo,

        title: "Ranking every Vader scene, worst to best",

        time: "9h",

        photo: "photo-1446776877081-d282a0f896e2",
      },

      {
        author: "Diego",

        avatar: A.diego,

        title: "Andor season 2 thoughts 🚀",

        time: "16h",

        photo: "photo-1518709268805-4e9042af9f23",
      },
    ],
  },
]

type MediaPost = {
  author: string

  avatar: string

  fandom: string

  title: string

  time: string

  photo: string

  location: string

  likes: number

  comments: number

  reposts: number
}

const feedPhotos = [
  "photo-1578632767115-351597cf2477",

  "photo-1511512578047-dfb367046420",

  "photo-1612036782180-6f0b6cd846fe",

  "photo-1571380401583-72ca84994796",

  "photo-1446776877081-d282a0f896e2",

  "photo-1542751371-adc38448a05e",

  "photo-1581833971358-2c8b550f87b3",

  "photo-1608889335941-32ac5f2041b9",

  "photo-1493711662062-fa541adb3fc8",

  "photo-1606041008023-472dfb5e530f",

  "photo-1531259683007-016a7b628fc3",

  "photo-1561731216-c3a4d99437d5",

  "photo-1636953056323-9c09fdd74fa6",

  "photo-1612404730960-5c71577fca11",

  "photo-1518709268805-4e9042af9f23",

  "photo-1550745165-9bc0b252726f",

  "photo-1509198397868-475647b2a1e5",

  "photo-1516035069371-29a1b244cc32",

  "photo-1542751110-97427bbecf20",

  "photo-1614680376573-df3480f0c6ff",
]

const feedAvatars = [A.mia, A.kenji, A.sana, A.diego, A.yuki, A.leo]

const feedAuthors = ["Mia", "Kenji", "Sana", "Diego", "Yuki", "Leo"]

const feedFandoms = [
  "Anime",

  "Gaming",

  "Marvel",

  "K-Pop",

  "Star Wars",

  "Sci-Fi",
]

const feedLocations = [
  "Bloomingdale, Illinois",

  "Tokyo, Japan",

  "Los Angeles, California",

  "Seoul, South Korea",

  "London, England",

  "Austin, Texas",
]

const feedTitles = [
  "Top 10 must-watch series of 2026",

  "The hidden lore behind Elden Ring's ending",

  "Every Easter egg in the new Secret Wars trailer",

  "Con day! 💜 fancams inside",

  "Time travel rules that actually make sense",

  "Ranked grind day 4 — finally Diamond",

  "Rating every Studio Ghibli film, part 3",

  "X-Men 97 rewatch thread 🧵",

  "Album photocard collection tour",

  "Ranking every Vader scene, worst to best",

  "This new arc changed everything 😭",

  "Speedrun record broken again 🤯",

  "My fan cast for the next big villain",

  "Dance practice breakdown, slow version",

  "Best lightsaber duels of the saga",

  "Best opening themes of the season, ranked",

  "Every boss weakness you missed",

  "Ranking every MCU phase, worst to best",

  "Behind the scenes of the music video",

  "Helmet collection shelf tour",

  "Why this underrated anime deserves a sequel",

  "Building the ultimate loadout guide",

  "The post-credit scene explained",

  "Lightstick unboxing 🎀",

  "Reading the Thrawn trilogy, chapter 1",

  "Manga vs anime: which told it better?",

  "Indie games that deserve more love",

  "Comic runs you should read before the movie",

  "Setlist predictions for the world tour",

  "Andor season 2 thoughts 🚀",

  "Cozy weekend watchlist for rainy days",

  "My honest review after 100 hours",

  "Suit upgrade breakdown — frame by frame",

  "Fan art compilation of the month",

  "Ranking the greatest sci-fi ships",

  "Weekend binge: 5 shows you can finish fast",

  "Character analysis: the anti-hero we needed",

  "Hidden details in the finale, frame by frame",

  "Cosplay build log — day 3",

  "Dune: Messiah adaptation — what to expect",

  "Poll: which team was right all along?",

  "Convention haul from this weekend",

  "My collection tour — 6 years in the making",

  "Best soundtracks to study to",

  "Building a reading list for new fans",

  "Live Q&A recap and thank you 🙏",

  "The scene that changed the genre forever",

  "What are you watching this week? Share below",

  "Frame-by-frame look at the final battle",

  "Community challenge: show us your setup 🎮",
]

const feed: MediaPost[] = feedTitles.map((title, i) => ({
  title,

  author: feedAuthors[i % feedAuthors.length],

  avatar: feedAvatars[i % feedAvatars.length],

  fandom: feedFandoms[i % feedFandoms.length],

  photo: feedPhotos[i % feedPhotos.length],

  location: feedLocations[i % feedLocations.length],

  time: `${((i * 3) % 23) + 1}h`,

  likes: 42 + ((i * 37) % 960),

  comments: 3 + ((i * 11) % 88),

  reposts: 2 + ((i * 7) % 41),
}))

type Reel = {
  id: string

  author: string

  avatar: string

  photo: string

  caption: string

  audio: string

  views: string

  likes: number

  comments: number

  shares: number
}

const reels: Reel[] = [
  {
    id: "r1",

    author: "Mia",

    avatar: A.mia,

    photo: "photo-1578632767115-351597cf2477",

    caption:
      "Top 10 must-watch series of 2026 🎬 which one are you starting with tonight?",

    audio: "original audio · Mia",

    views: "1.2M",

    likes: 84200,

    comments: 1240,

    shares: 3100,
  },

  {
    id: "r2",

    author: "Diego",

    avatar: A.diego,

    photo: "photo-1511512578047-dfb367046420",

    caption: "Ranked grind day 4 — finally Diamond ✦ full gameplay clip",

    audio: "Nightmare Night · Xeno Beats",

    views: "982K",

    likes: 45100,

    comments: 890,

    shares: 1400,
  },

  {
    id: "r3",

    author: "Sana",

    avatar: A.sana,

    photo: "photo-1571380401583-72ca84994796",

    caption:
      "Con day fit check 💜 fancams inside — wait for the lightstick part",

    audio: "Neon Heartbeat · LUNA8",

    views: "2.4M",

    likes: 156000,

    comments: 3400,

    shares: 8900,
  },

  {
    id: "r4",

    author: "Leo",

    avatar: A.leo,

    photo: "photo-1542751371-adc38448a05e",

    caption: "Every boss weakness you missed — part 3, the last one is broken",

    audio: "original audio · Leo",

    views: "644K",

    likes: 28700,

    comments: 640,

    shares: 980,
  },

  {
    id: "r5",

    author: "Yuki",

    avatar: A.yuki,

    photo: "photo-1493711662062-fa541adb3fc8",

    caption: "Dance practice breakdown in slow version 🩰 tutorial in comments",

    audio: "Slow Motion · ARIA",

    views: "1.8M",

    likes: 98300,

    comments: 2100,

    shares: 5600,
  },

  {
    id: "r6",

    author: "Kenji",

    avatar: A.kenji,

    photo: "photo-1531259683007-016a7b628fc3",

    caption: "This new arc changed everything 😭 wait for the last 5 seconds",

    audio: "original audio · Kenji",

    views: "756K",

    likes: 33400,

    comments: 720,

    shares: 1200,
  },
]

const fmtCount = (n: number) => {
  if (n >= 1000000) return `${(n / 1000000).toFixed(1).replace(/\.0$/, "")}M`

  if (n >= 1000) return `${(n / 1000).toFixed(1).replace(/\.0$/, "")}K`

  return `${n}`
}

export default function HomeTab({ onOpenMenu }: { onOpenMenu: () => void }) {
  const [activeFandom, setActiveFandom] = useState<number | null>(null)

  const [reelsOpen, setReelsOpen] = useState<number | null>(null)

  const [seen, setSeen] = useState<Set<string>>(new Set())

  const [headerHidden, setHeaderHidden] = useState(false)

  const scrollRef = useRef<HTMLDivElement | null>(null)

  const sentinelRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    const root = scrollRef.current

    const el = sentinelRef.current

    if (!root || !el || typeof IntersectionObserver === "undefined") return

    const io = new IntersectionObserver(
      (entries) => {
        const e = entries[0]

        setHeaderHidden(!e.isIntersecting && e.boundingClientRect.top < 0)
      },

      { root, threshold: 0 },
    )

    io.observe(el)

    return () => io.disconnect()
  }, [])

  const openFandomStory = (i: number) => {
    setSeen((s) => new Set(s).add(fandoms[i].name))

    setActiveFandom(i)
  }

  return (
    <div
      style={{
        position: "relative",

        height: "100%",

        background: "var(--app-bg)",
      }}
    >
      <div
        ref={scrollRef}
        className="flex flex-col h-full overflow-y-auto"
        style={{ background: "var(--app-bg)" }}
      >
        {/* Header with profile */}
        <div
          style={{
            position: "sticky",

            top: 0,

            zIndex: 10,

            background: "var(--app-bg)",

            transform: headerHidden ? "translateY(-100%)" : "translateY(0)",

            opacity: headerHidden ? 0 : 1,

            pointerEvents: headerHidden ? "none" : "auto",

            transition:
              "transform 0.28s cubic-bezier(0.22, 1, 0.36, 1), opacity 0.18s ease",
          }}
        >
          <div className="flex items-center justify-between px-5 pt-12 pb-1">
            <span
              style={{
                fontFamily: "Space Grotesk",

                fontSize: 20,

                fontWeight: 700,

                color: "var(--text)",
              }}
            >
              Home
            </span>
            <button
              onClick={onOpenMenu}
              aria-label="Profile"
              style={{
                width: 40,

                height: 40,

                borderRadius: "50%",

                padding: 0,

                overflow: "hidden",

                background: "var(--surface)",

                border: "1.5px solid #7C5CFF",

                cursor: "pointer",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                flexShrink: 0,
              }}
            >
              <img
                src={u("photo-1519345182560-3f2917c472ef", 96, 96)}
                alt="Alex Kim"
                style={{
                  width: "100%",

                  height: "100%",

                  objectFit: "cover",

                  display: "block",
                }}
              />
            </button>
          </div>
        </div>

        {/* Stories */}
        <div className="mb-6 pt-4">
          <div className="flex items-center justify-between px-5 mb-3">
            <span
              style={{
                fontFamily: "Space Grotesk",

                fontSize: 16,

                fontWeight: 600,

                color: "var(--text)",
              }}
            >
              Fandom Stories
            </span>
          </div>
          <div
            className="flex gap-4 px-5 overflow-x-auto pb-1"
            style={{ scrollbarWidth: "none" }}
          >
            {fandoms.map((f, i) => (
              <div
                key={f.name}
                className="flex flex-col items-center gap-1.5"
                style={{ flexShrink: 0, cursor: "pointer" }}
                onClick={() => openFandomStory(i)}
              >
                <div
                  style={{
                    width: 66,

                    height: 66,

                    borderRadius: "50%",

                    padding: 2.5,

                    background: seen.has(f.name)
                      ? "var(--border)"
                      : `linear-gradient(45deg, ${f.color}, #7C5CFF)`,
                  }}
                >
                  <img
                    src={u(f.photo, 140, 140)}
                    alt={f.name}
                    style={{
                      width: "100%",

                      height: "100%",

                      borderRadius: "50%",

                      objectFit: "cover",

                      border: "2.5px solid var(--app-bg)",
                    }}
                  />
                </div>
                <span
                  style={{
                    fontSize: 11,

                    color: seen.has(f.name) ? "var(--muted)" : "var(--text)",

                    maxWidth: 66,

                    overflow: "hidden",

                    textOverflow: "ellipsis",

                    whiteSpace: "nowrap",
                  }}
                >
                  {f.name}
                </span>
              </div>
            ))}
          </div>
        </div>

        {/* Media feed */}
        <div className="px-5 mb-6">
          <div className="flex items-center justify-between mb-3">
            <span
              style={{
                fontFamily: "Space Grotesk",

                fontSize: 16,

                fontWeight: 600,

                color: "var(--text)",
              }}
            >
              For You
            </span>
            {/* Post count — disabled (commented out, not removed)
            <span style={{ fontSize: 13, color: "var(--muted)" }}>
              {feed.length} posts
            </span>
            */}
          </div>
          <div className="flex flex-col gap-4">
            {feed.map((p, i) => (
              <Fragment key={`${p.title}-${i}`}>
                <MediaCard post={p} />
                {i === 4 && (
                  <Fragment>
                    <div ref={sentinelRef} style={{ height: 1 }} />
                    <ReelsTray onOpen={setReelsOpen} />
                  </Fragment>
                )}
              </Fragment>
            ))}
          </div>
        </div>
      </div>
      {activeFandom !== null && (
        <StoryViewer
          key={activeFandom}
          fandom={fandoms[activeFandom]}
          onClose={() => setActiveFandom(null)}
        />
      )}
      {reelsOpen !== null && (
        <ReelsViewer
          key={reelsOpen}
          startIndex={reelsOpen}
          onClose={() => setReelsOpen(null)}
        />
      )}
    </div>
  )
}

function MediaCard({ post }: { post: MediaPost }) {
  const [liked, setLiked] = useState(false)

  const [reposted, setReposted] = useState(false)

  return (
    <div
      style={{
        background: "var(--surface)",

        border: "1px solid var(--border)",

        borderRadius: 16,

        overflow: "hidden",

        cursor: "pointer",
      }}
    >
      <div
        style={{
          display: "flex",

          alignItems: "flex-start",

          gap: 10,

          padding: "12px 14px 0",
        }}
      >
        <img
          src={u(post.avatar, 80, 80)}
          alt={post.author}
          style={{
            width: 40,

            height: 40,

            borderRadius: "50%",

            objectFit: "cover",

            flexShrink: 0,
          }}
        />
        <div style={{ flex: 1, minWidth: 0 }}>
          <div
            style={{
              display: "flex",

              alignItems: "center",

              gap: 4,

              flexWrap: "wrap",

              lineHeight: 1.2,
            }}
          >
            <span
              style={{
                fontSize: 14.5,

                fontWeight: 700,

                color: "var(--text)",
              }}
            >
              {post.author}
            </span>
            <VerifiedBadge />
            <span style={{ fontSize: 13, color: "var(--muted)" }}>
              · @{post.fandom.toLowerCase().replace(/[^a-z0-9]/g, "")} ·{" "}
              {post.time}
            </span>
          </div>
          <p
            style={{
              margin: "5px 0 0",

              fontSize: 14.5,

              lineHeight: 1.45,

              color: "var(--text)",
            }}
          >
            {post.title}
          </p>
        </div>
        <button
          aria-label="More"
          style={{
            background: "none",

            border: "none",

            cursor: "pointer",

            padding: 2,

            display: "flex",

            flexShrink: 0,
          }}
        >
          <svg width="16" height="16" viewBox="0 0 24 24" fill="var(--muted)">
            <circle cx="5" cy="12" r="1.8" />
            <circle cx="12" cy="12" r="1.8" />
            <circle cx="19" cy="12" r="1.8" />
          </svg>
        </button>
      </div>

      <div
        style={{
          position: "relative",

          margin: "11px 12px 0",

          height: 218,

          borderRadius: 16,

          overflow: "hidden",

          background: "var(--surface-2)",
        }}
      >
        <img
          src={u(post.photo, 720, 480)}
          alt={post.title}
          style={{
            width: "100%",

            height: "100%",

            objectFit: "cover",

            display: "block",
          }}
        />
        <button
          aria-label="Unmute"
          style={{
            position: "absolute",

            right: 8,

            bottom: 8,

            width: 26,

            height: 26,

            borderRadius: "50%",

            background: "rgba(0,0,0,0.55)",

            border: "none",

            cursor: "pointer",

            display: "flex",

            alignItems: "center",

            justifyContent: "center",
          }}
        >
          <svg
            width="13"
            height="13"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#fff"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <polygon
              points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"
              fill="#fff"
              stroke="none"
            />
            <line x1="23" y1="9" x2="17" y2="15" />
            <line x1="17" y1="9" x2="23" y2="15" />
          </svg>
        </button>
      </div>

      <div
        style={{
          display: "flex",

          alignItems: "center",

          gap: 5,

          padding: "10px 14px 0",

          color: "var(--muted)",

          fontSize: 13,
        }}
      >
        <svg
          width="14"
          height="14"
          viewBox="0 0 24 24"
          fill="none"
          stroke="var(--muted)"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0118 0z" />
          <circle cx="12" cy="10" r="3" />
        </svg>
        {post.location}
      </div>

      <div
        style={{
          display: "flex",

          alignItems: "center",

          justifyContent: "space-between",

          padding: "8px 14px 10px",
        }}
      >
        <PostAction
          count={post.likes + (liked ? 1 : 0)}
          active={liked}
          activeColor="#f4212e"
          onClick={() => setLiked((v) => !v)}
        >
          <svg
            width="17"
            height="17"
            viewBox="0 0 24 24"
            fill={liked ? "#f4212e" : "none"}
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
          </svg>
        </PostAction>

        <PostAction count={post.comments}>
          <svg
            width="17"
            height="17"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" />
          </svg>
        </PostAction>

        <PostAction
          count={post.reposts + (reposted ? 1 : 0)}
          active={reposted}
          activeColor="#00ba7c"
          onClick={() => setReposted((v) => !v)}
        >
          <svg
            width="17"
            height="17"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <polyline points="17 1 21 5 17 9" />
            <path d="M3 11V9a4 4 0 014-4h14" />
            <polyline points="7 23 3 19 7 15" />
            <path d="M21 13v2a4 4 0 01-4 4H3" />
          </svg>
        </PostAction>

        <PostAction>
          <svg
            width="17"
            height="17"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.8"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <line x1="22" y1="2" x2="11" y2="13" />
            <polygon points="22 2 15 22 11 13 2 9 22 2" />
          </svg>
        </PostAction>
      </div>
    </div>
  )
}

function VerifiedBadge() {
  return (
    <svg
      width="15"
      height="15"
      viewBox="0 0 24 24"
      aria-label="Verified"
      style={{ flexShrink: 0 }}
    >
      <path
        fill="#1d9bf0"
        d="M22.25 12c0-1.43-.88-2.67-2.19-3.34.46-1.39.2-2.9-.81-3.91s-2.52-1.27-3.91-.81c-.67-1.31-1.91-2.19-3.34-2.19s-2.67.88-3.34 2.19c-1.39-.46-2.9-.2-3.91.81s-1.27 2.52-.81 3.91c-1.31.67-2.19 1.91-2.19 3.34s.88 2.67 2.19 3.34c-.46 1.39-.2 2.9.81 3.91s2.52 1.27 3.91.81c.67 1.31 1.91 2.19 3.34 2.19s2.67-.88 3.34-2.19c1.39.46 2.9.2 3.91-.81s1.27-2.52.81-3.91c1.31-.67 2.19-1.91 2.19-3.34zm-11.71 4.2L6.8 12.46l1.41-1.42 2.26 2.26 4.8-5.23 1.47 1.36-6.2 6.77z"
      />
    </svg>
  )
}

function PostAction({
  count,

  active,

  activeColor = "#f4212e",

  onClick,

  children,
}: {
  count?: number

  active?: boolean

  activeColor?: string

  onClick?: () => void

  children: React.ReactNode
}) {
  return (
    <button
      onClick={onClick}
      style={{
        display: "flex",

        alignItems: "center",

        gap: 6,

        background: "none",

        border: "none",

        cursor: "pointer",

        padding: "4px 2px",

        color: active ? activeColor : "var(--muted)",

        fontFamily: "Inter",

        fontSize: 12.5,

        fontWeight: 500,
      }}
    >
      {children}
      {count !== undefined && <span>{count}</span>}
    </button>
  )
}

function ReelsTray({ onOpen }: { onOpen: (i: number) => void }) {
  return (
    <div className="mb-6">
      <div className="flex items-center justify-between px-5 mb-3">
        <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="var(--text)"
            strokeWidth="1.7"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <rect x="2" y="2" width="20" height="20" rx="6" />
            <line x1="2" y1="8.5" x2="22" y2="8.5" />
            <path d="M9 2.5 6.5 8.5" />
            <path d="M15.5 2.5 13 8.5" />
            <polygon
              points="10 12.5 10 18 14.5 15.25"
              fill="var(--text)"
              stroke="none"
            />
          </svg>
          <span
            style={{
              fontFamily: "Space Grotesk",

              fontSize: 16,

              fontWeight: 600,

              color: "var(--text)",
            }}
          >
            Reels
          </span>
        </div>
        <span style={{ fontSize: 12.5, color: "var(--muted)" }}>
          Watch next
        </span>
      </div>
      <div
        className="flex gap-3 px-5 overflow-x-auto pb-1"
        style={{ scrollbarWidth: "none" }}
      >
        {reels.map((r, i) => (
          <div
            key={r.id}
            onClick={() => onOpen(i)}
            style={{
              position: "relative",

              width: 112,

              height: 198,

              borderRadius: 14,

              overflow: "hidden",

              flexShrink: 0,

              cursor: "pointer",

              background: "var(--surface-2)",

              border: "1px solid var(--border)",
            }}
          >
            <img
              src={u(r.photo, 240, 420)}
              alt={r.caption}
              style={{
                width: "100%",

                height: "100%",

                objectFit: "cover",

                display: "block",
              }}
            />
            <div
              style={{
                position: "absolute",

                inset: 0,

                background:
                  "linear-gradient(to bottom, rgba(0,0,0,0.2), transparent 45%, rgba(0,0,0,0.72))",
              }}
            />
            <div
              style={{
                position: "absolute",

                left: 7,

                bottom: 7,

                display: "flex",

                alignItems: "center",

                gap: 4,
              }}
            >
              <svg width="11" height="11" viewBox="0 0 24 24" fill="#fff">
                <polygon points="6 3 20 12 6 21 6 3" />
              </svg>
              <span
                style={{
                  fontSize: 11,

                  fontWeight: 600,

                  color: "#fff",
                }}
              >
                {r.views}
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

function ReelsViewer({
  startIndex,

  onClose,
}: {
  startIndex: number

  onClose: () => void
}) {
  const [liked, setLiked] = useState<Record<number, boolean>>({})

  const [followed, setFollowed] = useState<Record<number, boolean>>({})

  const [muted, setMuted] = useState(true)

  const [burst, setBurst] = useState<number | null>(null)

  const containerRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    const c = containerRef.current

    if (c) c.scrollTop = startIndex * c.clientHeight
  }, [startIndex])

  const toggleLike = (i: number) => {
    setLiked((l) => ({ ...l, [i]: !l[i] }))
  }

  const burstLike = (i: number) => {
    setLiked((l) => ({ ...l, [i]: true }))

    setBurst(i)

    window.setTimeout(() => setBurst((b) => (b === i ? null : b)), 1000)
  }

  const toggleFollow = (i: number) => {
    setFollowed((f) => ({ ...f, [i]: !f[i] }))
  }

  return (
    <div
      style={{
        position: "absolute",

        inset: 0,

        zIndex: 50,

        background: "#000",
      }}
    >
      {/* top bar */}
      <div
        style={{
          position: "absolute",

          top: 0,

          left: 0,

          right: 0,

          zIndex: 5,

          display: "flex",

          alignItems: "center",

          gap: 10,

          padding: "14px 14px 12px",

          background:
            "linear-gradient(to bottom, rgba(0,0,0,0.55), transparent)",

          pointerEvents: "none",
        }}
      >
        <button
          onClick={onClose}
          aria-label="Back"
          style={{
            background: "none",

            border: "none",

            cursor: "pointer",

            padding: 0,

            display: "flex",

            pointerEvents: "auto",
          }}
        >
          <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#fff"
            strokeWidth="2.2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </button>
        <span
          style={{
            fontFamily: "Space Grotesk",

            fontSize: 17,

            fontWeight: 700,

            color: "#fff",
          }}
        >
          Reels
        </span>
        <div style={{ flex: 1 }} />
        <button
          onClick={() => setMuted((m) => !m)}
          aria-label={muted ? "Unmute" : "Mute"}
          style={{
            width: 32,

            height: 32,

            borderRadius: "50%",

            background: "rgba(0,0,0,0.4)",

            border: "none",

            cursor: "pointer",

            display: "flex",

            alignItems: "center",

            justifyContent: "center",

            pointerEvents: "auto",
          }}
        >
          <svg
            width="15"
            height="15"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#fff"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <polygon
              points="11 5 6 9 2 9 2 15 6 15 11 19 11 5"
              fill="#fff"
              stroke="none"
            />
            {muted ? (
              <>
                <line x1="23" y1="9" x2="17" y2="15" />
                <line x1="17" y1="9" x2="23" y2="15" />
              </>
            ) : (
              <>
                <path d="M15.54 8.46a5 5 0 010 7.07" />
                <path d="M19.07 4.93a10 10 0 010 14.14" />
              </>
            )}
          </svg>
        </button>
      </div>

      {/* snap scroll feed */}
      <div
        ref={containerRef}
        style={{
          height: "100%",

          overflowY: "auto",

          scrollSnapType: "y mandatory",

          overscrollBehavior: "contain",

          scrollbarWidth: "none",
        }}
      >
        {reels.map((reel, i) => (
          <ReelItem
            key={reel.id}
            reel={reel}
            liked={!!liked[i]}
            followed={!!followed[i]}
            bursting={burst === i}
            onLike={() => toggleLike(i)}
            onDoubleLike={() => burstLike(i)}
            onFollow={() => toggleFollow(i)}
          />
        ))}
      </div>
    </div>
  )
}

function ReelItem({
  reel,

  liked,

  followed,

  bursting,

  onLike,

  onDoubleLike,

  onFollow,
}: {
  reel: Reel

  liked: boolean

  followed: boolean

  bursting: boolean

  onLike: () => void

  onDoubleLike: () => void

  onFollow: () => void
}) {
  return (
    <div
      onDoubleClick={onDoubleLike}
      style={{
        position: "relative",

        height: "100%",

        scrollSnapAlign: "start",

        scrollSnapStop: "always",

        overflow: "hidden",

        background: "#000",
      }}
    >
      <img
        src={u(reel.photo, 780, 1400)}
        alt=""
        style={{
          position: "absolute",

          inset: 0,

          width: "100%",

          height: "100%",

          objectFit: "cover",
        }}
      />
      <div
        style={{
          position: "absolute",

          inset: 0,

          background:
            "linear-gradient(to bottom, rgba(0,0,0,0.45), transparent 20%, transparent 50%, rgba(0,0,0,0.72))",
        }}
      />

      {bursting && (
        <div
          className="reel-heart"
          style={{
            position: "absolute",

            inset: 0,

            display: "flex",

            alignItems: "center",

            justifyContent: "center",

            pointerEvents: "none",

            zIndex: 3,
          }}
        >
          <svg width="98" height="98" viewBox="0 0 24 24" fill="#fff">
            <path d="M12 21s-6.7-4.35-9.33-8.11C.9 10.36 1.98 6.5 5.28 5.6c2.06-.56 4.06.3 5.22 2.05C11.66 5.9 13.66 5.04 15.72 5.6c3.3.9 4.38 4.76 2.61 7.29C18.7 16.65 12 21 12 21z" />
          </svg>
        </div>
      )}

      {/* right action rail */}
      <div
        style={{
          position: "absolute",

          right: 10,

          bottom: 88,

          zIndex: 4,

          display: "flex",

          flexDirection: "column",

          alignItems: "center",

          gap: 16,
        }}
      >
        <div style={{ position: "relative", marginBottom: 5 }}>
          <img
            src={u(reel.avatar, 96, 96)}
            alt={reel.author}
            style={{
              width: 46,

              height: 46,

              borderRadius: "50%",

              objectFit: "cover",

              border: "2px solid #fff",

              display: "block",
            }}
          />
          <button
            onClick={onFollow}
            aria-label={followed ? "Following" : "Follow"}
            style={{
              position: "absolute",

              left: "50%",

              transform: "translateX(-50%)",

              bottom: -9,

              width: 21,

              height: 21,

              borderRadius: "50%",

              background: followed ? "var(--surface-2)" : "#fff",

              border: "2px solid #000",

              cursor: "pointer",

              display: "flex",

              alignItems: "center",

              justifyContent: "center",

              padding: 0,
            }}
          >
            {followed ? (
              <svg
                width="11"
                height="11"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#fff"
                strokeWidth="3.4"
                strokeLinecap="round"
                strokeLinejoin="round"
              >
                <polyline points="20 6 9 17 4 12" />
              </svg>
            ) : (
              <svg
                width="11"
                height="11"
                viewBox="0 0 24 24"
                fill="none"
                stroke="#000"
                strokeWidth="3.4"
                strokeLinecap="round"
              >
                <line x1="12" y1="5" x2="12" y2="19" />
                <line x1="5" y1="12" x2="19" y2="12" />
              </svg>
            )}
          </button>
        </div>

        <RailAction
          count={fmtCount(reel.likes + (liked ? 1 : 0))}
          onClick={onLike}
        >
          <svg
            width="27"
            height="27"
            viewBox="0 0 24 24"
            fill={liked ? "#ff3040" : "none"}
            stroke={liked ? "#ff3040" : "#fff"}
            strokeWidth="1.9"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
          </svg>
        </RailAction>

        <RailAction count={fmtCount(reel.comments)}>
          <svg
            width="26"
            height="26"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#fff"
            strokeWidth="1.9"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" />
          </svg>
        </RailAction>

        <RailAction count={fmtCount(reel.shares)}>
          <svg
            width="25"
            height="25"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#fff"
            strokeWidth="1.9"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <line x1="22" y1="2" x2="11" y2="13" />
            <polygon points="22 2 15 22 11 13 2 9 22 2" />
          </svg>
        </RailAction>

        <RailAction>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="#fff">
            <circle cx="5" cy="12" r="2" />
            <circle cx="12" cy="12" r="2" />
            <circle cx="19" cy="12" r="2" />
          </svg>
        </RailAction>

        <div
          className="reel-spin"
          style={{
            width: 28,

            height: 28,

            borderRadius: "50%",

            overflow: "hidden",

            border: "1.5px solid rgba(255,255,255,0.55)",
          }}
        >
          <img
            src={u(reel.avatar, 56, 56)}
            alt=""
            style={{
              width: "100%",

              height: "100%",

              objectFit: "cover",
            }}
          />
        </div>
      </div>

      {/* bottom info */}
      <div
        style={{
          position: "absolute",

          left: 14,

          right: 78,

          bottom: 24,

          zIndex: 4,

          display: "flex",

          flexDirection: "column",

          gap: 8,
        }}
      >
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <span
            style={{
              fontFamily: "Space Grotesk",

              fontSize: 14.5,

              fontWeight: 700,

              color: "#fff",
            }}
          >
            {reel.author}
          </span>
          <button
            onClick={onFollow}
            style={{
              background: "none",

              border: "none",

              cursor: "pointer",

              padding: 0,

              color: "#fff",

              fontFamily: "Inter",

              fontSize: 13.5,

              fontWeight: 700,
            }}
          >
            {followed ? "Following" : "Follow"}
          </button>
        </div>
        <p
          style={{
            margin: 0,

            fontSize: 13.5,

            lineHeight: 1.4,

            color: "#fff",

            display: "-webkit-box",

            WebkitLineClamp: 2,

            WebkitBoxOrient: "vertical",

            overflow: "hidden",
          }}
        >
          {reel.caption}
        </p>
        <div
          style={{
            display: "flex",

            alignItems: "center",

            gap: 6,

            overflow: "hidden",
          }}
        >
          <svg
            width="13"
            height="13"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#fff"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
            style={{ flexShrink: 0 }}
          >
            <path d="M9 18V5l12-2v13" />
            <circle cx="6" cy="18" r="3" />
            <circle cx="18" cy="16" r="3" />
          </svg>
          <div style={{ overflow: "hidden", flex: 1 }}>
            <div
              className="reel-marquee"
              style={{ display: "flex", width: "max-content" }}
            >
              <span
                style={{
                  fontSize: 12.5,

                  color: "rgba(255,255,255,0.92)",

                  whiteSpace: "nowrap",

                  paddingRight: 48,
                }}
              >
                {reel.audio}
              </span>
              <span
                style={{
                  fontSize: 12.5,

                  color: "rgba(255,255,255,0.92)",

                  whiteSpace: "nowrap",

                  paddingRight: 48,
                }}
              >
                {reel.audio}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* progress bar */}
      <div
        style={{
          position: "absolute",

          left: 0,

          right: 0,

          bottom: 0,

          height: 2.5,

          background: "rgba(255,255,255,0.22)",

          zIndex: 5,
        }}
      >
        <div
          className="reel-progress"
          style={{ height: "100%", background: "#fff" }}
        />
      </div>
    </div>
  )
}

function RailAction({
  count,

  onClick,

  children,
}: {
  count?: string

  onClick?: () => void

  children: React.ReactNode
}) {
  return (
    <button
      onClick={onClick}
      style={{
        display: "flex",

        flexDirection: "column",

        alignItems: "center",

        gap: 4,

        background: "none",

        border: "none",

        cursor: "pointer",

        padding: 0,
      }}
    >
      {children}
      {count !== undefined && (
        <span
          style={{
            fontSize: 11.5,

            fontWeight: 600,

            color: "#fff",

            fontFamily: "Inter",
          }}
        >
          {count}
        </span>
      )}
    </button>
  )
}

function StoryViewer({
  fandom,

  onClose,
}: {
  fandom: typeof fandoms[number]

  onClose: () => void
}) {
  const total = fandom.posts.length

  const [seg, setSeg] = useState(0)

  const [progress, setProgress] = useState(0)

  const post = fandom.posts[seg]

  const segRef = useRef(0)

  const closeRef = useRef(onClose)

  segRef.current = seg

  closeRef.current = onClose

  const advance = () => {
    const i = segRef.current

    if (i + 1 < total) setSeg(i + 1)
    else closeRef.current()
  }

  const advanceRef = useRef(advance)

  advanceRef.current = advance

  const back = () => {
    const i = segRef.current

    if (i > 0) setSeg(i - 1)
    else setProgress(0)
  }

  useEffect(() => {
    setProgress(0)

    const started = Date.now()

    const id = setInterval(() => {
      const p = (Date.now() - started) / 5000

      if (p >= 1) {
        clearInterval(id)

        advanceRef.current()
      } else {
        setProgress(p)
      }
    }, 50)

    return () => clearInterval(id)
  }, [seg])

  return (
    <div
      style={{
        position: "absolute",

        inset: 0,

        background: "#000",

        zIndex: 40,

        display: "flex",

        flexDirection: "column",
      }}
    >
      <img
        src={u(fandom.photo, 780, 1400)}
        alt=""
        style={{
          position: "absolute",

          inset: 0,

          width: "100%",

          height: "100%",

          objectFit: "cover",

          opacity: 0.35,
        }}
      />
      <div
        style={{
          position: "absolute",

          inset: 0,

          background: "var(--app-bg)",

          opacity: 0.55,
        }}
      />
      <div
        style={{
          position: "absolute",

          inset: 0,

          background:
            "linear-gradient(to bottom, rgba(0,0,0,0.6), transparent 25%, transparent 55%, rgba(0,0,0,0.8))",
        }}
      />

      {/* progress bars */}
      <div
        style={{
          position: "relative",

          display: "flex",

          gap: 4,

          padding: "12px 12px 0",
        }}
      >
        {fandom.posts.map((_, i) => (
          <div
            key={i}
            style={{
              flex: 1,

              height: 2.5,

              borderRadius: 2,

              background: "rgba(255,255,255,0.3)",

              overflow: "hidden",
            }}
          >
            <div
              style={{
                height: "100%",

                width:
                  i < seg ? "100%" : i === seg ? `${progress * 100}%` : "0%",

                background: "#fff",

                borderRadius: 2,
              }}
            />
          </div>
        ))}
      </div>

      {/* header */}
      <div
        style={{
          position: "relative",

          display: "flex",

          alignItems: "center",

          gap: 10,

          padding: "12px 14px",
        }}
      >
        <img
          src={u(fandom.photo, 140, 140)}
          alt={fandom.name}
          style={{
            width: 36,

            height: 36,

            borderRadius: "50%",

            objectFit: "cover",

            border: "1.5px solid rgba(255,255,255,0.6)",
          }}
        />
        <span
          style={{
            fontFamily: "Space Grotesk",

            fontSize: 14,

            fontWeight: 600,

            color: "#fff",
          }}
        >
          {fandom.name}
        </span>
        <span style={{ fontSize: 12, color: "rgba(255,255,255,0.6)" }}>
          {fandom.members} members · {seg + 1}/{total}
        </span>
        <div style={{ flex: 1 }} />
        <button
          onClick={onClose}
          style={{
            background: "none",

            border: "none",

            cursor: "pointer",

            padding: 4,

            display: "flex",
          }}
        >
          <svg
            width="22"
            height="22"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#fff"
            strokeWidth="2"
            strokeLinecap="round"
          >
            <line x1="18" y1="6" x2="6" y2="18" />
            <line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>
      </div>

      {/* tap zones */}
      <div style={{ position: "relative", flex: 1, display: "flex" }}>
        <div onClick={back} style={{ flex: 1, cursor: "pointer" }} />
        <div onClick={advance} style={{ flex: 1, cursor: "pointer" }} />
      </div>

      {/* member post card */}
      <div style={{ position: "relative", padding: "0 14px 26px" }}>
        <div
          style={{
            background: "rgba(18,18,20,0.92)",

            border: "1px solid rgba(255,255,255,0.14)",

            borderRadius: 18,

            padding: 14,

            backdropFilter: "blur(10px)",
          }}
        >
          <div style={{ display: "flex", alignItems: "center", gap: 9 }}>
            <img
              src={u(post.avatar, 64, 64)}
              alt={post.author}
              style={{
                width: 32,

                height: 32,

                borderRadius: "50%",

                objectFit: "cover",
              }}
            />
            <span style={{ fontSize: 13.5, color: "#fff", fontWeight: 600 }}>
              {post.author}
            </span>
            <span style={{ fontSize: 12.5, color: "rgba(255,255,255,0.5)" }}>
              · {post.time} ago
            </span>
            <div style={{ flex: 1 }} />
            <span
              style={{
                fontSize: 11,

                fontWeight: 600,

                color: fandom.color,

                background: `${fandom.color}22`,

                border: `1px solid ${fandom.color}55`,

                padding: "3px 8px",

                borderRadius: 20,
              }}
            >
              {fandom.name}
            </span>
          </div>

          <div
            style={{
              fontSize: 16,

              fontWeight: 600,

              color: "#fff",

              lineHeight: 1.4,

              margin: "11px 0 10px",
            }}
          >
            {post.title}
          </div>

          <img
            src={u(post.photo, 640, 400)}
            alt=""
            style={{
              width: "100%",

              height: 178,

              objectFit: "cover",

              borderRadius: 12,

              display: "block",
            }}
          />

          <div
            style={{
              display: "flex",

              alignItems: "center",

              gap: 8,

              marginTop: 12,

              paddingTop: 10,

              borderTop: "1px solid rgba(255,255,255,0.1)",
            }}
          >
            <span style={{ fontSize: 13, color: "var(--muted)" }}>
              💬 24 · ❤️ 128
            </span>
            <div style={{ flex: 1 }} />
            <span style={{ fontSize: 12.5, color: "#7C5CFF", fontWeight: 600 }}>
              View post →
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}

export function AIChatSheet({ onClose }: { onClose: () => void }) {
  const [messages, setMessages] = useState([
    {
      role: "ai",

      text: "Hey! I'm your AI Fan Helper. Ask me anything about your favorite fandoms — lore, characters, events, recommendations, you name it.",
    },
  ])

  const [input, setInput] = useState("")

  const send = () => {
    if (!input.trim()) return

    setMessages((m) => [
      ...m,

      { role: "user", text: input },

      {
        role: "ai",

        text: `Great question about "${input}"! In the Fandom Verse, this is a topic that spans multiple universes. I'd recommend checking the latest posts on Explore first, then browsing the fandom stories for deeper lore.`,
      },
    ])

    setInput("")
  }

  return (
    <div
      className="flex flex-col h-full"
      style={{ background: "var(--app-bg)" }}
    >
      <div
        className="flex items-center gap-3 px-5 pt-4 pb-4 border-b"
        style={{ borderColor: "var(--border)" }}
      >
        <button
          onClick={onClose}
          style={{
            background: "none",

            border: "none",

            cursor: "pointer",

            color: "var(--muted)",
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
        <div
          style={{
            width: 36,

            height: 36,

            borderRadius: "50%",

            background: "#7C5CFF",

            display: "flex",

            alignItems: "center",

            justifyContent: "center",

            fontSize: 16,
          }}
        >
          🤖
        </div>
        <div>
          <div
            style={{
              fontFamily: "Space Grotesk",

              fontSize: 15,

              fontWeight: 600,

              color: "var(--text)",
            }}
          >
            AI Fan Helper
          </div>
          <div style={{ fontSize: 12, color: "#7C5CFF" }}>● Online</div>
        </div>
      </div>

      <div className="flex-1 overflow-y-auto px-4 py-4 flex flex-col gap-3">
        {messages.map((m, i) => (
          <div
            key={i}
            style={{
              display: "flex",

              justifyContent: m.role === "user" ? "flex-end" : "flex-start",
            }}
          >
            <div
              style={{
                maxWidth: "80%",

                padding: "10px 14px",

                borderRadius:
                  m.role === "user"
                    ? "14px 14px 4px 14px"
                    : "14px 14px 14px 4px",

                background: m.role === "user" ? "#7C5CFF" : "var(--surface)",

                color: "var(--text)",

                fontSize: 14,

                lineHeight: 1.5,

                border: m.role === "ai" ? "1px solid var(--border)" : "none",
              }}
            >
              {m.text}
            </div>
          </div>
        ))}
      </div>

      <div
        className="px-4 pb-6 pt-3 flex gap-2"
        style={{ borderTop: "1px solid var(--border)" }}
      >
        <input
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && send()}
          placeholder="Ask about any fandom…"
          style={{
            flex: 1,

            background: "var(--surface)",

            border: "1.5px solid var(--border)",

            borderRadius: 50,

            padding: "11px 16px",

            color: "var(--text)",

            fontSize: 14,

            fontFamily: "Inter",

            outline: "none",
          }}
          onFocus={(e) => (e.target.style.borderColor = "#7C5CFF")}
          onBlur={(e) => (e.target.style.borderColor = "var(--border)")}
        />
        <button
          onClick={send}
          style={{
            width: 44,

            height: 44,

            borderRadius: "50%",

            background: "#7C5CFF",

            border: "none",

            cursor: "pointer",

            display: "flex",

            alignItems: "center",

            justifyContent: "center",

            flexShrink: 0,
          }}
        >
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="white"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <line x1="22" y1="2" x2="11" y2="13" />
            <polygon points="22 2 15 22 11 13 2 9 22 2" />
          </svg>
        </button>
      </div>
    </div>
  )
}
