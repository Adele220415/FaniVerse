import { useRef, useState } from "react"
import {
  Accessibility,
  Activity,
  ArrowLeft,
  ArrowUpRight,
  Ban,
  ChevronRight,
  CircleUser,
  Copy,
  CreditCard,
  Crown,
  Download,
  Eye,
  FileText,
  Gauge,
  ImagePlus,
  Info,
  Keyboard,
  Languages,
  Link2,
  Lock,
  MapPin,
  MessageCircle,
  Mic,
  Palette,
  Search,
  SlidersHorizontal,
  Smartphone,
  Sparkles,
  Star,
  Trash2,
  Type,
  User,
  Users,
} from "lucide-react"
import { THEMES, setTheme, themeLabel, useTheme, type Theme } from "../../theme"
import type { ResourcePage } from "../general/ResourceScreen"
import {
  addCustomWallpaper,
  removeCustomWallpaper,
  setWallpaper,
  useWallpaper,
  useWallpapers,
} from "../../wallpaper"

type IconType = React.ComponentType<{
  size?: number | string
  color?: string
  strokeWidth?: number
}>

type PageId = "root" | "detail" | "account" | "monetization" | "premium" | "security" | "privacy" | "notifications" | "filters" | "preferences" | "accessibility" | "a11y" | "display" | "theme" | "languages" | "datausage" | "shortcuts" | "resources"

type RowKind = "nav" | "external" | "value" | "toggle" | "radio" | "custom"

interface Row {
  id: string
  label: string
  desc?: string
  icon?: IconType
  thumb?: string
  kind?: RowKind
  page?: PageId
  value?: string
  selected?: boolean
  trailingIcon?: IconType
  onSelect?: () => void
  onOpen?: () => void
}

interface Section {
  heading?: string
  rows: Row[]
}

interface PageDef {
  title: string
  intro?: string
  sections: Section[]
}

const HANDLE = "@alexkim"

const shortcuts: [string, string][] = [
  ["Ctrl + K", "Jump to search"],
  ["Ctrl + /", "Shortcut help"],
  ["Ctrl + Enter", "Send post"],
  ["Esc", "Close dialog"],
  ["g then h", "Go to Home"],
  ["g then p", "Go to Profile"],
]

const languages = ["English", "Español", "日本語", "Français", "Deutsch"]

