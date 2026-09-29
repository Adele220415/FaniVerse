import { useState, type CSSProperties, type ReactNode } from "react"
import BackButton from "../../components/BackButton"

type Media = {
  kind: "image" | "video"
  src: string
  duration?: string
}

type Author = {
  name: string
  handle: string
  avatar: string
  verified: boolean
}

type Community = {
  name: string
  handle: string
  category: string
  description: string
  banner: string
  img: string
  color: string
  owner: Author
  members: number
  followers: number
  following: boolean
}

type Post = {
  id: string
  community: string
  author: Author
  time: string
  text: string
  media?: Media[]
  replies: number
  reposts: number
  likes: number
  views: number
  liked: boolean
  reposted: boolean
  repostedBy?: string
}

type Comment = {
  id: string
  author: Author
  time: string
  text: string
  likes: number
  liked: boolean
}

const u = (id: string, w: number, h: number) =>
  `https://images.unsplash.com/${id}?w=${w}&h=${h}&fit=crop&auto=format`

const fmt = (n: number) =>
  n >= 1_000_000
    ? `${(n / 1_000_000).toFixed(1).replace(/\.0$/, "")}M`
    : n >= 1_000
      ? `${(n / 1_000).toFixed(1).replace(/\.0$/, "")}K`
      : `${n}`

const seedCommunities: Community[] = [
  {
    name: "Anime",
    handle: "animeverse",
    category: "Anime",
    description:
      "Seasonal anime discussion, manga theories, and fan art — all in one verse.",
    banner: u("photo-1578632767115-351597cf2477", 780, 340),
    img: u("photo-1578632767115-351597cf2477", 120, 120),
    color: "#FF6B5C",
    owner: {
      name: "Sakura Lane",
      handle: "sakuralane",
      avatar: u("photo-1544005313-94ddf0286df2", 80, 80),
      verified: true,
    },
    members: 2_100_000,
    followers: 45_800,
    following: false,
  },
  {
    name: "Gaming",
    handle: "gamingverse",
    category: "Gaming",
    description:
      "News, drops, and everything Rockstar Games (news, game involvement, content).",
    banner: u("photo-1511512578047-dfb367046420", 780, 340),
    img: u("photo-1511512578047-dfb367046420", 120, 120),
    color: "#7C5CFF",
    owner: {
      name: "ben",
      handle: "videotech",
      avatar: u("photo-1500648767791-00dcc994a43e", 80, 80),
      verified: true,
    },
    members: 3_400_000,
    followers: 2_300,
    following: true,
  },
  {
    name: "Marvel",
    handle: "marvelverse",
    category: "Marvel",
    description:
      "Trailer breakdowns, Easter eggs, and MCU theories from fans who never miss a post-credit scene.",
    banner: u("photo-1608889335941-32ac5f2041b9", 780, 340),
    img: u("photo-1608889335941-32ac5f2041b9", 120, 120),
    color: "#e23636",
    owner: {
      name: "Maya Rivera",
      handle: "mayacomics",
      avatar: u("photo-1494790108377-be9c29b29330", 80, 80),
      verified: true,
    },
    members: 5_200_000,
    followers: 88_000,
    following: false,
  },
  {
    name: "K-Pop",
    handle: "kpopverse",
    category: "K-Pop",
    description:
      "Comeback schedules, tour dates, and fan projects for every group you stream.",
    banner: u("photo-1571380401583-72ca84994796", 780, 340),
    img: u("photo-1571380401583-72ca84994796", 120, 120),
    color: "#FF6B5C",
    owner: {
      name: "Sana Ito",
      handle: "sanaverse",
      avatar: u("photo-1438761681033-6461ffad8d80", 80, 80),
      verified: true,
    },
    members: 1_800_000,
    followers: 34_200,
    following: false,
  },
  {
    name: "Sci-Fi",
    handle: "scifiverse",
    category: "Sci-Fi",
    description:
      "Dune, Star Trek, and everything beyond the jump — books, films, and theories.",
    banner: u("photo-1446776877081-d282a0f896e2", 780, 340),
    img: u("photo-1446776877081-d282a0f896e2", 120, 120),
    color: "#22c55e",
    owner: {
      name: "Leo Park",
      handle: "leobuilds",
      avatar: u("photo-1507003211169-0a1dd7228f2d", 80, 80),
      verified: false,
    },
    members: 960_000,
    followers: 12_100,
    following: false,
  },
  {
    name: "Star Wars",
    handle: "starwarsverse",
    category: "Star Wars",
    description:
      "Cantina chatter, lore deep-dives, and celebration recaps across the galaxy.",
    banner: u("photo-1606041008023-472dfb5e530f", 780, 340),
    img: u("photo-1606041008023-472dfb5e530f", 120, 120),
    color: "#7C5CFF",
    owner: {
      name: "Star Wars",
      handle: "starwars",
      avatar: u("photo-1606041008023-472dfb5e530f", 80, 80),
      verified: true,
    },
    members: 4_100_000,
    followers: 61_500,
    following: false,
  },
]

