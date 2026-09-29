import { useState } from "react"
import {
  Accessibility,
  Activity,
  ArrowLeft,
  Bookmark,
  BookOpen,
  Briefcase,
  Check,
  ChevronDown,
  ChevronRight,
  Clock,
  Cookie,
  CreditCard,
  Download,
  FileText,
  Info,
  LifeBuoy,
  Mail,
  MapPin,
  Megaphone,
  Phone,
  Search,
  Send,
  Shield,
  Trash2,
  Users,
  Wifi,
} from "lucide-react"

export type ResourcePage = "root" | "help" | "faq" | "contact" | "about" | "cookies" | "ads" | "bookmarks" | "history" | "order" | "offline" | "privacy" | "terms" | "careers" | "accessibility"

type IconType = React.ComponentType<{
  size?: number | string
  color?: string
  strokeWidth?: number
}>

type RowKind = "nav" | "toggle" | "radio" | "value"

interface Row {
  id: string
  label: string
  desc?: string
  icon?: IconType
  kind?: RowKind
  page?: ResourcePage
  value?: string
  selected?: boolean
  disabled?: boolean
  onSelect?: () => void
  onOpen?: () => void
}

interface Section {
  heading?: string
  rows: Row[]
}

interface Doc {
  title: string
  paras: string[]
}

const ACCENT = "#7C5CFF"

const para: React.CSSProperties = {
  fontFamily: "Inter, sans-serif",
  fontSize: 14,
  lineHeight: 1.65,
  color: "var(--muted-2)",
  margin: "0 0 10px",
}

const faqs = [
  {
    q: "What is Fandom Verse?",
    a: "Fandom Verse is a platform for pop-culture fans to discover content, find events, shop exclusive merch, and connect with their fandoms — all in one place.",
  },
  {
    q: "Is Fandom Verse free to use?",
    a: "Yes, the core app is completely free. You can browse content, track events, and explore fandoms without paying anything. Shop purchases are separate.",
  },
  {
    q: "How do I download content for offline use?",
    a: "Open any article and tap the download icon. Everything you save lives under Offline content, where you can manage storage and remove downloads.",
  },
  {
    q: "Are shop purchases real?",
    a: "All purchases in the current version are simulated — no real payment is processed. This is a demo environment.",
  },
  {
    q: "How do I contact support?",
    a: "Head to Contact us from this page, fill in the form and our team replies within one business day. You can also email hello@fandomverse.io.",
  },
  {
    q: "How does the AI Fan Helper work?",
    a: "The AI Fan Helper is a chatbot trained to answer questions about fandoms, lore, and events. It uses contextual knowledge from our content library.",
  },
]

const team = [
  {
    name: "Maya Chen",
    role: "Founder & CEO",
    img: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=120&h=120&fit=crop&auto=format",
  },
  {
    name: "Jordan Park",
    role: "Head of Design",
    img: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=120&h=120&fit=crop&auto=format",
  },
  {
    name: "Alex Torres",
    role: "Lead Engineer",
    img: "https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=120&h=120&fit=crop&auto=format",
  },
  {
    name: "Sam Okonkwo",
    role: "Community Lead",
    img: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=120&h=120&fit=crop&auto=format",
  },
]

type BookmarkItem = {
  id: string
  title: string
  tag: string
  saved: string
  img: string
  group: "Articles" | "Stories" | "Media"
}

const bookmarkSeed: BookmarkItem[] = [
  {
    id: "b1",
    title: "The Complete Attack on Titan Timeline",
    tag: "Anime",
    saved: "Saved 2d ago",
    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=120&h=120&fit=crop&auto=format",
    group: "Articles",
  },
  {
    id: "b2",
    title: "Marvel Phase 6: Everything We Know",
    tag: "Marvel",
    saved: "Saved 5d ago",
    img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=120&h=120&fit=crop&auto=format",
    group: "Articles",
  },
  {
    id: "b3",
    title: "Top 10 Gaming Moments of 2026",
    tag: "Gaming",
    saved: "Saved 1w ago",
    img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=120&h=120&fit=crop&auto=format",
    group: "Articles",
  },
  {
    id: "b4",
    title: "My first Anime Expo experience",
    tag: "Anime",
    saved: "Saved 3d ago",
    img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=120&h=120&fit=crop&auto=format",
    group: "Stories",
  },
  {
    id: "b5",
    title: "K-Pop: 3 years as an ARMY",
    tag: "K-Pop",
    saved: "Saved 2w ago",
    img: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=120&h=120&fit=crop&auto=format",
    group: "Stories",
  },
  {
    id: "b6",
    title: "Elden Ring Shadow of the Erdtree Trailer",
    tag: "Gaming",
    saved: "Saved 4d ago",
    img: "https://images.unsplash.com/photo-1636953056323-9c09fdd74fa6?w=120&h=120&fit=crop&auto=format",
    group: "Media",
  },
]

type Order = {
  id: string
  date: string
  status: "Delivered" | "Shipped" | "Refunded"
  note: string
  shipping: number
  items: {
    title: string
    qty: number
    price: number
    img: string
  }[]
}

const orders: Order[] = [
  {
    id: "#FV-20260924-8821",
    date: "Sep 24, 2026",
    status: "Delivered",
    note: "Delivered on Sep 27",
    shipping: 0,
    items: [
      {
        title: "Titan Foil Edition Art Book",
        qty: 1,
        price: 89.99,
        img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=120&h=120&fit=crop&auto=format",
      },
      {
        title: "Raid Boss Enamel Pin Set",
        qty: 2,
        price: 79.99,
        img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=120&h=120&fit=crop&auto=format",
      },
    ],
  },
  {
    id: "#FV-20260901-5410",
    date: "Sep 1, 2026",
    status: "Shipped",
    note: "Arriving in 2 days",
    shipping: 6.5,
    items: [
      {
        title: "Concert Lightstick Replica",
        qty: 1,
        price: 83.49,
        img: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=120&h=120&fit=crop&auto=format",
      },
    ],
  },
  {
    id: "#FV-20260815-2293",
    date: "Aug 15, 2026",
    status: "Refunded",
    note: "Refunded on Aug 20",
    shipping: 0,
    items: [
      {
        title: "Hero Crest Hoodie",
        qty: 1,
        price: 129.99,
        img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=120&h=120&fit=crop&auto=format",
      },
      {
        title: "Villain Arc Poster Set",
        qty: 1,
        price: 89.99,
        img: "https://images.unsplash.com/photo-1540575467063-178a50c2df87?w=120&h=120&fit=crop&auto=format",
      },
      {
        title: "Mecha Figure — Wave 2",
        qty: 1,
        price: 98.99,
        img: "https://images.unsplash.com/photo-1636953056323-9c09fdd74fa6?w=120&h=120&fit=crop&auto=format",
      },
    ],
  },
]

type OfflineItem = {
  id: string
  title: string
  tag: string
  mb: number
}

const offlineSeed: OfflineItem[] = [
  { id: "o1", title: "Attack on Titan: Full Timeline", tag: "Anime", mb: 1.2 },
  { id: "o2", title: "Marvel Phase 6 Guide", tag: "Marvel", mb: 0.84 },
  { id: "o3", title: "Elden Ring Lore Deep Dive", tag: "Gaming", mb: 2.1 },
  { id: "o4", title: "K-Pop Comeback Tracker", tag: "K-Pop", mb: 1.5 },
]

const STORAGE_LIMIT = 50

const helpTopics: {
  label: string
  desc: string
  icon: IconType
  page: ResourcePage
}[] = [
  {
    label: "Account & sign-in",
    desc: "Password, email and login issues",
    icon: Users,
    page: "faq",
  },
  {
    label: "Orders & payments",
    desc: "Receipts, refunds and status",
    icon: CreditCard,
    page: "history",
  },
  {
    label: "Downloads",
    desc: "Offline access and storage",
    icon: Download,
    page: "offline",
  },
  {
    label: "Privacy & safety",
    desc: "Your data and controls",
    icon: Shield,
    page: "privacy",
  },
  {
    label: "Content & fandoms",
    desc: "Feeds, bookmarks and events",
    icon: BookOpen,
    page: "faq",
  },
  {
    label: "Ads & business",
    desc: "Advertising and partnerships",
    icon: Megaphone,
    page: "ads",
  },
]

