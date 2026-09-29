import type { ReactNode } from "react"
import BackButton from "./BackButton"
import type { ResourcePage } from "../screens/general/ResourceScreen"

const u = (id: string, w: number, h: number) =>
  `https://images.unsplash.com/${id}?w=${w}&h=${h}&fit=crop&auto=format`

const ME = "photo-1519345182560-3f2917c472ef"

const stroke = {
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.9,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
}

const icon = (path: ReactNode, size = 22) => (
  <svg
    width={size}
    height={size}
    viewBox="0 0 24 24"
    {...stroke}
    style={{ flexShrink: 0 }}
  >
    {path}
  </svg>
)

export type DrawerTab = "profile" | "events" | "shop" | "home" | "explore"

export default function SideDrawer({
  open,
  onClose,
  onNavigate,
  onOpenSettings,
  onOpenResource,
}: {
  open: boolean
  onClose: () => void
  onNavigate: (tab: DrawerTab) => void
  onOpenSettings?: () => void
  onOpenResource?: (page: ResourcePage) => void
}) {
  if (!open) return null

  const items: {
    label: string
    icon: ReactNode
    go?: DrawerTab
    settings?: boolean
    resource?: ResourcePage
  }[] = [
    {
      label: "Profile",
      go: "profile",
      icon: icon(
        <>
          <path d="M20 21v-2a4 4 0 00-4-4H8a4 4 0 00-4 4v2" />
          <circle cx="12" cy="7" r="4" />
        </>,
      ),
    },
    {
      label: "Bookmarks",
      resource: "bookmarks",
      icon: icon(<path d="M19 21l-7-5-7 5V5a2 2 0 012-2h10a2 2 0 012 2z" />),
    },
    {
      label: "Communities",
      go: "explore",
      icon: icon(
        <>
          <path d="M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2" />
          <circle cx="9" cy="7" r="4" />
          <path d="M23 21v-2a4 4 0 00-3-3.87" />
          <path d="M16 3.13a4 4 0 010 7.75" />
        </>,
      ),
    },
    {
      label: "Events",
      go: "events",
      icon: icon(
        <>
          <rect x="3" y="4" width="18" height="18" rx="2" />
          <line x1="16" y1="2" x2="16" y2="6" />
          <line x1="8" y1="2" x2="8" y2="6" />
          <line x1="3" y1="10" x2="21" y2="10" />
        </>,
      ),
    },
    {
      label: "Shop",
      go: "shop",
      icon: icon(
        <>
          <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" />
          <line x1="3" y1="6" x2="21" y2="6" />
          <path d="M16 10a4 4 0 01-8 0" />
        </>,
      ),
    },
    {
      label: "Purchase History",
      resource: "history",
      icon: icon(
        <>
          <rect x="2" y="5" width="20" height="14" rx="2" />
          <line x1="2" y1="10" x2="22" y2="10" />
        </>,
      ),
    },
    {
      label: "Offline Content",
      resource: "offline",
      icon: icon(
        <>
          <path d="M21 15v4a2 2 0 01-2 2H5a2 2 0 01-2-2v-4" />
          <polyline points="7 10 12 15 17 10" />
          <line x1="12" y1="15" x2="12" y2="3" />
        </>,
      ),
    },
    {
      label: "Help Center",
      resource: "help",
      icon: icon(
        <>
          <circle cx="12" cy="12" r="10" />
          <path d="M9.09 9a3 3 0 015.83 1c0 2-3 3-3 3" />
          <line x1="12" y1="17" x2="12.01" y2="17" />
        </>,
      ),
    },
    {
      label: "Settings and privacy",
      settings: true,
      icon: icon(
        <>
          <circle cx="12" cy="12" r="3" />
          <path d="M19.4 15a1.65 1.65 0 00.33 1.82l.06.06a2 2 0 01-2.83 2.83l-.06-.06a1.65 1.65 0 00-1.82-.33 1.65 1.65 0 00-1 1.51V21a2 2 0 01-4 0v-.09A1.65 1.65 0 009 19.4a1.65 1.65 0 00-1.82.33l-.06.06a2 2 0 01-2.83-2.83l.06-.06a1.65 1.65 0 00.33-1.82 1.65 1.65 0 00-1.51-1H3a2 2 0 010-4h.09A1.65 1.65 0 004.6 9a1.65 1.65 0 00-.33-1.82l-.06-.06a2 2 0 012.83-2.83l.06.06a1.65 1.65 0 001.82.33H9a1.65 1.65 0 001-1.51V3a2 2 0 014 0v.09a1.65 1.65 0 001 1.51 1.65 1.65 0 001.82-.33l.06-.06a2 2 0 012.83 2.83l-.06.06a1.65 1.65 0 00-.33 1.82V9a1.65 1.65 0 001.51 1H21a2 2 0 010 4h-.09a1.65 1.65 0 00-1.51 1z" />
        </>,
      ),
    },
  ]

  return (
    <div style={{ position: "absolute", inset: 0, zIndex: 40 }}>
      <div
        onClick={onClose}
        className="drawer-backdrop"
        style={{
          position: "absolute",
          inset: 0,
          background: "rgba(0,0,0,0.6)",
        }}
      />
      <div
        className="drawer-panel"
        style={{
          position: "absolute",
          top: 0,
          left: 0,
          bottom: 0,
          width: 302,
          maxWidth: "82%",
          background: "var(--app-bg)",
          borderRight: "1px solid var(--border)",
          display: "flex",
          flexDirection: "column",
          overflowY: "auto",
          boxShadow: "12px 0 40px rgba(0,0,0,0.55)",
        }}
      >
        <div style={{ padding: "52px 18px 0" }}>
          <BackButton
            onClick={onClose}
            label="Close menu"
            style={{ marginBottom: 14, marginLeft: -4 }}
          />
          <div
            style={{
              display: "flex",
              alignItems: "flex-start",
              justifyContent: "space-between",
            }}
          >
            <img
              src={u(ME, 160, 160)}
              alt="Alex Kim"
              style={{
                width: 56,
                height: 56,
                borderRadius: "50%",
                objectFit: "cover",
                display: "block",
              }}
            />
            <button
              aria-label="Add account"
              style={{
                width: 32,
                height: 32,
                borderRadius: "50%",
                background: "transparent",
                border: "1px solid var(--border-strong)",
                color: "var(--text)",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                cursor: "pointer",
              }}
            >
              <svg
                width="16"
                height="16"
                viewBox="0 0 24 24"
                {...stroke}
                strokeWidth={2.2}
              >
                <line x1="12" y1="5" x2="12" y2="19" />
                <line x1="5" y1="12" x2="19" y2="12" />
              </svg>
            </button>
          </div>

          <div
            style={{
              fontFamily: "Space Grotesk",
              fontSize: 20,
              fontWeight: 700,
              color: "var(--text)",
              marginTop: 14,
            }}
          >
            Alex Kim
          </div>
          <div
            style={{
              fontFamily: "Inter",
              fontSize: 14.5,
              color: "var(--muted)",
              marginTop: 2,
            }}
          >
            @alexkim
          </div>

          <div
            style={{
              display: "flex",
              gap: 18,
              marginTop: 14,
              fontFamily: "Inter",
              fontSize: 14,
            }}
          >
            <span style={{ color: "var(--text)" }}>
              <strong style={{ fontWeight: 700 }}>128</strong>
              <span style={{ color: "var(--muted)" }}> Following</span>
            </span>
            <span style={{ color: "var(--text)" }}>
              <strong style={{ fontWeight: 700 }}>6</strong>
              <span style={{ color: "var(--muted)" }}> Followers</span>
            </span>
          </div>
        </div>

        <div
          style={{
            height: 1,
            background: "var(--border)",
            margin: "18px 0 6px",
          }}
        />

        <div style={{ padding: "6px 18px 24px" }}>
          {items.map((it) => (
            <div
              key={it.label}
              onClick={() => {
                if (it.settings) onOpenSettings?.()
                else if (it.resource) onOpenResource?.(it.resource)
                else if (it.go) onNavigate(it.go)
                onClose()
              }}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 18,
                padding: "13px 4px",
                cursor: "pointer",
                color: "var(--text)",
              }}
            >
              {it.icon}
              <span
                style={{
                  fontFamily: "Space Grotesk",
                  fontSize: 17,
                  fontWeight: 600,
                }}
              >
                {it.label}
              </span>
            </div>
          ))}

          <div
            style={{
              height: 1,
              background: "var(--border)",
              margin: "10px 0",
            }}
          />

          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 18,
              padding: "13px 4px",
              cursor: "pointer",
              color: "#FF6B5C",
            }}
          >
            {icon(
              <>
                <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4" />
                <polyline points="16 17 21 12 16 7" />
                <line x1="21" y1="12" x2="9" y2="12" />
              </>,
            )}
            <span
              style={{
                fontFamily: "Space Grotesk",
                fontSize: 17,
                fontWeight: 600,
              }}
            >
              Log out
            </span>
          </div>
        </div>
      </div>
    </div>
  )
}