const seedPosts: Post[] = [
  {
    id: "c-g1",
    community: "Gaming",
    author: {
      name: "Vinewood Motors",
      handle: "Vinewood_Mods",
      avatar: u("photo-1542751371-adc38448a05e", 80, 80),
      verified: true,
    },
    time: "3m",
    text: "This Week's GTA Online Stream Schedule!\n\n• Mon – Crew Sell Session (PS5)\n• Wednesday – Crew Bonuses Session (PS5)\n• Friday – Playlist Stream (PS5)\n• Sun – Random Playlist Stream (PC)",
    replies: 12,
    reposts: 64,
    likes: 980,
    views: 31_000,
    liked: false,
    reposted: false,
  },
  {
    id: "c-g2",
    community: "Gaming",
    repostedBy: "ben",
    author: {
      name: "Joel Franco",
      handle: "OfficialJoeF",
      avatar: u("photo-1500648767791-00dcc994a43e", 80, 80),
      verified: true,
    },
    time: "Sep 24",
    text: "Welcome to Vice City 🔥",
    media: [
      {
        kind: "video",
        src: u("photo-1493711662062-fa541adb3fc8", 720, 450),
        duration: "0:19",
      },
    ],
    replies: 38,
    reposts: 353,
    likes: 4_600,
    views: 488_000,
    liked: false,
    reposted: false,
  },
  {
    id: "c-g3",
    community: "Gaming",
    author: {
      name: "iGrandTheftAuto",
      handle: "iGrandTheftAuto",
      avatar: u("photo-1493711662062-fa541adb3fc8", 80, 80),
      verified: true,
    },
    time: "14h",
    text: "Jason and Lucia's suspected actors – Dylan Rourke and Manni L. Perez – have both verified their Instagram accounts this month 👀\n\nNeither actor has confirmed a role in GTA 6, which seems unlikely before release following Rockstar's NDA reminder to performers last week.",
    media: [
      { kind: "image", src: u("photo-1542751371-adc38448a05e", 420, 340) },
      { kind: "image", src: u("photo-1511512578047-dfb367046420", 420, 340) },
    ],
    replies: 214,
    reposts: 1_800,
    likes: 9_400,
    views: 210_000,
    liked: false,
    reposted: false,
  },
  {
    id: "c-g4",
    community: "Gaming",
    author: {
      name: "Kestrel",
      handle: "kestrelplays",
      avatar: u("photo-1507003211169-0a1dd7228f2d", 80, 80),
      verified: false,
    },
    time: "1h",
    text: "Finally cleared the new raid — that final boss fight was unreal. Who's down for a run tonight? #GTA6",
    replies: 24,
    reposts: 9,
    likes: 340,
    views: 12_400,
    liked: false,
    reposted: false,
  },
  {
    id: "c-g5",
    community: "Gaming",
    author: {
      name: "Lorekeeper",
      handle: "lorekeeper",
      avatar: u("photo-1511512578047-dfb367046420", 80, 80),
      verified: false,
    },
    time: "5h",
    text: "The hidden lore behind Elden Ring's ending — full video breakdown is up 🎬",
    media: [
      { kind: "image", src: u("photo-1612036782180-6f0b6cd846fe", 720, 450) },
    ],
    replies: 56,
    reposts: 120,
    likes: 2_100,
    views: 74_000,
    liked: false,
    reposted: false,
  },
  {
    id: "c-a1",
    community: "Anime",
    author: {
      name: "Sakura Lane",
      handle: "sakuralane",
      avatar: u("photo-1544005313-94ddf0286df2", 80, 80),
      verified: true,
    },
    time: "2h",
    text: "#AoT changed anime forever. Here's our final chapter breakdown — the full thread is live 🧵",
    media: [
      { kind: "image", src: u("photo-1578632767115-351597cf2477", 720, 450) },
    ],
    replies: 92,
    reposts: 410,
    likes: 5_200,
    views: 156_000,
    liked: false,
    reposted: false,
  },
  {
    id: "c-a2",
    community: "Anime",
    author: {
      name: "Mika",
      handle: "mikadraws",
      avatar: u("photo-1612036782180-6f0b6cd846fe", 80, 80),
      verified: false,
    },
    time: "6h",
    text: "Weekend fan art drop 🎨 which style should I do next?",
    media: [
      { kind: "image", src: u("photo-1578632767115-351597cf2477", 420, 340) },
      { kind: "image", src: u("photo-1608889335941-32ac5f2041b9", 420, 340) },
    ],
    replies: 41,
    reposts: 88,
    likes: 1_600,
    views: 39_000,
    liked: false,
    reposted: false,
  },
  {
    id: "c-m1",
    community: "Marvel",
    author: {
      name: "Maya Rivera",
      handle: "mayacomics",
      avatar: u("photo-1494790108377-be9c29b29330", 80, 80),
      verified: true,
    },
    time: "4h",
    text: "Every Easter egg in the new Secret Wars trailer 🔍 pause at 0:42 and thank me later.",
    media: [
      { kind: "image", src: u("photo-1608889335941-32ac5f2041b9", 720, 450) },
    ],
    replies: 130,
    reposts: 640,
    likes: 7_800,
    views: 302_000,
    liked: false,
    reposted: false,
  },
  {
    id: "c-k1",
    community: "K-Pop",
    author: {
      name: "Sana Ito",
      handle: "sanaverse",
      avatar: u("photo-1438761681033-6461ffad8d80", 80, 80),
      verified: true,
    },
    time: "8h",
    text: "BLACKPINK world tour 2026 dates confirmed 🖤💖 Full schedule just dropped — which city are you hitting?",
    media: [
      { kind: "image", src: u("photo-1571380401583-72ca84994796", 720, 450) },
    ],
    replies: 288,
    reposts: 1_900,
    likes: 14_300,
    views: 611_000,
    liked: false,
    reposted: false,
  },
  {
    id: "c-s1",
    community: "Sci-Fi",
    author: {
      name: "Leo Park",
      handle: "leobuilds",
      avatar: u("photo-1507003211169-0a1dd7228f2d", 80, 80),
      verified: false,
    },
    time: "1d",
    text: "Dune: Messiah — everything we know so far. Casting rumors, release window, and what the trailers hint at.",
    replies: 64,
    reposts: 210,
    likes: 3_100,
    views: 88_000,
    liked: false,
    reposted: false,
  },
  {
    id: "c-w1",
    community: "Star Wars",
    author: {
      name: "Star Wars",
      handle: "starwars",
      avatar: u("photo-1606041008023-472dfb5e530f", 80, 80),
      verified: true,
    },
    time: "1d",
    text: "Recapping Star Wars Celebration — the panels, the drops, and that surprise cameo 👀",
    media: [
      { kind: "image", src: u("photo-1606041008023-472dfb5e530f", 720, 450) },
    ],
    replies: 176,
    reposts: 920,
    likes: 8_900,
    views: 402_000,
    liked: false,
    reposted: false,
  },
]

const trending = [
  { tag: "GTA 6", posts: 128_000, postId: "c-g3" },
  { tag: "Elden Ring", posts: 54_200, postId: "c-g5" },
  { tag: "#AoT", posts: 41_800, postId: "c-a1" },
  { tag: "BLACKPINK", posts: 33_500, postId: "c-k1" },
  { tag: "Secret Wars", posts: 22_400, postId: "c-m1" },
]

const cAuthor = (
  name: string,
  handle: string,
  photo: string,
  verified = false,
): Author => ({
  name,
  handle,
  avatar: u(photo, 80, 80),
  verified,
})