type HelpArticle = {
  label: string
  page: ResourcePage
}

const popularArticles: HelpArticle[] = [
  { label: "Reset or change your password", page: "faq" },
  { label: "Where can I see my orders?", page: "history" },
  { label: "Turn off personalized ads", page: "ads" },
  { label: "Read content without a connection", page: "offline" },
  { label: "Manage your cookie preferences", page: "cookies" },
]

const privacyDocs: Doc[] = [
  {
    title: "Information we collect",
    paras: [
      "We collect the information you give us directly — your name, email address, bio and the interests you pick when you set up an account.",
      "We also collect usage information such as the pages you view, the fandoms you follow and the device you use, so we can keep the app running and improve what we recommend to you.",
    ],
  },
  {
    title: "How we use your information",
    paras: [
      "We use your information to operate Fandom Verse: personalising your feed, processing shop orders, protecting the community from spam and abuse, and answering support requests.",
      "We never sell your personal information. Aggregate, de-identified data may be used for research and reporting.",
    ],
  },
  {
    title: "Sharing and disclosure",
    paras: [
      "We share information with service providers who help us run the platform — hosting, analytics, payments and customer support — under contracts that limit how they may use it.",
      "We may disclose information when required by law, or to protect the rights, safety and property of Fandom Verse and our community.",
    ],
  },
  {
    title: "Your rights and controls",
    paras: [
      "You can review and edit your account information any time in Settings → Your account, download an archive of your data, or request deletion of your account.",
      "You can also manage cookies from the Cookies page and adjust ad targeting from Ads & Business.",
    ],
  },
]

const termsDocs: Doc[] = [
  {
    title: "1. Acceptance of terms",
    paras: [
      "By creating an account or using Fandom Verse you agree to these Terms of Service and our Privacy Policy. If you do not agree, please do not use the app.",
    ],
  },
  {
    title: "2. Your account",
    paras: [
      "You are responsible for keeping your login credentials secure and for all activity that happens under your account. You must be at least 13 years old to use Fandom Verse.",
      "One person may not maintain more than one account for the purpose of spamming, manipulation or evasion of enforcement actions.",
    ],
  },
  {
    title: "3. Your content",
    paras: [
      "You keep ownership of the posts, stories and media you upload. You grant Fandom Verse a worldwide licence to host, display and distribute that content as part of operating the service.",
      "You may not upload content you do not have the right to use, including copyrighted material owned by others.",
    ],
  },
  {
    title: "4. Purchases and refunds",
    paras: [
      "Shop purchases in this build are simulated and no real payment is processed. In production, prices, taxes and shipping are shown before you confirm an order.",
      "Physical goods may be returned within 30 days of delivery in original condition. Digital items are non-refundable once downloaded.",
    ],
  },
  {
    title: "5. Acceptable use",
    paras: [
      "Do not harass other members, organise brigading, post illegal material, scrape the service at scale, or attempt to gain unauthorised access to any account or system.",
      "We may remove content or suspend accounts that break these rules.",
    ],
  },
  {
    title: "6. Termination",
    paras: [
      "You may delete your account at any time. We may suspend or terminate accounts that violate these terms, and will when possible notify you of the reason.",
    ],
  },
]

const roles = [
  {
    title: "Product Designer",
    dept: "Design",
    place: "Los Angeles, CA",
    type: "Full-time",
  },
  {
    title: "Frontend Engineer, Web",
    dept: "Engineering",
    place: "Remote (US)",
    type: "Full-time",
  },
  {
    title: "Community Manager",
    dept: "Community",
    place: "Seoul, KR",
    type: "Full-time",
  },
  {
    title: "Events Producer",
    dept: "Operations",
    place: "Tokyo, JP",
    type: "Contract",
  },
  {
    title: "Data Analyst",
    dept: "Data",
    place: "Los Angeles, CA",
    type: "Full-time",
  },
]

function useToggles<T extends Record<string, boolean>>(initial: T) {
  const [state, setState] = useState(initial)
  const toggle = (key: keyof T) =>
    setState((prev) => ({ ...prev, [key]: !prev[key] }))
  return [state, toggle] as const
}

const money = (n: number) => `$${n.toFixed(2)}`

const orderTotal = (order: Order) =>
  order.items.reduce((sum, item) => sum + item.price * item.qty, 0) +
  order.shipping