export default function SettingsScreen({
  onBack,
  onLogout,
  onOpenResource,
}: {
  onBack?: () => void
  onLogout?: () => void
  onOpenResource?: (page: ResourcePage) => void
}) {
  const theme = useTheme()
  const wallpaper = useWallpaper()
  const wallpapers = useWallpapers()
  const wallpaperRef = useRef<HTMLInputElement>(null)
  const [stack, setStack] = useState<PageId[]>(["root"])
  const [query, setQuery] = useState("")
  const [language, setLanguage] = useState("English")
  const [detail, setDetail] = useState<{
    label: string
    desc?: string
  }>({
    label: "Setting",
  })
  const [notifMode, setNotifMode] = useState<"all" | "filtered" | "off">("all")
  const [uploadError, setUploadError] = useState("")
  const [toggles, setToggles] = useState<Record<string, boolean>>({
    motion: false,
    contrast: false,
    captions: true,
    dataSaver: false,
    autoplay: true,
    likes: true,
    reposts: false,
    mentions: true,
    followers: true,
    messages: true,
    quotes: false,
  })

  const page = stack[stack.length - 1]
  const toggle = (key: string) =>
    setToggles((state) => ({ ...state, [key]: !state[key] }))

  const push = (next: PageId) => setStack((s) => [...s, next])
  const handleBack = () => {
    if (stack.length > 1) setStack((s) => s.slice(0, -1))
    else onBack?.()
  }

  const wallpaperRows: Row[] = [
    {
      id: "wp-none",
      label: "No wallpaper",
      desc: "Solid background from your base theme.",
      kind: "radio",
      selected: !wallpaper,
      onSelect: () => setWallpaper(null),
    },
    ...wallpapers.map((item) => ({
      id: `wp-${item.id}`,
      label: item.label,
      desc: item.desc,
      thumb: item.src,
      kind: "radio" as const,
      selected: wallpaper?.id === item.id,
      onSelect: () => setWallpaper(item.id),
    })),
    ...(wallpapers.some((item) => item.id === "custom")
      ? [
          {
            id: "wp-remove",
            label: "Remove my image",
            desc: "Deletes the picture you uploaded.",
            kind: "nav" as const,
            trailingIcon: Trash2,
            onOpen: () => removeCustomWallpaper(),
          },
        ]
      : []),
    {
      id: "wp-add",
      label: "Add your own image",
      desc: "Upload a picture and matching colours are made from it.",
      kind: "custom" as const,
      trailingIcon: ImagePlus,
      onSelect: () => wallpaperRef.current?.click(),
    },
    ...(uploadError
      ? [{ id: "wp-error", label: uploadError, kind: "value" as const }]
      : []),
  ]

  const handleWallpaperFile = async (
    event: React.ChangeEvent<HTMLInputElement>,
  ) => {
    const file = event.target.files?.[0]
    event.target.value = ""
    if (!file) return
    setUploadError("")
    try {
      await addCustomWallpaper(file)
    } catch {
      setUploadError("That file could not be used as a wallpaper.")
    }
  }

  const t = (key: string, label: string, icon?: IconType): Row => ({
    id: key,
    label,
    icon,
    kind: "toggle",
    selected: toggles[key],
    onSelect: () => toggle(key),
  })

  const nav = (
    id: string,
    label: string,
    page: PageId,
    desc?: string,
    icon?: IconType,
    value?: string,
  ): Row => ({ id, label, page, desc, icon, kind: "nav", value })

  const external = (id: string, label: string): Row => ({
    id,
    label,
    kind: "external",
  })

  const resource = (
    id: string,
    label: string,
    target: ResourcePage,
    desc?: string,
    icon?: IconType,
  ): Row => ({
    id,
    label,
    desc,
    icon,
    kind: "nav",
    page: "detail",
    onOpen: onOpenResource ? () => onOpenResource(target) : undefined,
  })

  const pages: Record<PageId, PageDef> = {
    root: {
      title: "Settings",
      sections: [
        {
          rows: [
            resource(
              "history",
              "Purchase history",
              "history",
              "Track your orders and view past purchases.",
              CreditCard,
            ),
            nav("account", "Your account", "account"),
            nav("monetization", "Monetization", "monetization"),
            nav("premium", "Premium", "premium"),
            nav("security", "Security and account access", "security"),
            nav("privacy", "Privacy and safety", "privacy"),
            nav("notifications", "Notifications", "notifications"),
            nav(
              "accessibility",
              "Accessibility, display, and languages",
              "accessibility",
            ),
            nav(
              "theme",
              "Theme",
              "theme",
              undefined,
              undefined,
              wallpaper ? wallpaper.label : themeLabel(theme),
            ),
            nav("resources", "Additional resources", "resources"),
            resource("help", "Help Center", "help"),
          ],
        },
      ],
    },
    detail: {
      title: detail.label,
      intro: detail.desc,
      sections: [],
    },
    account: {
      title: "Your account",
      intro:
        "See information about your account, download an archive of your data, or learn about your account deactivation options.",
      sections: [
        {
          rows: [
            nav(
              "info",
              "Account information",
              "detail",
              "See your account information like your phone number and email address.",
              User,
            ),
            nav(
              "password",
              "Change your password",
              "detail",
              "Change your password at any time.",
              Lock,
            ),
            nav(
              "archive",
              "Download an archive of your data",
              "detail",
              "Get insights into the type of information stored for your account.",
              Download,
            ),
            nav(
              "deactivate",
              "Deactivate your account",
              "detail",
              "Find out how you can deactivate your account.",
              Ban,
            ),
          ],
        },
      ],
    },
    monetization: {
      title: "Monetization",
      intro: "Earn money on X and manage how you get paid.",
      sections: [
        {
          rows: [
            nav(
              "revenue",
              "Creator revenue sharing",
              "detail",
              "Earn a share of the revenue from ads shown in your replies.",
              Sparkles,
            ),
            nav(
              "subs",
              "Subscriptions",
              "detail",
              "Offer your followers exclusive content for a monthly fee.",
              Star,
            ),
            nav(
              "payouts",
              "Payouts",
              "detail",
              "Manage how you get paid and keep an eye on your earnings.",
              CreditCard,
            ),
            nav(
              "tax",
              "Tax information",
              "detail",
              "Add or update the tax information for your payouts.",
              FileText,
            ),
          ],
        },
      ],
    },
    premium: {
      title: "Premium",
      intro: "Subscribe to Premium to unlock new features and support X.",
      sections: [
        {
          rows: [
            nav(
              "manage",
              "Manage your subscription",
              "detail",
              "View your plan, billing cycle and renewal date.",
              Crown,
            ),
            nav(
              "features",
              "Premium features",
              "detail",
              "See everything that comes with your subscription.",
              Sparkles,
            ),
            nav(
              "restore",
              "Restore purchase",
              "detail",
              "Restore a purchase made on another device.",
              Smartphone,
            ),
          ],
        },
      ],
    },
    security: {
      title: "Security and account access",
      intro:
        "Manage your account's security and keep track of your account's usage including apps that you have connected to your account.",
      sections: [
        {
          rows: [
            nav(
              "sec",
              "Security",
              "detail",
              "Manage your account's security.",
              Lock,
            ),
            nav(
              "sessions",
              "Apps and sessions",
              "detail",
              "See information about when you logged into your account and the apps you connected to your account.",
              Copy,
            ),
            nav(
              "connected",
              "Connected accounts",
              "detail",
              "Manage Google or Apple accounts connected to X to log in.",
              Link2,
            ),
            nav(
              "delegate",
              "Delegate",
              "detail",
              "Manage your shared accounts.",
              Users,
            ),
          ],
        },
      ],
    },
    privacy: {
      title: "Privacy and safety",
      intro: "Manage what information you see and share on X.",
      sections: [
        {
          heading: "Your X activity",
          rows: [
            nav(
              "audience",
              "Audience, media and tagging",
              "detail",
              "Manage what information you allow other people on X to see.",
              Users,
            ),
            nav(
              "posts",
              "Your posts",
              "detail",
              "Manage the information associated with your posts.",
              Type,
            ),
            nav(
              "content",
              "Content you see",
              "detail",
              "Decide what you see on X based on your preferences like interests.",
              Eye,
            ),
            nav(
              "mute",
              "Mute and block",
              "detail",
              "Manage the accounts, words, and notifications that you've muted or blocked.",
              Ban,
            ),
            nav(
              "chat",
              "Chat",
              "detail",
              "Manage who can message you directly.",
              MessageCircle,
            ),
            nav(
              "spaces",
              "Spaces",
              "detail",
              "Manage who can see your Spaces listening activity.",
              Mic,
            ),
            nav(
              "discover",
              "Discoverability and contacts",
              "detail",
              "Control your discoverability settings and manage contacts you've imported.",
              CircleUser,
            ),
          ],
        },
        {
          heading: "Data sharing and personalization",
          rows: [
            nav(
              "ads",
              "Ads preferences",
              "detail",
              "Manage your ads experience on X.",
              Star,
            ),
            nav(
              "inferred",
              "Inferred identity",
              "detail",
              "Allow X to personalize your experience with your inferred activity, e.g. activity on devices you haven't used to log in to X.",
              Activity,
            ),
            nav(
              "partners",
              "Data sharing with business partners",
              "detail",
              "Allow sharing of additional information with X's business partners.",
              Link2,
            ),
            nav(
              "location",
              "Location information",
              "detail",
              "Manage the location information X uses to personalize your experience.",
              MapPin,
            ),
            nav(
              "grok",
              "Grok & Third-party Collaborators",
              "detail",
              "Allow your public data as well as your interactions, inputs, and results with Grok and xAI to be used for training and fine-tuning.",
              Sparkles,
            ),
          ],
        },
        {
          heading: "Learn more about privacy on X",
          rows: [
            external("center", "Privacy center"),
            resource("policy", "Privacy policy", "privacy"),
          ],
        },
      ],
    },
    notifications: {
      title: "Notifications",
      intro:
        "Select the kinds of notifications you get about your activities, interests, and recommendations.",
      sections: [
        {
          rows: [
            nav(
              "filters",
              "Filters",
              "filters",
              "Choose the notifications you'd like to see — and those you don't.",
              SlidersHorizontal,
            ),
            nav(
              "prefs",
              "Preferences",
              "preferences",
              "Select your preferences by notification type.",
              Smartphone,
            ),
          ],
        },
      ],
    },
    filters: {
      title: "Filters",
      intro:
        "Choose the notifications you'd like to see — and those you don't.",
      sections: [
        {
          rows: [
            t("likes", "Likes"),
            t("reposts", "Reposts and quotes"),
            t("mentions", "Mentions"),
            t("followers", "New followers"),
            t("messages", "Direct messages"),
            t("quotes", "Video posts"),
          ],
        },
      ],
    },
    preferences: {
      title: "Preferences",
      intro: "Choose how often you hear from us.",
      sections: [
        {
          rows: [
            {
              id: "all",
              label: "All notifications",
              desc: "Get every notification about your activity.",
              kind: "radio",
              selected: notifMode === "all",
              onSelect: () => setNotifMode("all"),
            },
            {
              id: "filtered",
              label: "Filtered",
              desc: "Only notifications from people you follow.",
              kind: "radio",
              selected: notifMode === "filtered",
              onSelect: () => setNotifMode("filtered"),
            },
            {
              id: "off",
              label: "Off",
              desc: "Stop all push notifications from X.",
              kind: "radio",
              selected: notifMode === "off",
              onSelect: () => setNotifMode("off"),
            },
          ],
        },
      ],
    },
    accessibility: {
      title: "Accessibility, display and languages",
      intro: "Manage how X content is displayed to you.",
      sections: [
        {
          rows: [
            nav(
              "a11y",
              "Accessibility",
              "a11y",
              "Manage aspects of your X experience such as limiting color contrast and motion.",
              Accessibility,
            ),
            nav(
              "display",
              "Display",
              "display",
              "Manage your font size, color, and background. These settings affect all the X accounts on this browser.",
              Palette,
            ),
            nav(
              "language",
              "Languages",
              "languages",
              "Manage which languages are used to personalize your X experience.",
              Languages,
            ),
            {
              id: "data",
              label: "Data usage",
              desc: "Limit how X uses some of your network data on this device.",
              icon: Gauge,
              kind: "nav",
              page: "datausage",
              value: toggles.dataSaver ? "Data saver" : "Standard",
            },
            nav(
              "shortcuts",
              "Keyboard shortcuts",
              "shortcuts",
              undefined,
              Keyboard,
            ),
          ],
        },
      ],
    },
    a11y: {
      title: "Accessibility",
      intro: "Manage aspects of your X experience.",
      sections: [
        {
          rows: [
            t("motion", "Reduce motion", Activity),
            t("contrast", "Increase color contrast", Eye),
            t("captions", "Always show media captions", Type),
          ],
        },
      ],
    },
    display: {
      title: "Display",
      intro: "Manage your font size, color, and background.",
      sections: [
        {
          rows: [
            nav(
              "theme",
              "Theme",
              "theme",
              undefined,
              Palette,
              wallpaper ? wallpaper.label : themeLabel(theme),
            ),
            {
              id: "fontsize",
              label: "Text size",
              kind: "value",
              value: "Default",
            },
            {
              id: "color",
              label: "Color",
              kind: "value",
              value: "Violet",
            },
          ],
        },
      ],
    },
    theme: {
      title: "Theme",
      intro:
        "Set a picture wallpaper with colours pulled from the image, or pick a base theme. These settings affect all the X accounts on this browser.",
      sections: [
        {
          heading: "Wallpaper",
          rows: wallpaperRows,
        },
        {
          heading: "Base theme",
          rows: THEMES.map((option) => ({
            id: option.id,
            label: option.label,
            desc: option.desc,
            kind: "radio" as const,
            selected: theme === option.id,
            onSelect: () => setTheme(option.id as Theme),
          })),
        },
      ],
    },
    datausage: {
      title: "Data usage",
      intro: "Limit how much data X uses on this device.",
      sections: [
        {
          rows: [
            {
              id: "standard",
              label: "Standard",
              desc: "Full quality images and video.",
              kind: "radio",
              selected: !toggles.dataSaver,
              onSelect: () =>
                setToggles((state) => ({ ...state, dataSaver: false })),
            },
            {
              id: "saver",
              label: "Data saver",
              desc: "Lower image and video quality to reduce data use.",
              kind: "radio",
              selected: toggles.dataSaver,
              onSelect: () =>
                setToggles((state) => ({ ...state, dataSaver: true })),
            },
          ],
        },
      ],
    },
    languages: {
      title: "Languages",
      intro:
        "Manage which languages are used to personalize your X experience.",
      sections: [
        {
          rows: languages.map((lang) => ({
            id: lang,
            label: lang,
            kind: "radio" as const,
            selected: language === lang,
            onSelect: () => setLanguage(lang),
          })),
        },
      ],
    },
    shortcuts: {
      title: "Keyboard shortcuts",
      sections: [
        {
          rows: shortcuts.map(([keys, action]) => ({
            id: keys,
            label: action,
            kind: "value" as const,
            value: keys,
          })),
        },
      ],
    },
    resources: {
      title: "Additional resources",
      intro:
        "Check out other places for helpful information to learn more about X products and services.",
      sections: [
        {
          rows: [external("release", "Release notes")],
        },
        {
          heading: "Legal",
          rows: [
            resource("ads", "Ads & Business", "ads"),
            resource("cookies", "Cookies", "cookies"),
            resource("privacy", "Privacy", "privacy"),
            resource("terms", "Terms", "terms"),
          ],
        },
        {
          heading: "Miscellaneous",
          rows: [
            resource("about", "About", "about"),
            resource("accessibility", "Accessibility", "accessibility"),
            resource("careers", "Careers", "careers"),
          ],
        },
      ],
    },
  }

  const current = pages[page]
  const showSearch = page === "root" && query.trim().length > 0
  const sections = showSearch
    ? [
        {
          rows: current.sections
            .flatMap((section) => section.rows)
            .filter((row) =>
              `${row.label} ${row.desc ?? ""}`
                .toLowerCase()
                .includes(query.trim().toLowerCase()),
            ),
        },
      ]
    : current.sections

  const handleRow = (row: Row) => {
    if (row.kind === "toggle" || row.kind === "radio" || row.kind === "custom")
      row.onSelect?.()
    else if (row.kind === "nav") {
      if (row.onOpen) row.onOpen()
      else if (row.page) {
        if (row.page === "detail")
          setDetail({ label: row.label, desc: row.desc })
        push(row.page)
      }
    }
  }

  const trailing = (row: Row) => {
    if (row.trailingIcon) {
      const Trailing = row.trailingIcon
      return <Trailing size={16} color="var(--muted)" />
    }
    if (row.kind === "toggle") {
      const on = row.selected ?? false
      return (
        <span
          style={{
            width: 42,
            height: 24,
            borderRadius: 12,
            background: on ? "#7C5CFF" : "var(--border-strong)",
            position: "relative",
            flexShrink: 0,
            transition: "background 0.18s ease",
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
    if (row.kind === "radio") {
      return (
        <span
          style={{
            width: 20,
            height: 20,
            borderRadius: "50%",
            border: `2px solid ${
              row.selected ? "#7C5CFF" : "var(--border-strong)"
            }`,
            background: row.selected ? "#7C5CFF" : "transparent",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            flexShrink: 0,
          }}
        >
          {row.selected && (
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none">
              <path
                d="M5 13l4 4L19 7"
                stroke="#fff"
                strokeWidth="3.4"
                strokeLinecap="round"
                strokeLinejoin="round"
              />
            </svg>
          )}
        </span>
      )
    }
    if (row.kind === "value") {
      return row.value ? (
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
      ) : null
    }
    if (row.kind === "external") {
      return <ArrowUpRight size={16} style={{ color: "var(--muted)" }} />
    }
    return (
      <span
        style={{ display: "flex", alignItems: "center", gap: 6, flexShrink: 0 }}
      >
        {row.value && (
          <span
            style={{
              fontSize: 14,
              color: "var(--muted)",
              maxWidth: 150,
              overflow: "hidden",
              textOverflow: "ellipsis",
              whiteSpace: "nowrap",
            }}
          >
            {row.value}
          </span>
        )}
        <ChevronRight size={16} style={{ color: "var(--muted)" }} />
      </span>
    )
  }

  const renderRow = (row: Row, index: number, total: number) => {
    const Icon = row.icon
    const interactive = row.kind !== "value"
    return (
      <button
        key={`${page}-${row.id}`}
        onClick={() => handleRow(row)}
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
        {row.thumb && (
          <img
            src={row.thumb}
            alt=""
            style={{
              width: 46,
              height: 46,
              borderRadius: 12,
              objectFit: "cover",
              border: `2px solid ${
                row.selected ? "#7C5CFF" : "var(--border-strong)"
              }`,
              flexShrink: 0,
            }}
          />
        )}
        {!row.thumb && Icon && (
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
              color: "var(--text)",
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
        {trailing(row)}
      </button>
    )
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
      <input
        ref={wallpaperRef}
        type="file"
        accept="image/*"
        onChange={handleWallpaperFile}
        style={{ display: "none" }}
      />
      <div
        style={{
          position: "sticky",
          top: 0,
          zIndex: 10,
          background: "var(--app-bg)",
          borderBottom: "1px solid var(--border)",
          flexShrink: 0,
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
            aria-label="Back"
            onClick={handleBack}
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
              {current.title}
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
                marginTop: 2,
              }}
            >
              {HANDLE}
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
                placeholder="Search Settings"
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

      <div style={{ flex: 1, overflowY: "auto" }}>
        {current.intro && (
          <p
            style={{
              margin: 0,
              padding: "16px 16px 4px",
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
              lineHeight: 1.45,
              color: "var(--muted)",
            }}
          >
            {current.intro}
          </p>
        )}

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
                  fontSize: 20,
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

        {page === "detail" && (
          <div
            style={{
              padding: "34px 32px",
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              textAlign: "center",
              gap: 10,
            }}
          >
            <span
              style={{
                width: 46,
                height: 46,
                borderRadius: "50%",
                background: "var(--surface)",
                border: "1px solid var(--border)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                color: "var(--muted)",
              }}
            >
              <Info size={20} />
            </span>
            <span
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 16,
                fontWeight: 700,
                color: "var(--text)",
              }}
            >
              Not available in this preview
            </span>
            <span
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13.5,
                lineHeight: 1.5,
                color: "var(--muted)",
              }}
            >
              This part of Settings is still being built. Theme, Filters,
              Preferences, Privacy and safety and the language picker are fully
              interactive.
            </span>
          </div>
        )}

        {showSearch && sections[0].rows.length === 0 && (
          <div
            style={{
              padding: "36px 16px",
              textAlign: "center",
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
              color: "var(--muted)",
            }}
          >
            No settings match “{query.trim()}”.
          </div>
        )}

        {page === "root" && (
          <div
            style={{
              borderTop: "1px solid var(--border)",
              marginTop: 10,
              paddingBottom: 28,
            }}
          >
            <button
              onClick={() => onLogout?.()}
              style={{
                width: "100%",
                display: "flex",
                alignItems: "center",
                gap: 16,
                padding: "16px",
                background: "none",
                border: "none",
                cursor: "pointer",
                fontFamily: "Inter, sans-serif",
                fontSize: 15.5,
                color: "#FF6B5C",
                textAlign: "left",
              }}
            >
              Log out
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