const seedComments: Record<string, Comment[]> = {
  "c-g3": [
    {
      id: "cm-g3-1",
      author: cAuthor(
        "Kestrel",
        "kestrelplays",
        "photo-1507003211169-0a1dd7228f2d",
      ),
      time: "9m",
      text: "Manni L. Perez would be an unreal Lucia. The wait is actually killing me 😭",
      likes: 412,
      liked: false,
    },
    {
      id: "cm-g3-2",
      author: cAuthor(
        "Lorekeeper",
        "lorekeeper",
        "photo-1511512578047-dfb367046420",
      ),
      time: "22m",
      text: "Rockstar's NDA is doing heavy lifting right now — nothing gets confirmed until release week.",
      likes: 128,
      liked: false,
    },
    {
      id: "cm-g3-3",
      author: cAuthor(
        "ben",
        "videotech",
        "photo-1500648767791-00dcc994a43e",
        true,
      ),
      time: "41m",
      text: "Both accounts following each other is the real hint 👀",
      likes: 96,
      liked: false,
    },
  ],
  "c-g5": [
    {
      id: "cm-g5-1",
      author: cAuthor("Mika", "mikadraws", "photo-1612036782180-6f0b6cd846fe"),
      time: "1h",
      text: "The Age of Stars ending still lives in my head rent free.",
      likes: 233,
      liked: false,
    },
    {
      id: "cm-g5-2",
      author: cAuthor(
        "Kestrel",
        "kestrelplays",
        "photo-1507003211169-0a1dd7228f2d",
      ),
      time: "2h",
      text: "Drop the timestamp for the final section, I need to rewatch it 🎬",
      likes: 74,
      liked: false,
    },
    {
      id: "cm-g5-3",
      author: cAuthor(
        "Leo Park",
        "leobuilds",
        "photo-1507003211169-0a1dd7228f2d",
      ),
      time: "3h",
      text: "Best breakdown I've seen on this — subscribing for the next one.",
      likes: 51,
      liked: false,
    },
  ],
  "c-a1": [
    {
      id: "cm-a1-1",
      author: cAuthor(
        "Maya Rivera",
        "mayacomics",
        "photo-1494790108377-be9c29b29330",
        true,
      ),
      time: "1h",
      text: "#AoT really redefined what a finale could be. That last panel hit hard.",
      likes: 640,
      liked: false,
    },
    {
      id: "cm-a1-2",
      author: cAuthor("Mika", "mikadraws", "photo-1612036782180-6f0b6cd846fe"),
      time: "2h",
      text: "Drawing the final scene as we speak 🎨",
      likes: 188,
      liked: false,
    },
    {
      id: "cm-a1-3",
      author: cAuthor(
        "Sana Ito",
        "sanaverse",
        "photo-1438761681033-6461ffad8d80",
        true,
      ),
      time: "4h",
      text: "The score alone deserves its own thread.",
      likes: 97,
      liked: false,
    },
  ],
  "c-k1": [
    {
      id: "cm-k1-1",
      author: cAuthor("Mika", "mikadraws", "photo-1612036782180-6f0b6cd846fe"),
      time: "3h",
      text: "Seoul date secured 🖤 which city is everyone flying for?",
      likes: 512,
      liked: false,
    },
    {
      id: "cm-k1-2",
      author: cAuthor(
        "Maya Rivera",
        "mayacomics",
        "photo-1494790108377-be9c29b29330",
        true,
      ),
      time: "5h",
      text: "The setlist leaks are wild if they're true 👀",
      likes: 205,
      liked: false,
    },
    {
      id: "cm-k1-3",
      author: cAuthor(
        "Kestrel",
        "kestrelplays",
        "photo-1507003211169-0a1dd7228f2d",
      ),
      time: "6h",
      text: "Presale code please, I am begging 🙏",
      likes: 143,
      liked: false,
    },
  ],
  "c-m1": [
    {
      id: "cm-m1-1",
      author: cAuthor(
        "Leo Park",
        "leobuilds",
        "photo-1507003211169-0a1dd7228f2d",
      ),
      time: "1h",
      text: "0:42 confirmed, I went back three times 😂",
      likes: 388,
      liked: false,
    },
    {
      id: "cm-m1-2",
      author: cAuthor(
        "Kestrel",
        "kestrelplays",
        "photo-1507003211169-0a1dd7228f2d",
      ),
      time: "2h",
      text: "Every Fox universe nod in one trailer is criminal. In a good way.",
      likes: 152,
      liked: false,
    },
    {
      id: "cm-m1-3",
      author: cAuthor(
        "Sakura Lane",
        "sakuralane",
        "photo-1544005313-94ddf0286df2",
        true,
      ),
      time: "3h",
      text: "The Doom silhouette at the end — we are so not ready.",
      likes: 274,
      liked: false,
    },
  ],
}

const mediaPresets = [
  u("photo-1542751371-adc38448a05e", 240, 180),
  u("photo-1578632767115-351597cf2477", 240, 180),
  u("photo-1608889335941-32ac5f2041b9", 240, 180),
]

const ME: Author = {
  name: "Alex Kim",
  handle: "alexkim",
  avatar: u("photo-1519345182560-3f2917c472ef", 80, 80),
  verified: false,
}

const sectionTitle: CSSProperties = {
  fontFamily: "Space Grotesk",
  fontSize: 16,
  fontWeight: 600,
  color: "var(--text)",
}

const iconButton: CSSProperties = {
  width: 34,
  height: 34,
  borderRadius: "50%",
  border: "none",
  background: "none",
  color: "var(--text)",
  display: "flex",
  alignItems: "center",
  justifyContent: "center",
  cursor: "pointer",
  flexShrink: 0,
  padding: 0,
}

function VerifiedBadge({ size = 15 }: { size?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none">
      <path
        d="M12 1.5l2.38 2.1 3.2-.42 1.1 3.03 3.03 1.1-.42 3.2L23.5 12l-2.1 2.38.42 3.2-3.03 1.1-1.1 3.03-3.2.42L12 22.5l-2.38-2.1-3.2.42-1.1-3.03-3.03-1.1.42-3.2L.5 12l2.1-2.38-.42-3.2 3.03-1.1 1.1-3.03 3.2-.42L12 1.5z"
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

type AvatarProps = {
  src: string
  size?: number
}

function Avatar({ src, size = 40 }: AvatarProps) {
  return (
    <img
      src={src}
      alt=""
      style={{
        width: size,
        height: size,
        borderRadius: "50%",
        objectFit: "cover",
        flexShrink: 0,
        border: "1px solid var(--border)",
      }}
    />
  )
}

function Action({
  children,
  count,
  active,
  color,
  filled,
  onClick,
}: {
  children: ReactNode
  count?: number
  active?: boolean
  color: string
  filled?: boolean
  onClick?: (e: React.MouseEvent) => void
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
        padding: 0,
        cursor: onClick ? "pointer" : "default",
        color: active ? color : "var(--muted)",
        fontSize: 13,
        fontFamily: "Inter",
        transition: "color 0.15s",
      }}
    >
      <svg
        width="17"
        height="17"
        viewBox="0 0 24 24"
        fill={active && filled ? "currentColor" : "none"}
        stroke="currentColor"
        strokeWidth="1.7"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        {children}
      </svg>
      {count !== undefined ? <span>{fmt(count)}</span> : null}
    </button>
  )
}