export default function ResourceScreen({
  initial = "root",
  onClose,
}: {
  initial?: ResourcePage
  onClose: () => void
}) {
  const [stack, setStack] = useState<ResourcePage[]>([initial])
  const [query, setQuery] = useState("")
  const [helpQuery, setHelpQuery] = useState("")
  const [openFaq, setOpenFaq] = useState<number | null>(null)
  const [bookmarkTab, setBookmarkTab] =
    useState<"Articles" | "Stories" | "Media">("Articles")
  const [removedBookmarks, setRemovedBookmarks] = useState<string[]>([])
  const [selectedOrder, setSelectedOrder] = useState(0)
  const [downloads, setDownloads] = useState<string[]>(["o1", "o2"])
  const [contact, setContact] = useState({
    name: "",
    email: "",
    message: "",
    error: "",
    sent: false,
  })
  const [cookiePrefs, toggleCookie] = useToggles({
    performance: false,
    functional: true,
    targeting: false,
  })
  const [adPrefs, toggleAds] = useToggles({
    personalized: true,
    inferred: false,
    partners: false,
  })
  const [a11yPrefs, toggleA11y] = useToggles({
    motion: false,
    contrast: false,
    captions: true,
    largeText: false,
  })
  const [offlinePrefs, toggleOffline] = useToggles({
    wifiOnly: true,
    autoSave: false,
  })
  const [savedNote, setSavedNote] = useState("")

  const page = stack[stack.length - 1]

  const push = (next: ResourcePage) => {
    setSavedNote("")
    setStack((s) => [...s, next])
  }
  const back = () => {
    if (stack.length > 1) setStack((s) => s.slice(0, -1))
    else onClose()
  }

  const titles: Record<ResourcePage, string> = {
    root: "Help & more",
    help: "Help Center",
    faq: "FAQ",
    contact: "Contact us",
    about: "About us",
    cookies: "Cookies",
    ads: "Ads & Business",
    bookmarks: "Bookmarks",
    history: "Purchase history",
    order: orders[selectedOrder]?.id ?? "Order details",
    offline: "Offline content",
    privacy: "Privacy policy",
    terms: "Terms of service",
    careers: "Careers",
    accessibility: "Accessibility",
  }

  const backLabel = page === "root" ? "Close" : "Back"

  const toggleRow = (
    id: string,
    label: string,
    desc: string | undefined,
    icon: IconType | undefined,
    on: boolean,
    onSelect: () => void,
    disabled = false,
  ): Row => ({
    id,
    label,
    desc,
    icon,
    kind: "toggle",
    selected: on,
    disabled,
    onSelect,
  })

  const navRow = (
    id: string,
    label: string,
    target: ResourcePage,
    desc?: string,
    icon?: IconType,
    value?: string,
  ): Row => ({ id, label, desc, icon, value, kind: "nav", page: target })

  const rootSections: Section[] = [
    {
      heading: "Your library",
      rows: [
        navRow(
          "bookmarks",
          "Bookmarks",
          "bookmarks",
          "Posts, stories and media you saved for later.",
          Bookmark,
        ),
        navRow(
          "history",
          "Purchase history",
          "history",
          "Track orders, view receipts and buy again.",
          CreditCard,
          `${orders.length} orders`,
        ),
        navRow(
          "offline",
          "Offline content",
          "offline",
          "Manage what you can read without a connection.",
          Download,
          `${downloads.length} saved`,
        ),
      ],
    },
    {
      heading: "Support",
      rows: [
        navRow(
          "help",
          "Help Center",
          "help",
          "Search help topics, browse guides and get support.",
          LifeBuoy,
        ),
        navRow(
          "faq",
          "FAQ",
          "faq",
          "Quick answers to the most common questions.",
          Info,
        ),
        navRow(
          "contact",
          "Contact us",
          "contact",
          "Send a message straight to our support team.",
          Mail,
        ),
      ],
    },
    {
      heading: "Company",
      rows: [
        navRow(
          "about",
          "About us",
          "about",
          "Who we are, what we build and the team behind it.",
          Info,
        ),
        navRow(
          "careers",
          "Careers",
          "careers",
          "Open roles across Los Angeles, Seoul and Tokyo.",
          Briefcase,
        ),
      ],
    },
    {
      heading: "Legal and data",
      rows: [
        navRow(
          "cookies",
          "Cookies",
          "cookies",
          "How we use cookies and manage your preferences.",
          Cookie,
        ),
        navRow(
          "ads",
          "Ads & Business",
          "ads",
          "Advertising, partners and business solutions.",
          Megaphone,
        ),
        navRow(
          "privacy",
          "Privacy policy",
          "privacy",
          "What we collect and how we use it.",
          Shield,
        ),
        navRow(
          "terms",
          "Terms of service",
          "terms",
          "The rules that apply when you use Fandom Verse.",
          FileText,
        ),
        navRow(
          "accessibility",
          "Accessibility",
          "accessibility",
          "Display options and our accessibility commitment.",
          Accessibility,
        ),
      ],
    },
  ]

  const filteredSections = (() => {
    const q = query.trim().toLowerCase()
    if (!q) return rootSections
    return rootSections
      .map((section) => ({
        heading: section.heading,
        rows: section.rows.filter((row) =>
          `${row.label} ${row.desc ?? ""}`.toLowerCase().includes(q),
        ),
      }))
      .filter((section) => section.rows.length > 0)
  })()

  const rowTrailing = (row: Row) => {
    if (row.kind === "toggle") {
      const on = row.selected ?? false
      return (
        <span
          style={{
            width: 42,
            height: 24,
            borderRadius: 12,
            background: row.disabled
              ? "var(--border-strong)"
              : on
                ? ACCENT
                : "var(--border-strong)",
            position: "relative",
            flexShrink: 0,
            transition: "background 0.18s ease",
            opacity: row.disabled ? 0.7 : 1,
          }}
        >
          <span
            style={{
              position: "absolute",
              top: 3,
              left: on ? 21 : 3,
              width: 18,
              height: 18,
              borderRadius: "50%",
              background: "#fff",
              transition: "left 0.18s ease",
            }}
          />
        </span>
      )
    }
    if (row.kind === "value" && row.value)
      return (
        <span
          style={{
            fontSize: 14,
            color: "var(--muted)",
            flexShrink: 0,
            maxWidth: "48%",
            textAlign: "right",
          }}
        >
          {row.value}
        </span>
      )
    if (row.value)
      return (
        <span
          style={{
            display: "flex",
            alignItems: "center",
            gap: 6,
            flexShrink: 0,
          }}
        >
          <span
            style={{
              fontSize: 14,
              color: "var(--muted)",
              maxWidth: 130,
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
            }}
          >
            {row.value}
          </span>
          <ChevronRight size={16} style={{ color: "var(--muted)" }} />
        </span>
      )
    return <ChevronRight size={16} style={{ color: "var(--muted)" }} />
  }

  const renderRow = (row: Row, index: number, total: number) => {
    const Icon = row.icon
    const interactive = row.kind !== "value"
    return (
      <button
        key={`${page}-${row.id}`}
        onClick={() => {
          if (row.kind === "toggle" || row.kind === "radio") {
            if (!row.disabled) row.onSelect?.()
          } else if (row.kind === "nav" && row.page) push(row.page)
          else row.onSelect?.()
        }}
        style={{
          width: "100%",
          display: "flex",
          alignItems: "center",
          gap: 16,
          padding: "15px 16px",
          background: "none",
          border: "none",
          borderBottom: index < total - 1 ? "1px solid var(--border)" : "none",
          cursor: interactive ? "pointer" : "default",
          textAlign: "left",
        }}
      >
        {Icon && (
          <span
            style={{
              width: 26,
              display: "flex",
              justifyContent: "center",
              flexShrink: 0,
              color: "var(--text)",
            }}
          >
            <Icon size={19} />
          </span>
        )}
        <span style={{ flex: 1, minWidth: 0, display: "block" }}>
          <span
            style={{
              display: "block",
              fontFamily: "Inter, sans-serif",
              fontSize: 15.5,
              color: row.disabled ? "var(--muted)" : "var(--text)",
              lineHeight: 1.3,
            }}
          >
            {row.label}
          </span>
          {row.desc && (
            <span
              style={{
                display: "block",
                fontFamily: "Inter, sans-serif",
                fontSize: 13.5,
                color: "var(--muted)",
                lineHeight: 1.4,
                marginTop: 3,
              }}
            >
              {row.desc}
            </span>
          )}
        </span>
        {rowTrailing(row)}
      </button>
    )
  }

  const renderSections = (sections: Section[]) => (
    <>
      {sections.map((section, sectionIndex) => (
        <div
          key={section.heading ?? `section-${sectionIndex}`}
          style={{
            borderTop: sectionIndex > 0 ? "1px solid var(--border)" : "none",
            marginTop: sectionIndex > 0 ? 10 : 0,
          }}
        >
          {section.heading && (
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 19,
                fontWeight: 700,
                color: "var(--text)",
                padding: "18px 16px 8px",
              }}
            >
              {section.heading}
            </div>
          )}
          <div>
            {section.rows.map((row, index) =>
              renderRow(row, index, section.rows.length),
            )}
          </div>
        </div>
      ))}
    </>
  )

  const intro = (text: string) => (
    <p
      style={{
        margin: 0,
        padding: "16px 16px 6px",
        fontFamily: "Inter, sans-serif",
        fontSize: 14,
        lineHeight: 1.5,
        color: "var(--muted)",
      }}
    >
      {text}
    </p>
  )

  const docSection = (doc: Doc) => (
    <div key={doc.title} style={{ padding: "18px 16px 4px" }}>
      <h3
        style={{
          fontFamily: "Space Grotesk, sans-serif",
          fontSize: 16,
          fontWeight: 700,
          color: "var(--text)",
          margin: "0 0 8px",
        }}
      >
        {doc.title}
      </h3>
      {doc.paras.map((text, i) => (
        <p key={i} style={para}>
          {text}
        </p>
      ))}
    </div>
  )

  const card = (
    children: React.ReactNode,
    extra?: React.CSSProperties,
  ): React.ReactNode => (
    <div
      style={{
        background: "var(--surface)",
        border: "1px solid var(--border)",
        borderRadius: 16,
        padding: 18,
        margin: "14px 16px 0",
        ...extra,
      }}
    >
      {children}
    </div>
  )

  const primaryButton = (
    label: string,
    onClick: () => void,
    icon?: React.ReactNode,
  ) => (
    <button
      onClick={onClick}
      style={{
        width: "100%",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 8,
        background: ACCENT,
        color: "#fff",
        border: "none",
        borderRadius: 10,
        padding: "13px 16px",
        fontFamily: "Inter, sans-serif",
        fontSize: 14.5,
        fontWeight: 600,
        cursor: "pointer",
      }}
    >
      {icon}
      {label}
    </button>
  )

  const ghostButton = (label: string, onClick: () => void) => (
    <button
      onClick={onClick}
      style={{
        flex: 1,
        background: "transparent",
        color: "var(--text)",
        border: "1px solid var(--border-strong)",
        borderRadius: 10,
        padding: "12px 14px",
        fontFamily: "Inter, sans-serif",
        fontSize: 14,
        fontWeight: 500,
        cursor: "pointer",
      }}
    >
      {label}
    </button>
  )

  const field = (
    placeholder: string,
    value: string,
    onChange: (v: string) => void,
    type = "text",
  ) => (
    <input
      type={type}
      value={value}
      onChange={(event) => onChange(event.target.value)}
      placeholder={placeholder}
      style={{
        width: "100%",
        background: "var(--app-bg)",
        border: "1px solid var(--border-strong)",
        borderRadius: 10,
        padding: "13px 14px",
        color: "var(--text)",
        fontFamily: "Inter, sans-serif",
        fontSize: 14.5,
        outline: "none",
      }}
    />
  )

  const chip = (label: string, active: boolean, onClick: () => void) => (
    <button
      key={label}
      onClick={onClick}
      style={{
        padding: "7px 14px",
        borderRadius: 999,
        border: `1px solid ${active ? ACCENT : "var(--border)"}`,
        background: active ? "rgba(124,92,255,0.15)" : "var(--surface)",
        color: active ? ACCENT : "var(--muted)",
        fontFamily: "Inter, sans-serif",
        fontSize: 13,
        fontWeight: active ? 600 : 400,
        cursor: "pointer",
      }}
    >
      {label}
    </button>
  )

  const statusColor = (status: Order["status"]) =>
    status === "Delivered"
      ? "#4CAF50"
      : status === "Shipped"
        ? ACCENT
        : "#FF6B5C"

  const renderHelp = () => {
    const q = helpQuery.trim().toLowerCase()
    const topics = helpTopics.filter((t) =>
      `${t.label} ${t.desc}`.toLowerCase().includes(q),
    )
    const articles = popularArticles.filter((a) =>
      a.label.toLowerCase().includes(q),
    )
    return (
      <>
        <div style={{ padding: "16px 16px 4px" }}>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 10,
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 999,
              padding: "12px 16px",
            }}
          >
            <Search size={16} style={{ color: "var(--muted)" }} />
            <input
              value={helpQuery}
              onChange={(event) => setHelpQuery(event.target.value)}
              placeholder="Search help articles"
              style={{
                flex: 1,
                minWidth: 0,
                background: "none",
                border: "none",
                outline: "none",
                color: "var(--text)",
                fontFamily: "Inter, sans-serif",
                fontSize: 14.5,
              }}
            />
          </div>
        </div>

        {topics.length > 0 && (
          <>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 19,
                fontWeight: 700,
                color: "var(--text)",
                padding: "18px 16px 10px",
              }}
            >
              Browse by topic
            </div>
            <div
              style={{
                display: "grid",
                gridTemplateColumns: "1fr 1fr",
                gap: 10,
                padding: "0 16px",
              }}
            >
              {topics.map((topic) => {
                const Icon = topic.icon
                return (
                  <button
                    key={topic.label}
                    onClick={() => push(topic.page)}
                    style={{
                      textAlign: "left",
                      background: "var(--surface)",
                      border: "1px solid var(--border)",
                      borderRadius: 14,
                      padding: "14px 14px 16px",
                      cursor: "pointer",
                      display: "flex",
                      flexDirection: "column",
                      gap: 10,
                    }}
                  >
                    <span
                      style={{
                        width: 34,
                        height: 34,
                        borderRadius: 10,
                        background: "rgba(124,92,255,0.15)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: ACCENT,
                      }}
                    >
                      <Icon size={17} />
                    </span>
                    <span
                      style={{
                        fontFamily: "Space Grotesk, sans-serif",
                        fontSize: 14,
                        fontWeight: 600,
                        color: "var(--text)",
                        lineHeight: 1.3,
                      }}
                    >
                      {topic.label}
                    </span>
                    <span
                      style={{
                        fontFamily: "Inter, sans-serif",
                        fontSize: 12,
                        color: "var(--muted)",
                        lineHeight: 1.4,
                      }}
                    >
                      {topic.desc}
                    </span>
                  </button>
                )
              })}
            </div>
          </>
        )}

        {articles.length > 0 && (
          <div style={{ marginTop: 22, borderTop: "1px solid var(--border)" }}>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 19,
                fontWeight: 700,
                color: "var(--text)",
                padding: "18px 16px 8px",
              }}
            >
              Popular articles
            </div>
            {articles.map((article, index) => (
              <button
                key={article.label}
                onClick={() => push(article.page)}
                style={{
                  width: "100%",
                  display: "flex",
                  alignItems: "center",
                  gap: 16,
                  padding: "15px 16px",
                  background: "none",
                  border: "none",
                  borderBottom:
                    index < articles.length - 1
                      ? "1px solid var(--border)"
                      : "none",
                  cursor: "pointer",
                  textAlign: "left",
                }}
              >
                <span
                  style={{
                    flex: 1,
                    fontFamily: "Inter, sans-serif",
                    fontSize: 15,
                    color: "var(--text)",
                  }}
                >
                  {article.label}
                </span>
                <ChevronRight size={16} style={{ color: "var(--muted)" }} />
              </button>
            ))}
          </div>
        )}

        {topics.length === 0 && articles.length === 0 && (
          <div
            style={{
              padding: "40px 32px",
              textAlign: "center",
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
              color: "var(--muted)",
            }}
          >
            No help articles match “{helpQuery.trim()}”.
          </div>
        )}

        {card(
          <>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 16,
                fontWeight: 700,
                color: "var(--text)",
                marginBottom: 6,
              }}
            >
              Still need help?
            </div>
            <p style={{ ...para, marginBottom: 14 }}>
              Our support team replies within one business day.
            </p>
            <div style={{ display: "flex", gap: 10 }}>
              {ghostButton("FAQ", () => push("faq"))}
              <button
                onClick={() => push("contact")}
                style={{
                  flex: 1,
                  background: ACCENT,
                  color: "#fff",
                  border: "none",
                  borderRadius: 10,
                  padding: "12px 14px",
                  fontFamily: "Inter, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  cursor: "pointer",
                }}
              >
                Contact us
              </button>
            </div>
          </>,
          { marginBottom: 28 },
        )}
      </>
    )
  }

  const renderFaq = () => (
    <>
      {intro("Answers to the questions we hear most often.")}
      <div style={{ padding: "10px 16px 28px" }}>
        {faqs.map((faq, i) => (
          <div
            key={i}
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              marginBottom: 10,
              overflow: "hidden",
            }}
          >
            <button
              onClick={() => setOpenFaq(openFaq === i ? null : i)}
              style={{
                width: "100%",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "16px 18px",
                background: "none",
                border: "none",
                cursor: "pointer",
                textAlign: "left",
                gap: 12,
              }}
            >
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                  lineHeight: 1.35,
                }}
              >
                {faq.q}
              </span>
              <ChevronDown
                size={18}
                style={{
                  color: "var(--muted)",
                  flexShrink: 0,
                  transform: openFaq === i ? "rotate(180deg)" : "none",
                  transition: "transform 0.2s",
                }}
              />
            </button>
            {openFaq === i && (
              <div
                style={{
                  padding: "0 18px 16px",
                  fontFamily: "Inter, sans-serif",
                  fontSize: 14,
                  lineHeight: 1.6,
                  color: "var(--muted-2)",
                }}
              >
                {faq.a}
              </div>
            )}
          </div>
        ))}
      </div>
    </>
  )

  const renderContact = () => {
    if (contact.sent)
      return (
        <>
          {card(
            <>
              <span
                style={{
                  width: 44,
                  height: 44,
                  borderRadius: "50%",
                  background: "rgba(76,175,80,0.16)",
                  color: "#4CAF50",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  marginBottom: 12,
                }}
              >
                <Check size={22} />
              </span>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 17,
                  fontWeight: 700,
                  color: "var(--text)",
                  marginBottom: 6,
                }}
              >
                Message sent
              </div>
              <p style={{ ...para, marginBottom: 16 }}>
                Thanks {contact.name.split(" ")[0] || "there"} — we replied to{" "}
                {contact.email} within one business day.
              </p>
              <button
                onClick={() =>
                  setContact({
                    name: "",
                    email: "",
                    message: "",
                    error: "",
                    sent: false,
                  })
                }
                style={{
                  width: "100%",
                  background: "transparent",
                  color: "var(--text)",
                  border: "1px solid var(--border-strong)",
                  borderRadius: 10,
                  padding: "12px 14px",
                  fontFamily: "Inter, sans-serif",
                  fontSize: 14,
                  fontWeight: 500,
                  cursor: "pointer",
                }}
              >
                Send another message
              </button>
            </>,
            { marginBottom: 20 },
          )}
        </>
      )

    return (
      <>
        <div
          style={{
            padding: "16px 16px 0",
            display: "flex",
            flexDirection: "column",
            gap: 12,
          }}
        >
          {field("Your name", contact.name, (v) =>
            setContact((c) => ({ ...c, name: v })),
          )}
          {field(
            "Email address",
            contact.email,
            (v) => setContact((c) => ({ ...c, email: v })),
            "email",
          )}
          <textarea
            value={contact.message}
            onChange={(event) =>
              setContact((c) => ({ ...c, message: event.target.value }))
            }
            placeholder="How can we help?"
            rows={5}
            style={{
              width: "100%",
              background: "var(--app-bg)",
              border: "1px solid var(--border-strong)",
              borderRadius: 10,
              padding: "13px 14px",
              color: "var(--text)",
              fontFamily: "Inter, sans-serif",
              fontSize: 14.5,
              outline: "none",
              resize: "none",
              lineHeight: 1.5,
            }}
          />
          {contact.error && (
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "#FF6B5C",
              }}
            >
              {contact.error}
            </div>
          )}
          {primaryButton(
            "Send message",
            () => {
              if (
                !contact.name.trim() ||
                !contact.email.trim() ||
                !contact.message.trim()
              ) {
                setContact((c) => ({
                  ...c,
                  error: "Please fill in your name, email and message.",
                }))
                return
              }
              if (!contact.email.includes("@")) {
                setContact((c) => ({
                  ...c,
                  error: "Please enter a valid email address.",
                }))
                return
              }
              setContact((c) => ({ ...c, error: "", sent: true }))
            },
            <Send size={16} />,
          )}
        </div>

        {card(
          <>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 16,
                fontWeight: 700,
                color: "var(--text)",
                marginBottom: 14,
              }}
            >
              Contact details
            </div>
            {[
              { Icon: Mail, text: "hello@fandomverse.io", color: ACCENT },
              { Icon: Phone, text: "+1 (800) 326-6683", color: "#4CAF50" },
              {
                Icon: MapPin,
                text: "1234 Fan Ave, Los Angeles, CA",
                color: "#FF6B5C",
              },
            ].map((item, i) => (
              <div
                key={i}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  marginBottom: i < 2 ? 12 : 0,
                }}
              >
                <item.Icon size={16} color={item.color} />
                <span
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 14,
                    color: "var(--muted-2)",
                  }}
                >
                  {item.text}
                </span>
              </div>
            ))}
          </>,
          { marginBottom: 28 },
        )}
      </>
    )
  }

  const renderAbout = () => (
    <>
      <div style={{ padding: "18px 16px 0" }}>
        <div
          style={{
            background: ACCENT,
            borderRadius: 18,
            padding: "24px 22px",
            position: "relative",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              position: "absolute",
              top: -20,
              right: -20,
              width: 100,
              height: 100,
              background: "rgba(255,255,255,0.08)",
              borderRadius: "50%",
            }}
          />
          <div
            style={{
              position: "absolute",
              bottom: -30,
              right: 20,
              width: 70,
              height: 70,
              background: "rgba(255,255,255,0.06)",
              borderRadius: "50%",
            }}
          />
          <h2
            style={{
              fontFamily: "Space Grotesk, sans-serif",
              fontSize: 20,
              fontWeight: 700,
              color: "#fff",
              margin: "0 0 10px",
            }}
          >
            Built by fans, for fans
          </h2>
          <p
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
              color: "rgba(255,255,255,0.85)",
              margin: 0,
              lineHeight: 1.6,
            }}
          >
            Fandom Verse was born out of a simple frustration: fan content,
            events, and merchandise were scattered across dozens of platforms.
            We built one place to bring it all together.
          </p>
        </div>
        <p style={{ ...para, margin: "20px 0 0" }}>
          Our team of 12 is spread across Los Angeles, Seoul, and Tokyo — all
          united by the fandoms that shaped us growing up. We believe pop
          culture communities deserve a dedicated home, not just a hashtag.
        </p>
      </div>

      <div
        style={{
          display: "grid",
          gridTemplateColumns: "1fr 1fr",
          gap: 12,
          padding: "18px 16px 28px",
        }}
      >
        {team.map((member) => (
          <div
            key={member.name}
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              padding: 16,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 10,
            }}
          >
            <img
              src={member.img}
              alt={member.name}
              style={{
                width: 52,
                height: 52,
                borderRadius: 16,
                objectFit: "cover",
                border: "2px solid var(--border)",
              }}
            />
            <div style={{ textAlign: "center" }}>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                  marginBottom: 3,
                }}
              >
                {member.name}
              </div>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 12,
                  color: "var(--muted)",
                }}
              >
                {member.role}
              </div>
            </div>
          </div>
        ))}
      </div>

      <div style={{ borderTop: "1px solid var(--border)" }}>
        {renderSections([
          {
            heading: "Learn more",
            rows: [
              navRow(
                "careers",
                "Careers",
                "careers",
                "Join the team.",
                Briefcase,
              ),
              navRow("contact", "Contact us", "contact", "Say hello.", Mail),
              navRow(
                "privacy",
                "Privacy policy",
                "privacy",
                "How we handle your data.",
                Shield,
              ),
            ],
          },
        ])}
        <div style={{ height: 28 }} />
      </div>
    </>
  )

  const renderCookies = () => (
    <>
      {intro(
        "We use cookies and similar technologies to keep you signed in, understand how the app is used, and personalise what you see. You can change your choices at any time.",
      )}
      {renderSections([
        {
          heading: "Cookie preferences",
          rows: [
            toggleRow(
              "necessary",
              "Strictly necessary",
              "Required for sign-in, security and core features. Always on.",
              Shield,
              true,
              () => {},
              true,
            ),
            toggleRow(
              "performance",
              "Performance and analytics",
              "Helps us understand which features are used and where things break.",
              Activity,
              cookiePrefs.performance,
              () => toggleCookie("performance"),
            ),
            toggleRow(
              "functional",
              "Functional",
              "Remembers your theme, language and other choices.",
              Wifi,
              cookiePrefs.functional,
              () => toggleCookie("functional"),
            ),
            toggleRow(
              "targeting",
              "Advertising",
              "Used to show ads that are relevant to your interests.",
              Megaphone,
              cookiePrefs.targeting,
              () => toggleCookie("targeting"),
            ),
          ],
        },
      ])}
      <div style={{ padding: "16px 16px 0" }}>
        {primaryButton(
          savedNote ? "Preferences saved" : "Save preferences",
          () => setSavedNote("saved"),
          savedNote ? <Check size={16} /> : undefined,
        )}
        {savedNote && (
          <div
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
              color: "#4CAF50",
              marginTop: 10,
              textAlign: "center",
            }}
          >
            Your cookie choices are up to date.
          </div>
        )}
      </div>
      <div style={{ borderTop: "1px solid var(--border)", marginTop: 20 }}>
        {docSection({
          title: "What cookies we use",
          paras: [
            "Session cookies keep you signed in as you move around the app and expire when you close it.",
            "Preference cookies store your theme, wallpaper and language so the app looks the same next time you open it.",
            "Analytics cookies count visits and feature usage in aggregate, so we can decide what to build next.",
            "Advertising cookies are only set when you allow them, and are used to measure how well campaigns perform.",
          ],
        })}
        {docSection({
          title: "Managing cookies in your browser",
          paras: [
            "You can also block or delete cookies in your browser settings. Blocking strictly necessary cookies may stop you from signing in.",
          ],
        })}
        <div style={{ height: 28 }} />
      </div>
    </>
  )

  const renderAds = () => (
    <>
      {intro(
        "Control how advertising works on Fandom Verse, and find out how brands and creators work with us.",
      )}
      {renderSections([
        {
          heading: "Your ad experience",
          rows: [
            toggleRow(
              "personalized",
              "Personalized ads",
              "Use your activity in the app to pick ads you're more likely to care about.",
              Megaphone,
              adPrefs.personalized,
              () => toggleAds("personalized"),
            ),
            toggleRow(
              "inferred",
              "Ads from inferred activity",
              "Consider activity on devices you haven't used to sign in.",
              Info,
              adPrefs.inferred,
              () => toggleAds("inferred"),
            ),
            toggleRow(
              "partners",
              "Share with business partners",
              "Allow additional signals to be shared with advertising partners.",
              Users,
              adPrefs.partners,
              () => toggleAds("partners"),
            ),
          ],
        },
        {
          heading: "For business",
          rows: [
            navRow(
              "advertise",
              "Advertise with us",
              "contact",
              "Reach millions of fans with themed placements.",
              Megaphone,
            ),
            navRow(
              "partnerships",
              "Brand partnerships",
              "contact",
              "Sponsor events, guides and creator collabs.",
              Users,
            ),
            navRow(
              "creators",
              "Creator monetization",
              "contact",
              "Earn from subscriptions, tips and paid stories.",
              CreditCard,
            ),
          ],
        },
      ])}
      <div style={{ borderTop: "1px solid var(--border)", marginTop: 10 }}>
        {docSection({
          title: "How ads work",
          paras: [
            "Ads can appear in the home feed, on event pages and inside the shop. They're always labelled so you can tell them apart from organic posts.",
            "When personalization is on, we choose ads using your interests, the fandoms you follow and broad engagement patterns. We do not use the content of your private messages.",
            "Turning off personalized ads does not reduce the number of ads you see — it only changes which ones you see.",
          ],
        })}
        {docSection({
          title: "Working with us",
          paras: [
            "Branded content must be disclosed by creators, and never includes data that identifies individual members.",
            "For media kits, rates and sponsorship packages, reach out through Contact us and our partnerships team will follow up.",
          ],
        })}
        <div style={{ height: 28 }} />
      </div>
    </>
  )

  const renderBookmarks = () => {
    const items = bookmarkSeed.filter(
      (item) =>
        item.group === bookmarkTab && !removedBookmarks.includes(item.id),
    )
    return (
      <>
        <div
          style={{
            display: "flex",
            gap: 6,
            padding: "12px 16px",
            borderBottom: "1px solid var(--border)",
          }}
        >
          {(["Articles", "Stories", "Media"] as const).map((tab) =>
            chip(tab, bookmarkTab === tab, () => setBookmarkTab(tab)),
          )}
        </div>
        <div style={{ padding: "16px 16px 28px" }}>
          {items.map((item) => (
            <div
              key={item.id}
              style={{
                display: "flex",
                gap: 14,
                alignItems: "center",
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 14,
                padding: 14,
                marginBottom: 10,
              }}
            >
              <img
                src={item.img}
                alt={item.title}
                style={{
                  width: 54,
                  height: 54,
                  borderRadius: 10,
                  objectFit: "cover",
                  flexShrink: 0,
                }}
              />
              <div style={{ flex: 1, minWidth: 0 }}>
                <span
                  style={{
                    display: "inline-block",
                    fontFamily: "Inter, sans-serif",
                    fontSize: 11,
                    fontWeight: 600,
                    color: ACCENT,
                    background: "rgba(124,92,255,0.15)",
                    borderRadius: 999,
                    padding: "3px 9px",
                    marginBottom: 6,
                  }}
                >
                  {item.tag}
                </span>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 14.5,
                    fontWeight: 600,
                    color: "var(--text)",
                    lineHeight: 1.3,
                  }}
                >
                  {item.title}
                </div>
                <div
                  style={{
                    display: "flex",
                    alignItems: "center",
                    gap: 5,
                    marginTop: 5,
                    fontFamily: "Inter, sans-serif",
                    fontSize: 12,
                    color: "var(--muted)",
                  }}
                >
                  <Clock size={12} />
                  {item.saved}
                </div>
              </div>
              <button
                aria-label="Remove bookmark"
                onClick={() => setRemovedBookmarks((r) => [...r, item.id])}
                style={{
                  width: 34,
                  height: 34,
                  borderRadius: 9,
                  background: "rgba(124,92,255,0.15)",
                  border: "1px solid rgba(124,92,255,0.3)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: ACCENT,
                  cursor: "pointer",
                  flexShrink: 0,
                }}
              >
                <Bookmark size={16} fill={ACCENT} />
              </button>
            </div>
          ))}
          {items.length === 0 && (
            <div
              style={{
                padding: "54px 24px",
                textAlign: "center",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 8,
              }}
            >
              <span
                style={{
                  width: 52,
                  height: 52,
                  borderRadius: "50%",
                  background: "var(--surface)",
                  border: "1px solid var(--border)",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  color: "var(--muted)",
                }}
              >
                <Bookmark size={22} />
              </span>
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 17,
                  fontWeight: 700,
                  color: "var(--text)",
                }}
              >
                No bookmarks yet
              </span>
              <span
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13.5,
                  color: "var(--muted)",
                  lineHeight: 1.5,
                }}
              >
                Save posts, stories and media and they'll show up here.
              </span>
            </div>
          )}
        </div>
      </>
    )
  }

  const renderHistory = () => (
    <>
      {intro(
        "Every order placed on Fandom Verse, with receipts, status and refunds.",
      )}
      <div style={{ padding: "8px 16px 28px" }}>
        {orders.map((order, index) => (
          <button
            key={order.id}
            onClick={() => {
              setSelectedOrder(index)
              push("order")
            }}
            style={{
              width: "100%",
              display: "flex",
              alignItems: "center",
              gap: 14,
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              padding: 16,
              marginBottom: 10,
              cursor: "pointer",
              textAlign: "left",
            }}
          >
            <div style={{ flex: 1, minWidth: 0 }}>
              <div
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 8,
                  marginBottom: 6,
                }}
              >
                <span
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 14,
                    fontWeight: 700,
                    color: ACCENT,
                  }}
                >
                  {order.id}
                </span>
                <span
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 11,
                    fontWeight: 600,
                    color: statusColor(order.status),
                    background: `${statusColor(order.status)}22`,
                    borderRadius: 999,
                    padding: "3px 8px",
                  }}
                >
                  {order.status}
                </span>
              </div>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13,
                  color: "var(--muted)",
                  marginBottom: 6,
                }}
              >
                {order.date} · {order.items.length} item
                {order.items.length > 1 ? "s" : ""} · {order.note}
              </div>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 16,
                  fontWeight: 700,
                  color: "var(--text)",
                }}
              >
                {money(orderTotal(order))}
              </div>
            </div>
            <ChevronRight size={18} style={{ color: "var(--muted)" }} />
          </button>
        ))}
      </div>
    </>
  )

  const renderOrder = () => {
    const order = orders[selectedOrder]
    const steps =
      order.status === "Refunded"
        ? ["Order placed", "Payment confirmed", "Refund issued"]
        : ["Order placed", "Payment confirmed", "Shipped", "Delivered"]
    const doneSteps =
      order.status === "Delivered"
        ? steps.length
        : order.status === "Shipped"
          ? 3
          : 2
    const subtotal = order.items.reduce(
      (sum, item) => sum + item.price * item.qty,
      0,
    )

    return (
      <>
        <div style={{ padding: "16px 16px 0" }}>
          <div
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 16,
              padding: 18,
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: 14,
              }}
            >
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 15,
                  fontWeight: 700,
                  color: "var(--text)",
                }}
              >
                {order.note}
              </span>
              <span
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 11,
                  fontWeight: 600,
                  color: statusColor(order.status),
                  background: `${statusColor(order.status)}22`,
                  borderRadius: 999,
                  padding: "4px 10px",
                }}
              >
                {order.status}
              </span>
            </div>
            {steps.map((step, i) => {
              const done = i < doneSteps
              return (
                <div
                  key={step}
                  style={{ display: "flex", gap: 12, alignItems: "flex-start" }}
                >
                  <div
                    style={{
                      display: "flex",
                      flexDirection: "column",
                      alignItems: "center",
                      flexShrink: 0,
                    }}
                  >
                    <span
                      style={{
                        width: 20,
                        height: 20,
                        borderRadius: "50%",
                        background: done ? ACCENT : "var(--border-strong)",
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        color: "#fff",
                      }}
                    >
                      {done && <Check size={12} />}
                    </span>
                    {i < steps.length - 1 && (
                      <span
                        style={{
                          width: 2,
                          height: 26,
                          background:
                            i < doneSteps - 1 ? ACCENT : "var(--border)",
                        }}
                      />
                    )}
                  </div>
                  <span
                    style={{
                      fontFamily: "Inter, sans-serif",
                      fontSize: 13.5,
                      color: done ? "var(--text)" : "var(--muted)",
                      paddingTop: 1,
                    }}
                  >
                    {step}
                  </span>
                </div>
              )
            })}
          </div>
        </div>

        <div
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 19,
            fontWeight: 700,
            color: "var(--text)",
            padding: "22px 16px 10px",
          }}
        >
          Items
        </div>
        <div style={{ padding: "0 16px" }}>
          {order.items.map((item) => (
            <div
              key={item.title}
              style={{
                display: "flex",
                gap: 14,
                alignItems: "center",
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 14,
                padding: 14,
                marginBottom: 10,
              }}
            >
              <img
                src={item.img}
                alt={item.title}
                style={{
                  width: 54,
                  height: 54,
                  borderRadius: 10,
                  objectFit: "cover",
                  flexShrink: 0,
                }}
              />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 14.5,
                    fontWeight: 600,
                    color: "var(--text)",
                    lineHeight: 1.3,
                  }}
                >
                  {item.title}
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 13,
                    color: "var(--muted)",
                    marginTop: 4,
                  }}
                >
                  Qty {item.qty} · {money(item.price)} each
                </div>
              </div>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 15,
                  fontWeight: 700,
                  color: "var(--text)",
                }}
              >
                {money(item.price * item.qty)}
              </div>
            </div>
          ))}
        </div>

        <div style={{ padding: "8px 16px 0" }}>
          <div
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              padding: 16,
            }}
          >
            {[
              ["Subtotal", money(subtotal)],
              ["Shipping", order.shipping ? money(order.shipping) : "Free"],
            ].map(([label, value]) => (
              <div
                key={label}
                style={{
                  display: "flex",
                  justifyContent: "space-between",
                  fontFamily: "Inter, sans-serif",
                  fontSize: 14,
                  color: "var(--muted)",
                  marginBottom: 8,
                }}
              >
                <span>{label}</span>
                <span>{value}</span>
              </div>
            ))}
            <div
              style={{
                display: "flex",
                justifyContent: "space-between",
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 16,
                fontWeight: 700,
                color: "var(--text)",
                borderTop: "1px solid var(--border)",
                paddingTop: 10,
                marginTop: 2,
              }}
            >
              <span>Total</span>
              <span>{money(orderTotal(order))}</span>
            </div>
          </div>

          <div
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              padding: 16,
              marginTop: 10,
            }}
          >
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 14,
                fontWeight: 700,
                color: "var(--text)",
                marginBottom: 6,
              }}
            >
              Shipping address
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13.5,
                lineHeight: 1.55,
                color: "var(--muted-2)",
              }}
            >
              Alex Kim
              <br />
              1234 Fan Ave, Apt 21
              <br />
              Los Angeles, CA 90012
            </div>
          </div>

          <div style={{ display: "flex", gap: 10, margin: "16px 0 28px" }}>
            {ghostButton("Back to orders", () =>
              setStack((s) => (s.length > 1 ? s.slice(0, -1) : s)),
            )}
            {ghostButton("Get help", () => push("contact"))}
          </div>
        </div>
      </>
    )
  }

  const renderOffline = () => {
    const used = offlineSeed
      .filter((item) => downloads.includes(item.id))
      .reduce((sum, item) => sum + item.mb, 0)
    const percent = Math.min(100, (used / STORAGE_LIMIT) * 100)

    return (
      <>
        <div style={{ padding: "16px 16px 0" }}>
          <div
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 16,
              padding: 18,
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                marginBottom: 12,
              }}
            >
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 15,
                  fontWeight: 700,
                  color: "var(--text)",
                }}
              >
                Storage used
              </span>
              <span
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13,
                  color: "var(--muted)",
                }}
              >
                {used.toFixed(1)} MB of {STORAGE_LIMIT} MB
              </span>
            </div>
            <div
              style={{
                height: 8,
                borderRadius: 999,
                background: "var(--border)",
                overflow: "hidden",
              }}
            >
              <div
                style={{
                  width: `${Math.max(percent, used > 0 ? 3 : 0)}%`,
                  height: "100%",
                  borderRadius: 999,
                  background: `linear-gradient(90deg, ${ACCENT}, #9B84FF)`,
                  transition: "width 0.25s ease",
                }}
              />
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 12.5,
                color: "var(--muted)",
                marginTop: 10,
              }}
            >
              {downloads.length} item{downloads.length === 1 ? "" : "s"}{" "}
              available offline
            </div>
          </div>
        </div>

        {renderSections([
          {
            heading: "Download settings",
            rows: [
              toggleRow(
                "wifi",
                "Download over Wi-Fi only",
                "Never use mobile data for downloads.",
                Wifi,
                offlinePrefs.wifiOnly,
                () => toggleOffline("wifiOnly"),
              ),
              toggleRow(
                "autosave",
                "Auto-download saved items",
                "Keep bookmarked articles available offline.",
                Download,
                offlinePrefs.autoSave,
                () => toggleOffline("autoSave"),
              ),
            ],
          },
        ])}

        <div
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 19,
            fontWeight: 700,
            color: "var(--text)",
            padding: "20px 16px 10px",
          }}
        >
          Downloads
        </div>
        <div style={{ padding: "0 16px" }}>
          {offlineSeed.map((item) => {
            const has = downloads.includes(item.id)
            return (
              <div
                key={item.id}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 14,
                  background: "var(--surface)",
                  border: "1px solid var(--border)",
                  borderRadius: 14,
                  padding: 14,
                  marginBottom: 10,
                }}
              >
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div
                    style={{
                      fontFamily: "Space Grotesk, sans-serif",
                      fontSize: 14,
                      fontWeight: 600,
                      color: "var(--text)",
                      marginBottom: 5,
                    }}
                  >
                    {item.title}
                  </div>
                  <div
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 8,
                    }}
                  >
                    <span
                      style={{
                        fontFamily: "Inter, sans-serif",
                        fontSize: 11,
                        fontWeight: 600,
                        color: ACCENT,
                        background: "rgba(124,92,255,0.15)",
                        borderRadius: 999,
                        padding: "3px 9px",
                      }}
                    >
                      {item.tag}
                    </span>
                    <span
                      style={{
                        fontFamily: "Inter, sans-serif",
                        fontSize: 12,
                        color: "var(--muted)",
                      }}
                    >
                      {item.mb.toFixed(2)} MB ·{" "}
                      {has ? "Downloaded" : "Not downloaded"}
                    </span>
                  </div>
                </div>
                <button
                  aria-label={has ? "Remove download" : "Download"}
                  onClick={() =>
                    setDownloads((d) =>
                      has ? d.filter((x) => x !== item.id) : [...d, item.id],
                    )
                  }
                  style={{
                    width: 34,
                    height: 34,
                    borderRadius: 9,
                    background: has
                      ? "rgba(255,107,92,0.14)"
                      : "rgba(124,92,255,0.15)",
                    border: has
                      ? "1px solid rgba(255,107,92,0.3)"
                      : "1px solid rgba(124,92,255,0.3)",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    color: has ? "#FF6B5C" : ACCENT,
                    cursor: "pointer",
                    flexShrink: 0,
                  }}
                >
                  {has ? <Trash2 size={16} /> : <Download size={16} />}
                </button>
              </div>
            )
          })}
          {downloads.length > 0 && (
            <button
              onClick={() => setDownloads([])}
              style={{
                width: "100%",
                background: "transparent",
                border: "1px solid var(--border-strong)",
                borderRadius: 10,
                padding: "12px 14px",
                color: "#FF6B5C",
                fontFamily: "Inter, sans-serif",
                fontSize: 14,
                fontWeight: 600,
                cursor: "pointer",
                marginTop: 4,
              }}
            >
              Remove all downloads
            </button>
          )}
        </div>
        <div style={{ height: 28 }} />
      </>
    )
  }

  const renderCareers = () => (
    <>
      {intro(
        "We're a small team with big fandoms. Open roles are posted here first — no recruiters in between.",
      )}
      <div style={{ padding: "8px 16px 0" }}>
        {roles.map((role) => (
          <div
            key={role.title}
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              padding: 16,
              marginBottom: 10,
            }}
          >
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 15.5,
                fontWeight: 700,
                color: "var(--text)",
                marginBottom: 6,
              }}
            >
              {role.title}
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
                marginBottom: 14,
              }}
            >
              {role.dept} · {role.place} · {role.type}
            </div>
            <button
              onClick={() => push("contact")}
              style={{
                width: "100%",
                background: "rgba(124,92,255,0.15)",
                border: "1px solid rgba(124,92,255,0.35)",
                borderRadius: 10,
                padding: "11px 14px",
                color: ACCENT,
                fontFamily: "Inter, sans-serif",
                fontSize: 14,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              Apply
            </button>
          </div>
        ))}
        <div
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 13.5,
            lineHeight: 1.6,
            color: "var(--muted)",
            marginTop: 6,
            marginBottom: 28,
          }}
        >
          Don't see your role? Send us a note through Contact us — we're always
          happy to meet fans who build things.
        </div>
      </div>
    </>
  )

  const renderAccessibility = () => (
    <>
      {intro(
        "Fandom Verse is built to work for everyone. Adjust how content is displayed here, and tell us where we fall short.",
      )}
      {renderSections([
        {
          heading: "Display and interaction",
          rows: [
            toggleRow(
              "motion",
              "Reduce motion",
              "Minimise animations across feeds and reels.",
              Accessibility,
              a11yPrefs.motion,
              () => toggleA11y("motion"),
            ),
            toggleRow(
              "contrast",
              "Increase color contrast",
              "Make text and borders easier to read.",
              Info,
              a11yPrefs.contrast,
              () => toggleA11y("contrast"),
            ),
            toggleRow(
              "captions",
              "Always show media captions",
              "Captions appear automatically on video.",
              BookOpen,
              a11yPrefs.captions,
              () => toggleA11y("captions"),
            ),
            toggleRow(
              "large",
              "Larger text",
              "Increase the base font size across the app.",
              Users,
              a11yPrefs.largeText,
              () => toggleA11y("largeText"),
            ),
          ],
        },
        {
          heading: "Support",
          rows: [
            navRow(
              "contact",
              "Request an accommodation",
              "contact",
              "Tell us what you need and we'll help.",
              Mail,
            ),
          ],
        },
      ])}
      <div style={{ borderTop: "1px solid var(--border)", marginTop: 10 }}>
        {docSection({
          title: "Our commitment",
          paras: [
            "We target WCAG 2.1 AA across the app, including keyboard navigation, screen-reader labels and colour contrast on every surface.",
            "All new features are tested with assistive technology before release, and we run an accessibility review every quarter.",
            "If you hit a barrier, contact us with the page and device you used — reports from members drive our roadmap.",
          ],
        })}
        <div style={{ height: 28 }} />
      </div>
    </>
  )

  const body = () => {
    switch (page) {
      case "root":
        return filteredSections.length > 0 ? (
          renderSections(filteredSections)
        ) : (
          <div
            style={{
              padding: "40px 24px",
              textAlign: "center",
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
              color: "var(--muted)",
            }}
          >
            Nothing matches “{query.trim()}”.
          </div>
        )
      case "help":
        return renderHelp()
      case "faq":
        return renderFaq()
      case "contact":
        return renderContact()
      case "about":
        return renderAbout()
      case "cookies":
        return renderCookies()
      case "ads":
        return renderAds()
      case "bookmarks":
        return renderBookmarks()
      case "history":
        return renderHistory()
      case "order":
        return renderOrder()
      case "offline":
        return renderOffline()
      case "privacy":
        return (
          <>
            {intro(
              "Last updated September 2026. This policy applies to the Fandom Verse app and website.",
            )}
            {privacyDocs.map(docSection)}
            <div
              style={{ borderTop: "1px solid var(--border)", marginTop: 14 }}
            >
              {renderSections([
                {
                  heading: "Questions",
                  rows: [
                    navRow(
                      "contact",
                      "Contact our privacy team",
                      "contact",
                      "Ask about or delete your data.",
                      Mail,
                    ),
                    navRow(
                      "cookies",
                      "Manage cookies",
                      "cookies",
                      "Change your cookie preferences.",
                      Cookie,
                    ),
                    navRow(
                      "ads",
                      "Ads & Business",
                      "ads",
                      "Control ad personalization.",
                      Megaphone,
                    ),
                  ],
                },
              ])}
              <div style={{ height: 28 }} />
            </div>
          </>
        )
      case "terms":
        return (
          <>
            {intro(
              "Last updated September 2026. By using Fandom Verse you agree to these terms.",
            )}
            {termsDocs.map(docSection)}
            <div style={{ height: 28 }} />
          </>
        )
      case "careers":
        return renderCareers()
      case "accessibility":
        return renderAccessibility()
      default:
        return null
    }
  }

  return (
    <div
      style={{
        height: "100%",
        display: "flex",
        flexDirection: "column",
        background: "var(--app-bg)",
        overflow: "hidden",
      }}
    >
      <div
        style={{
          flexShrink: 0,
          background: "var(--app-bg)",
          borderBottom: "1px solid var(--border)",
        }}
      >
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 14,
            padding: "14px 16px 12px",
          }}
        >
          <button
            aria-label={backLabel}
            onClick={back}
            style={{
              width: 34,
              height: 34,
              borderRadius: 9,
              background: "var(--surface)",
              border: "1px solid var(--border)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              color: "var(--text)",
              cursor: "pointer",
              flexShrink: 0,
            }}
          >
            <ArrowLeft size={17} />
          </button>
          <div style={{ minWidth: 0 }}>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 17,
                fontWeight: 700,
                color: "var(--text)",
                lineHeight: 1.2,
              }}
            >
              {titles[page]}
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
                marginTop: 2,
              }}
            >
              {page === "root" ? "@alexkim" : "Help & more"}
            </div>
          </div>
        </div>

        {page === "root" && (
          <div style={{ padding: "0 16px 14px" }}>
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 999,
                padding: "10px 16px",
              }}
            >
              <Search size={16} style={{ color: "var(--muted)" }} />
              <input
                value={query}
                onChange={(event) => setQuery(event.target.value)}
                placeholder="Search Help & more"
                style={{
                  flex: 1,
                  minWidth: 0,
                  background: "none",
                  border: "none",
                  outline: "none",
                  color: "var(--text)",
                  fontFamily: "Inter, sans-serif",
                  fontSize: 14.5,
                }}
              />
            </div>
          </div>
        )}
      </div>

      <div style={{ flex: 1, overflowY: "auto" }}>{body()}</div>
      <div style={{ height: 12, flexShrink: 0, background: "var(--app-bg)" }} />
    </div>
  )
}