function PostCard({
  post,
  communityColor,
  onOpen,
  onLike,
  onRepost,
}: {
  post: Post
  communityColor?: string
  onOpen?: () => void
  onLike: () => void
  onRepost: () => void
}) {
  const stop = (fn: () => void) => (e: React.MouseEvent) => {
    e.stopPropagation()
    fn()
  }

  return (
    <article
      onClick={onOpen}
      style={{
        display: "flex",
        gap: 12,
        padding: "14px 16px",
        borderBottom: "1px solid var(--border)",
        cursor: onOpen ? "pointer" : "default",
        background: "transparent",
      }}
    >
      <div className="flex flex-col items-center" style={{ gap: 8 }}>
        <Avatar src={post.author.avatar} size={40} />
        {post.repostedBy && (
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
            <path d="M17 1l4 4-4 4" />
            <path d="M3 21v-4a4 4 0 014-4h14" />
            <path d="M7 23l-4-4 4-4" />
          </svg>
        )}
      </div>

      <div style={{ flex: 1, minWidth: 0 }}>
        {post.repostedBy && (
          <div
            style={{
              fontSize: 13,
              color: "var(--muted)",
              marginBottom: 2,
              display: "flex",
              alignItems: "center",
              gap: 5,
            }}
          >
            <svg
              width="13"
              height="13"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M17 1l4 4-4 4" />
              <path d="M3 21v-4a4 4 0 014-4h14" />
              <path d="M7 23l-4-4 4-4" />
            </svg>
            {post.repostedBy} reposted
          </div>
        )}

        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 4,
            fontSize: 15,
            minWidth: 0,
          }}
        >
          <span
            style={{
              fontWeight: 700,
              color: "var(--text)",
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
              maxWidth: "45%",
            }}
          >
            {post.author.name}
          </span>
          {post.author.verified && <VerifiedBadge size={15} />}
          <span
            style={{
              color: "var(--muted)",
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
              minWidth: 0,
            }}
          >
            @{post.author.handle}
          </span>
          <span style={{ color: "var(--muted)", flexShrink: 0 }}>
            · {post.time}
          </span>
          <span
            style={{
              marginLeft: "auto",
              color: "var(--muted)",
              flexShrink: 0,
              letterSpacing: 1,
              paddingLeft: 8,
            }}
          >
            ···
          </span>
        </div>

        <div
          style={{
            fontSize: 15,
            color: "var(--text)",
            lineHeight: 1.45,
            whiteSpace: "pre-wrap",
            marginTop: 3,
            wordBreak: "break-word",
          }}
        >
          {post.text}
        </div>

        {communityColor && (
          <span
            style={{
              display: "inline-block",
              fontSize: 11,
              fontWeight: 600,
              color: communityColor,
              background: `${communityColor}1f`,
              padding: "2px 8px",
              borderRadius: 4,
              marginTop: 8,
            }}
          >
            {post.community}
          </span>
        )}

        {post.media && (
          <div
            style={{
              display: "grid",
              gap: 6,
              gridTemplateColumns: post.media.length === 2 ? "1fr 1fr" : "1fr",
              marginTop: 10,
              borderRadius: 14,
              overflow: "hidden",
            }}
          >
            {post.media.map((m, i) => (
              <div
                key={i}
                style={{
                  position: "relative",
                  aspectRatio: post.media!.length === 2 ? "1/1" : "16/10",
                  background: "#000",
                }}
              >
                <img
                  src={m.src}
                  alt=""
                  style={{
                    width: "100%",
                    height: "100%",
                    objectFit: "cover",
                    display: "block",
                  }}
                />
                {m.kind === "video" && (
                  <>
                    <span
                      style={{
                        position: "absolute",
                        top: "50%",
                        left: "50%",
                        transform: "translate(-50%, -50%)",
                        width: 44,
                        height: 44,
                        borderRadius: "50%",
                        background: "rgba(0,0,0,0.55)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                      }}
                    >
                      <svg
                        width="18"
                        height="18"
                        viewBox="0 0 24 24"
                        fill="#fff"
                      >
                        <path d="M8 5v14l11-7z" />
                      </svg>
                    </span>
                    <span
                      style={{
                        position: "absolute",
                        bottom: 8,
                        left: 8,
                        fontSize: 11,
                        fontWeight: 600,
                        color: "#fff",
                        background: "rgba(0,0,0,0.65)",
                        padding: "2px 6px",
                        borderRadius: 4,
                      }}
                    >
                      {m.duration}
                    </span>
                    <span
                      style={{
                        position: "absolute",
                        bottom: 8,
                        right: 8,
                        width: 24,
                        height: 24,
                        borderRadius: "50%",
                        background: "rgba(0,0,0,0.65)",
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
                        <path d="M11 5L6 9H2v6h4l5 4V5z" />
                        <line x1="23" y1="9" x2="17" y2="15" />
                        <line x1="17" y1="9" x2="23" y2="15" />
                      </svg>
                    </span>
                  </>
                )}
              </div>
            ))}
          </div>
        )}

        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            marginTop: 12,
            maxWidth: 320,
          }}
        >
          <Action color="#1D9BF0" count={post.replies}>
            <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" />
          </Action>
          <Action
            color="#00BA7C"
            count={post.reposts}
            active={post.reposted}
            onClick={stop(onRepost)}
          >
            <path d="M17 1l4 4-4 4" />
            <path d="M3 21v-4a4 4 0 014-4h14" />
            <path d="M7 23l-4-4 4-4" />
          </Action>
          <Action
            color="#F91880"
            count={post.likes}
            active={post.liked}
            filled
            onClick={stop(onLike)}
          >
            <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
          </Action>
          <Action color="#1D9BF0" count={post.views}>
            <path d="M18 20V10" />
            <path d="M12 20V4" />
            <path d="M6 20v-6" />
          </Action>
          <Action color="#1D9BF0">
            <path d="M4 12v7a2 2 0 002 2h12a2 2 0 002-2v-7" />
            <path d="M16 6l-4-4-4 4" />
            <path d="M12 2v13" />
          </Action>
        </div>
      </div>
    </article>
  )
}

function CommentRow({
  comment,
  onLike,
}: {
  comment: Comment
  onLike: () => void
}) {
  return (
    <div
      style={{
        display: "flex",
        gap: 12,
        padding: "14px 16px",
        borderBottom: "1px solid var(--border)",
      }}
    >
      <Avatar src={comment.author.avatar} size={40} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 4,
            fontSize: 14,
            minWidth: 0,
            flexWrap: "wrap",
          }}
        >
          <span
            style={{
              fontWeight: 700,
              color: "var(--text)",
              maxWidth: "55%",
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
            }}
          >
            {comment.author.name}
          </span>
          {comment.author.verified && <VerifiedBadge size={14} />}
          <span
            style={{
              color: "var(--muted)",
              whiteSpace: "nowrap",
              overflow: "hidden",
              textOverflow: "ellipsis",
              minWidth: 0,
            }}
          >
            @{comment.author.handle}
          </span>
          <span style={{ color: "var(--muted)", flexShrink: 0 }}>
            · {comment.time}
          </span>
        </div>

        <div
          style={{
            fontSize: 14.5,
            color: "var(--text)",
            lineHeight: 1.45,
            whiteSpace: "pre-wrap",
            marginTop: 3,
            wordBreak: "break-word",
          }}
        >
          {comment.text}
        </div>

        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            marginTop: 10,
            maxWidth: 260,
          }}
        >
          <Action color="#1D9BF0">
            <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" />
          </Action>
          <Action color="#00BA7C">
            <path d="M17 1l4 4-4 4" />
            <path d="M3 21v-4a4 4 0 014-4h14" />
            <path d="M7 23l-4-4 4-4" />
          </Action>
          <Action
            color="#F91880"
            count={comment.likes}
            active={comment.liked}
            filled
            onClick={onLike}
          >
            <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
          </Action>
          <Action color="#1D9BF0">
            <path d="M4 12v7a2 2 0 002 2h12a2 2 0 002-2v-7" />
            <path d="M16 6l-4-4-4 4" />
            <path d="M12 2v13" />
          </Action>
        </div>
      </div>
    </div>
  )
}

function PostDetail({
  post,
  communityColor,
  comments,
  onBack,
  onLike,
  onRepost,
  onLikeComment,
  onReply,
}: {
  post: Post
  communityColor?: string
  comments: Comment[]
  onBack: () => void
  onLike: () => void
  onRepost: () => void
  onLikeComment: (commentId: string) => void
  onReply: (text: string) => void
}) {
  const [draft, setDraft] = useState("")

  const submit = () => {
    const text = draft.trim()
    if (!text) return
    onReply(text)
    setDraft("")
  }

  return (
    <div
      style={{
        position: "relative",
        height: "100%",
        display: "flex",
        flexDirection: "column",
        background: "var(--app-bg)",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          padding: "10px 12px",
          borderBottom: "1px solid var(--border)",
          flexShrink: 0,
          gap: 8,
        }}
      >
        <button onClick={onBack} aria-label="Back" style={iconButton}>
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
            <path d="M19 12H5" />
            <path d="M12 19l-7-7 7-7" />
          </svg>
        </button>
        <span
          style={{
            fontFamily: "Space Grotesk",
            fontSize: 17,
            fontWeight: 700,
            color: "var(--text)",
          }}
        >
          Post
        </span>
        <button
          aria-label="Share"
          style={{ ...iconButton, marginLeft: "auto" }}
        >
          <svg
            width="18"
            height="18"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="1.9"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M4 12v7a2 2 0 002 2h12a2 2 0 002-2v-7" />
            <path d="M16 6l-4-4-4 4" />
            <path d="M12 2v13" />
          </svg>
        </button>
        <button aria-label="More" style={iconButton}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
            <circle cx="5" cy="12" r="1.7" />
            <circle cx="12" cy="12" r="1.7" />
            <circle cx="19" cy="12" r="1.7" />
          </svg>
        </button>
      </div>

      <div
        className="flex-1 overflow-y-auto"
        style={{ background: "var(--app-bg)" }}
      >
        <div style={{ padding: "14px 16px 0" }}>
          <div style={{ display: "flex", gap: 12 }}>
            <Avatar src={post.author.avatar} size={44} />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 4,
                  minWidth: 0,
                }}
              >
                <span
                  style={{
                    fontWeight: 700,
                    fontSize: 15,
                    color: "var(--text)",
                    whiteSpace: "nowrap",
                    overflow: "hidden",
                    textOverflow: "ellipsis",
                  }}
                >
                  {post.author.name}
                </span>
                {post.author.verified && <VerifiedBadge size={15} />}
                <span
                  style={{
                    marginLeft: "auto",
                    color: "var(--muted)",
                    letterSpacing: 1,
                    flexShrink: 0,
                    paddingLeft: 8,
                  }}
                >
                  ···
                </span>
              </div>
              <div
                style={{
                  fontSize: 14,
                  color: "var(--muted)",
                  fontFamily: "Inter",
                  whiteSpace: "nowrap",
                  overflow: "hidden",
                  textOverflow: "ellipsis",
                }}
              >
                @{post.author.handle} · {post.time}
              </div>
            </div>
          </div>

          <div
            style={{
              fontSize: 16.5,
              color: "var(--text)",
              lineHeight: 1.5,
              whiteSpace: "pre-wrap",
              marginTop: 12,
              wordBreak: "break-word",
            }}
          >
            {post.text}
          </div>

          {communityColor && (
            <span
              style={{
                display: "inline-block",
                fontSize: 11,
                fontWeight: 600,
                color: communityColor,
                background: `${communityColor}1f`,
                padding: "2px 8px",
                borderRadius: 4,
                marginTop: 10,
              }}
            >
              {post.community}
            </span>
          )}

          {post.media && (
            <div
              style={{
                display: "grid",
                gap: 6,
                gridTemplateColumns:
                  post.media.length === 2 ? "1fr 1fr" : "1fr",
                marginTop: 12,
                borderRadius: 14,
                overflow: "hidden",
              }}
            >
              {post.media.map((m, i) => (
                <div
                  key={i}
                  style={{
                    position: "relative",
                    aspectRatio: post.media!.length === 2 ? "1/1" : "16/10",
                    background: "#000",
                  }}
                >
                  <img
                    src={m.src}
                    alt=""
                    style={{
                      width: "100%",
                      height: "100%",
                      objectFit: "cover",
                      display: "block",
                    }}
                  />
                  {m.kind === "video" && (
                    <>
                      <span
                        style={{
                          position: "absolute",
                          top: "50%",
                          left: "50%",
                          transform: "translate(-50%, -50%)",
                          width: 44,
                          height: 44,
                          borderRadius: "50%",
                          background: "rgba(0,0,0,0.55)",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                        }}
                      >
                        <svg
                          width="18"
                          height="18"
                          viewBox="0 0 24 24"
                          fill="#fff"
                        >
                          <path d="M8 5v14l11-7z" />
                        </svg>
                      </span>
                      <span
                        style={{
                          position: "absolute",
                          bottom: 8,
                          left: 8,
                          fontSize: 11,
                          fontWeight: 600,
                          color: "#fff",
                          background: "rgba(0,0,0,0.65)",
                          padding: "2px 6px",
                          borderRadius: 4,
                        }}
                      >
                        {m.duration}
                      </span>
                    </>
                  )}
                </div>
              ))}
            </div>
          )}
        </div>

        <div
          style={{
            padding: "14px 16px",
            borderBottom: "1px solid var(--border)",
            fontSize: 14,
            color: "var(--muted)",
            fontFamily: "Inter",
          }}
        >
          {fmt(post.views)} views · {fmt(post.reposts)} reposts ·{" "}
          {fmt(post.likes)} likes
        </div>

        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            padding: "6px 20px",
            borderBottom: "1px solid var(--border)",
          }}
        >
          <Action color="#1D9BF0" count={post.replies}>
            <path d="M21 11.5a8.38 8.38 0 01-.9 3.8 8.5 8.5 0 01-7.6 4.7 8.38 8.38 0 01-3.8-.9L3 21l1.9-5.7a8.38 8.38 0 01-.9-3.8 8.5 8.5 0 014.7-7.6 8.38 8.38 0 013.8-.9h.5a8.48 8.48 0 018 8v.5z" />
          </Action>
          <Action
            color="#00BA7C"
            count={post.reposts}
            active={post.reposted}
            onClick={onRepost}
          >
            <path d="M17 1l4 4-4 4" />
            <path d="M3 21v-4a4 4 0 014-4h14" />
            <path d="M7 23l-4-4 4-4" />
          </Action>
          <Action
            color="#F91880"
            count={post.likes}
            active={post.liked}
            filled
            onClick={onLike}
          >
            <path d="M20.84 4.61a5.5 5.5 0 00-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 00-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 000-7.78z" />
          </Action>
          <Action color="#1D9BF0">
            <path d="M18 20V10" />
            <path d="M12 20V4" />
            <path d="M6 20v-6" />
          </Action>
          <Action color="#1D9BF0">
            <path d="M4 12v7a2 2 0 002 2h12a2 2 0 002-2v-7" />
            <path d="M16 6l-4-4-4 4" />
            <path d="M12 2v13" />
          </Action>
        </div>

        {comments.length === 0 ? (
          <div
            style={{
              padding: "40px 20px",
              textAlign: "center",
              fontSize: 14,
              color: "var(--muted)",
              fontFamily: "Inter",
              lineHeight: 1.6,
            }}
          >
            No replies yet.
            <br />
            Be the first to reply.
          </div>
        ) : (
          comments.map((c) => (
            <CommentRow
              key={c.id}
              comment={c}
              onLike={() => onLikeComment(c.id)}
            />
          ))
        )}

        <div style={{ height: 12 }} />
      </div>

      <div
        style={{
          display: "flex",
          alignItems: "center",
          gap: 10,
          padding: "10px 14px",
          borderTop: "1px solid var(--border)",
          background: "var(--app-bg)",
          flexShrink: 0,
        }}
      >
        <Avatar src={ME.avatar} size={34} />
        <input
          value={draft}
          onChange={(e) => setDraft(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") submit()
          }}
          placeholder="Post your reply"
          style={{
            flex: 1,
            minWidth: 0,
            background: "var(--surface)",
            border: "1.5px solid var(--border)",
            borderRadius: 999,
            padding: "10px 14px",
            color: "var(--text)",
            fontSize: 14,
            fontFamily: "Inter",
            outline: "none",
          }}
          onFocus={(e) => (e.target.style.borderColor = "#7C5CFF")}
          onBlur={(e) => (e.target.style.borderColor = "var(--border)")}
        />
        <button
          onClick={submit}
          disabled={!draft.trim()}
          style={{
            background: draft.trim() ? "#7C5CFF" : "var(--border)",
            border: "none",
            color: draft.trim() ? "#fff" : "var(--muted-3)",
            fontSize: 13,
            fontWeight: 700,
            fontFamily: "Inter",
            cursor: draft.trim() ? "pointer" : "default",
            padding: "9px 16px",
            borderRadius: 999,
            flexShrink: 0,
          }}
        >
          Reply
        </button>
      </div>
    </div>
  )
}

function ComposeOverlay({
  community,
  onClose,
  onPost,
}: {
  community: Community
  onClose: () => void
  onPost: (text: string, media?: Media[]) => void
}) {
  const [text, setText] = useState("")
  const [image, setImage] = useState<string | null>(null)
  const canPost = text.trim().length > 0 && text.length <= 280

  const submit = () => {
    if (!canPost) return
    onPost(text.trim(), image ? [{ kind: "image", src: image }] : undefined)
    onClose()
  }

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        zIndex: 40,
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          display: "flex",
          alignItems: "center",
          justifyContent: "space-between",
          padding: "12px 16px",
          borderBottom: "1px solid var(--border)",
          flexShrink: 0,
        }}
      >
        <BackButton
          onClick={onClose}
          label="Back"
          size={20}
          color="var(--muted)"
        />
        <span
          style={{
            fontFamily: "Space Grotesk",
            fontSize: 16,
            fontWeight: 700,
            color: "var(--text)",
          }}
        >
          New post
        </span>
        <button
          onClick={submit}
          disabled={!canPost}
          style={{
            background: canPost ? "#7C5CFF" : "var(--border)",
            border: "none",
            color: canPost ? "#fff" : "var(--muted-3)",
            fontSize: 14,
            fontWeight: 600,
            fontFamily: "Inter",
            cursor: canPost ? "pointer" : "default",
            padding: "7px 18px",
            borderRadius: 999,
          }}
        >
          Post
        </button>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 16px 24px" }}>
        <div style={{ display: "flex", gap: 12 }}>
          <Avatar src={ME.avatar} size={40} />
          <div style={{ flex: 1, minWidth: 0 }}>
            <div
              style={{
                display: "inline-flex",
                alignItems: "center",
                gap: 6,
                border: "1px solid var(--border)",
                borderRadius: 999,
                padding: "4px 12px",
                fontSize: 12,
                color: "var(--muted)",
                fontFamily: "Inter",
                marginBottom: 12,
              }}
            >
              Posting to
              <span style={{ color: community.color, fontWeight: 600 }}>
                {community.name}
              </span>
            </div>
            <textarea
              autoFocus
              value={text}
              maxLength={280}
              onChange={(e) => setText(e.target.value)}
              placeholder="What's happening in the community?"
              style={{
                width: "100%",
                minHeight: 150,
                background: "transparent",
                border: "none",
                outline: "none",
                resize: "none",
                color: "var(--text)",
                fontSize: 16,
                fontFamily: "Inter",
                lineHeight: 1.5,
              }}
            />
          </div>
        </div>

        <div style={{ marginTop: 20 }}>
          <div
            style={{
              fontSize: 12,
              color: "var(--muted)",
              fontFamily: "Inter",
              marginBottom: 8,
            }}
          >
            Add media (optional)
          </div>
          <div style={{ display: "flex", gap: 8 }}>
            {mediaPresets.map((src) => (
              <button
                key={src}
                onClick={() => setImage(image === src ? null : src)}
                style={{
                  padding: 0,
                  width: 78,
                  height: 60,
                  borderRadius: 10,
                  overflow: "hidden",
                  cursor: "pointer",
                  background: "none",
                  border: `2px solid ${
                    image === src ? "#7C5CFF" : "var(--border)"
                  }`,
                }}
              >
                <img
                  src={src}
                  alt=""
                  style={{
                    width: "100%",
                    height: "100%",
                    objectFit: "cover",
                    display: "block",
                  }}
                />
              </button>
            ))}
          </div>
        </div>
      </div>

      <div
        style={{
          padding: "12px 16px",
          borderTop: "1px solid var(--border)",
          display: "flex",
          justifyContent: "space-between",
          alignItems: "center",
          flexShrink: 0,
        }}
      >
        <span
          style={{
            fontSize: 12,
            fontFamily: "Inter",
            color: text.length > 250 ? "#FF6B5C" : "var(--muted)",
          }}
        >
          {text.length}/280
        </span>
        <span
          style={{ fontSize: 12, fontFamily: "Inter", color: "var(--muted)" }}
        >
          Posts to {community.name}
        </span>
      </div>
    </div>
  )
}

export default function CommunityTab({
  onBack,
  initialName,
}: {
  onBack: () => void
  initialName?: string | null
}) {
  const [communities, setCommunities] = useState<Community[]>(seedCommunities)
  const [posts, setPosts] = useState<Post[]>(seedPosts)
  const [view, setView] = useState<"directory" | "detail">(
    initialName ? "detail" : "directory",
  )
  const [origin, setOrigin] = useState<"explore" | "directory">(
    initialName ? "explore" : "directory",
  )
  const [selected, setSelected] = useState(() => {
    const hit = seedCommunities.find(
      (c) => c.name === initialName || c.category === initialName,
    )
    return (hit ?? seedCommunities[0]).name
  })
  const [query, setQuery] = useState("")
  const [filter, setFilter] = useState("All")
  const [composing, setComposing] = useState(false)
  const [openPostId, setOpenPostId] = useState<string | null>(null)
  const [replies, setReplies] =
    useState<Record<string, Comment[]>>(seedComments)

  const community =
    communities.find((c) => c.name === selected) ?? communities[0]

  const chips = [
    "All",
    ...Array.from(new Set(communities.map((c) => c.category))),
  ]

  const categoryOf = (name: string) =>
    communities.find((c) => c.name === name)?.category

  const colorOf = (name: string) =>
    communities.find((c) => c.name === name)?.color

  const q = query.trim().toLowerCase()

  const visibleCommunities = communities.filter(
    (c) =>
      (filter === "All" || c.category === filter) &&
      (!q ||
        c.name.toLowerCase().includes(q) ||
        c.handle.toLowerCase().includes(q) ||
        c.category.toLowerCase().includes(q)),
  )

  const visiblePosts = posts.filter(
    (p) =>
      (filter === "All" || categoryOf(p.community) === filter) &&
      (!q ||
        p.text.toLowerCase().includes(q) ||
        p.author.name.toLowerCase().includes(q) ||
        p.community.toLowerCase().includes(q)),
  )

  const toggleLike = (id: string) =>
    setPosts((ps) =>
      ps.map((p) =>
        p.id === id
          ? { ...p, liked: !p.liked, likes: p.likes + (p.liked ? -1 : 1) }
          : p,
      ),
    )

  const toggleRepost = (id: string) =>
    setPosts((ps) =>
      ps.map((p) =>
        p.id === id
          ? {
              ...p,
              reposted: !p.reposted,
              reposts: p.reposts + (p.reposted ? -1 : 1),
            }
          : p,
      ),
    )

  const toggleFollow = (name: string) =>
    setCommunities((cs) =>
      cs.map((c) =>
        c.name === name
          ? {
              ...c,
              following: !c.following,
              followers: c.followers + (c.following ? -1 : 1),
            }
          : c,
      ),
    )

  const openDetail = (name: string) => {
    setSelected(name)
    setOrigin("directory")
    setView("detail")
  }

  const openPost = (id: string) => {
    if (posts.some((p) => p.id === id)) setOpenPostId(id)
  }

  const addReply = (postId: string, text: string) => {
    setReplies((r) => ({
      ...r,
      [postId]: [
        ...(r[postId] ?? []),
        {
          id: `reply-${Date.now()}`,
          author: ME,
          time: "now",
          text,
          likes: 0,
          liked: false,
        },
      ],
    }))
    setPosts((ps) =>
      ps.map((p) => (p.id === postId ? { ...p, replies: p.replies + 1 } : p)),
    )
  }

  const toggleReplyLike = (postId: string, commentId: string) =>
    setReplies((r) => ({
      ...r,
      [postId]: (r[postId] ?? []).map((c) =>
        c.id === commentId
          ? { ...c, liked: !c.liked, likes: c.likes + (c.liked ? -1 : 1) }
          : c,
      ),
    }))

  const addPost = (text: string, media?: Media[]) =>
    setPosts((ps) => [
      {
        id: `user-${Date.now()}`,
        community: selected,
        author: ME,
        time: "now",
        text,
        media,
        replies: 0,
        reposts: 0,
        likes: 0,
        views: 1,
        liked: false,
        reposted: false,
      },
      ...ps,
    ])

  const back = () => {
    if (view === "detail" && origin === "directory") {
      setView("directory")
    } else {
      onBack()
    }
  }

  const activePost = openPostId
    ? (posts.find((p) => p.id === openPostId) ?? null)
    : null

  if (activePost) {
    return (
      <PostDetail
        post={activePost}
        communityColor={colorOf(activePost.community)}
        comments={replies[activePost.id] ?? []}
        onBack={() => setOpenPostId(null)}
        onLike={() => toggleLike(activePost.id)}
        onRepost={() => toggleRepost(activePost.id)}
        onLikeComment={(commentId) => toggleReplyLike(activePost.id, commentId)}
        onReply={(text) => addReply(activePost.id, text)}
      />
    )
  }

  if (view === "detail") {
    const feed = posts.filter((p) => p.community === selected)

    return (
      <div
        style={{
          position: "relative",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          background: "var(--app-bg)",
          overflow: "hidden",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            padding: "10px 12px",
            borderBottom: "1px solid var(--border)",
            flexShrink: 0,
            gap: 8,
          }}
        >
          <button onClick={back} aria-label="Back" style={iconButton}>
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
              <path d="M19 12H5" />
              <path d="M12 19l-7-7 7-7" />
            </svg>
          </button>
          <div
            style={{
              flex: 1,
              minWidth: 0,
              textAlign: "center",
              lineHeight: 1.25,
            }}
          >
            <div
              style={{
                fontFamily: "Space Grotesk",
                fontSize: 16,
                fontWeight: 700,
                color: "var(--text)",
                whiteSpace: "nowrap",
                overflow: "hidden",
                textOverflow: "ellipsis",
              }}
            >
              {community.name}
            </div>
            <div
              style={{
                fontSize: 12,
                color: "var(--muted)",
                fontFamily: "Inter",
              }}
            >
              @{community.handle}
            </div>
          </div>
          <button aria-label="Share" style={iconButton}>
            <svg
              width="18"
              height="18"
              viewBox="0 0 24 24"
              fill="none"
              stroke="currentColor"
              strokeWidth="1.9"
              strokeLinecap="round"
              strokeLinejoin="round"
            >
              <path d="M4 12v7a2 2 0 002 2h12a2 2 0 002-2v-7" />
              <path d="M16 6l-4-4-4 4" />
              <path d="M12 2v13" />
            </svg>
          </button>
          <button aria-label="More" style={iconButton}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="currentColor">
              <circle cx="5" cy="12" r="1.7" />
              <circle cx="12" cy="12" r="1.7" />
              <circle cx="19" cy="12" r="1.7" />
            </svg>
          </button>
        </div>

        <div
          className="flex-1 overflow-y-auto"
          style={{ background: "var(--app-bg)" }}
        >
          <img
            src={community.banner}
            alt=""
            style={{ width: "100%", height: 170, objectFit: "cover" }}
          />

          <div style={{ padding: "18px 20px 8px", textAlign: "center" }}>
            <h2
              style={{
                fontFamily: "Space Grotesk",
                fontSize: 22,
                fontWeight: 700,
                color: "var(--text)",
                margin: "0 0 10px",
              }}
            >
              {community.name}
            </h2>
            <p
              style={{
                fontSize: 14,
                fontWeight: 600,
                color: "var(--text)",
                lineHeight: 1.5,
                margin: "0 0 14px",
                fontFamily: "Inter",
              }}
            >
              {community.description}
            </p>

            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 6,
                marginBottom: 14,
                flexWrap: "wrap",
              }}
            >
              <Avatar src={community.owner.avatar} size={24} />
              <span
                style={{
                  fontSize: 14,
                  fontWeight: 700,
                  color: "var(--text)",
                  fontFamily: "Inter",
                }}
              >
                {community.owner.name}
              </span>
              {community.owner.verified && <VerifiedBadge size={15} />}
              <span
                style={{
                  fontSize: 14,
                  color: "var(--muted)",
                  fontFamily: "Inter",
                }}
              >
                @{community.owner.handle}
              </span>
            </div>

            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                gap: 18,
                marginBottom: 16,
                fontFamily: "Inter",
                fontSize: 14,
              }}
            >
              <span style={{ fontWeight: 700, color: "var(--text)" }}>
                {fmt(community.members)} Members
              </span>
              <span style={{ color: "var(--muted)" }}>
                {fmt(community.followers)} Followers
              </span>
            </div>

            <button
              onClick={() => toggleFollow(community.name)}
              style={{
                padding: "8px 26px",
                borderRadius: 999,
                fontSize: 15,
                fontWeight: 700,
                fontFamily: "Inter",
                cursor: "pointer",
                border: community.following
                  ? "1px solid var(--text)"
                  : "1px solid var(--text)",
                background: community.following ? "transparent" : "var(--text)",
                color: community.following ? "var(--text)" : "var(--app-bg)",
                transition: "all 0.15s",
              }}
            >
              {community.following ? "Following" : "Follow"}
            </button>
          </div>

          <div style={{ marginTop: 14 }}>
            {feed.length === 0 && (
              <div
                style={{
                  padding: "40px 24px",
                  textAlign: "center",
                  fontSize: 14,
                  color: "var(--muted)",
                  fontFamily: "Inter",
                  lineHeight: 1.5,
                }}
              >
                No posts yet in {community.name} — be the first to share.
              </div>
            )}
            {feed.map((p) => (
              <PostCard
                key={p.id}
                post={p}
                onLike={() => toggleLike(p.id)}
                onRepost={() => toggleRepost(p.id)}
              />
            ))}
          </div>

          <div style={{ height: 72 }} />
        </div>

        <button
          onClick={() => setComposing(true)}
          aria-label="New post"
          style={{
            position: "absolute",
            right: 16,
            bottom: 16,
            width: 52,
            height: 52,
            borderRadius: "50%",
            border: "none",
            background: "linear-gradient(135deg, #8F72FF 0%, #7C5CFF 100%)",
            boxShadow: "0 6px 18px rgba(124,92,255,0.45)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            zIndex: 30,
          }}
        >
          <svg
            width="20"
            height="20"
            viewBox="0 0 24 24"
            fill="none"
            stroke="#fff"
            strokeWidth="2.2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <path d="M12 20h9" />
            <path d="M16.5 3.5a2.12 2.12 0 013 3L7 19l-4 1 1-4L16.5 3.5z" />
          </svg>
        </button>

        {composing && (
          <ComposeOverlay
            community={community}
            onClose={() => setComposing(false)}
            onPost={addPost}
          />
        )}
      </div>
    )
  }

  return (
    <div
      className="flex flex-col h-full overflow-y-auto"
      style={{ background: "var(--app-bg)" }}
    >
      <div className="px-5 pt-12 pb-4">
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <button
            onClick={onBack}
            aria-label="Back"
            style={{ ...iconButton, marginLeft: -8 }}
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
              <path d="M19 12H5" />
              <path d="M12 19l-7-7 7-7" />
            </svg>
          </button>
          <h2
            style={{
              fontFamily: "Space Grotesk",
              fontSize: 24,
              fontWeight: 700,
              color: "var(--text)",
              margin: 0,
            }}
          >
            Community
          </h2>
        </div>

        <div style={{ position: "relative", marginTop: 14 }}>
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
            placeholder="Search communities and discussions…"
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

      {!q && (
        <div className="px-5 pb-4">
          <span style={sectionTitle}>Trending now</span>
          <div className="flex flex-col mt-1">
            {trending.map((t) => (
              <button
                key={t.tag}
                onClick={() => openPost(t.postId)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  width: "100%",
                  background: "none",
                  border: "none",
                  padding: "10px 0",
                  cursor: "pointer",
                  textAlign: "left",
                }}
              >
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div
                    style={{
                      fontSize: 14,
                      fontWeight: 600,
                      color: "var(--text)",
                      fontFamily: "Inter",
                    }}
                  >
                    {t.tag}
                  </div>
                  <div
                    style={{
                      fontSize: 12,
                      color: "var(--muted)",
                      fontFamily: "Inter",
                    }}
                  >
                    {fmt(t.posts)} posts
                  </div>
                </div>
                <svg
                  width="15"
                  height="15"
                  viewBox="0 0 24 24"
                  fill="none"
                  stroke="var(--muted)"
                  strokeWidth="1.8"
                  strokeLinecap="round"
                  strokeLinejoin="round"
                >
                  <path d="M9 18l6-6-6-6" />
                </svg>
              </button>
            ))}
          </div>
        </div>
      )}

      {visibleCommunities.length > 0 && (
        <div className="px-5 pb-4">
          <span style={sectionTitle}>Communities</span>
          <div
            className="flex gap-2 overflow-x-auto"
            style={{ scrollbarWidth: "none", margin: "10px 0 12px" }}
          >
            {chips.map((c) => (
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

          <div className="flex flex-col gap-3">
            {visibleCommunities.map((c) => (
              <div
                key={c.name}
                onClick={() => openDetail(c.name)}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  background: "var(--surface)",
                  border: "1px solid var(--border)",
                  borderRadius: 12,
                  padding: 12,
                  cursor: "pointer",
                }}
              >
                <div
                  style={{
                    width: 46,
                    height: 46,
                    borderRadius: "50%",
                    padding: 1.5,
                    background: `linear-gradient(45deg, ${c.color}, #7C5CFF)`,
                    flexShrink: 0,
                  }}
                >
                  <img
                    src={c.img}
                    alt={c.name}
                    style={{
                      width: "100%",
                      height: "100%",
                      borderRadius: "50%",
                      objectFit: "cover",
                      border: "2px solid var(--surface)",
                    }}
                  />
                </div>
                <div
                  className="flex flex-col"
                  style={{ flex: 1, minWidth: 0, gap: 2 }}
                >
                  <span
                    style={{
                      fontSize: 14,
                      fontWeight: 600,
                      color: "var(--text)",
                      fontFamily: "Inter",
                      whiteSpace: "nowrap",
                      overflow: "hidden",
                      textOverflow: "ellipsis",
                    }}
                  >
                    {c.name}
                  </span>
                  <span
                    style={{
                      fontSize: 12,
                      color: "var(--muted)",
                      fontFamily: "Inter",
                    }}
                  >
                    {fmt(c.members)} members · {fmt(c.followers)} followers
                  </span>
                </div>
                <button
                  onClick={(e) => {
                    e.stopPropagation()
                    toggleFollow(c.name)
                  }}
                  style={{
                    flexShrink: 0,
                    padding: "6px 16px",
                    borderRadius: 999,
                    fontSize: 13,
                    fontWeight: 700,
                    fontFamily: "Inter",
                    cursor: "pointer",
                    border: "1px solid var(--text)",
                    background: c.following ? "transparent" : "var(--text)",
                    color: c.following ? "var(--text)" : "var(--app-bg)",
                  }}
                >
                  {c.following ? "Following" : "Follow"}
                </button>
              </div>
            ))}
          </div>
        </div>
      )}

      <div className="px-5 pb-4">
        <span style={sectionTitle}>Latest discussions</span>
        <div
          style={{
            marginTop: 10,
            marginLeft: -20,
            marginRight: -20,
            borderTop: "1px solid var(--border)",
          }}
        >
          {visiblePosts.length === 0 && (
            <div
              style={{
                padding: "32px 20px",
                textAlign: "center",
                fontSize: 14,
                color: "var(--muted)",
                fontFamily: "Inter",
                lineHeight: 1.5,
              }}
            >
              {visibleCommunities.length === 0
                ? `No results for “${query.trim()}”.`
                : "No discussions match your filters yet."}
            </div>
          )}
          {visiblePosts.map((p) => (
            <PostCard
              key={p.id}
              post={p}
              communityColor={colorOf(p.community)}
              onOpen={() => openDetail(p.community)}
              onLike={() => toggleLike(p.id)}
              onRepost={() => toggleRepost(p.id)}
            />
          ))}
        </div>
      </div>

      <div style={{ height: 24 }} />
    </div>
  )
}
