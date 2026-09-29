import { useState } from "react"
import HomeTab from "./tabs/HomeTab"
import ExploreTab from "./tabs/ExploreTab"
import EventsTab from "./tabs/EventsTab"
import ShopTab from "./tabs/ShopTab"
import ProfileTab from "./tabs/ProfileTab"
import SideDrawer from "../components/SideDrawer"
import CreatorStudio from "../components/CreatorStudio"
import ResourceScreen, { type ResourcePage } from "./general/ResourceScreen"
import { AIChatSheet } from "./tabs/HomeTab"

type Tab = "home" | "explore" | "events" | "shop" | "profile"

const tabs: {
  id: Tab
  label: string
  icon: (active: boolean) => React.ReactNode
}[] = [
  {
    id: "home",
    label: "Home",
    icon: (a) => (
      <svg
        width="22"
        height="22"
        viewBox="0 0 24 24"
        fill="none"
        stroke={a ? "#7C5CFF" : "var(--muted)"}
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
        <polyline points="9 22 9 12 15 12 15 22" />
      </svg>
    ),
  },
  {
    id: "explore",
    label: "Explore",
    icon: (a) => (
      <svg
        width="22"
        height="22"
        viewBox="0 0 24 24"
        fill="none"
        stroke={a ? "#7C5CFF" : "var(--muted)"}
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <circle cx="11" cy="11" r="8" />
        <line x1="21" y1="21" x2="16.65" y2="16.65" />
      </svg>
    ),
  },
  {
    id: "events",
    label: "Events",
    icon: (a) => (
      <svg
        width="22"
        height="22"
        viewBox="0 0 24 24"
        fill="none"
        stroke={a ? "#7C5CFF" : "var(--muted)"}
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <rect x="3" y="4" width="18" height="18" rx="2" ry="2" />
        <line x1="16" y1="2" x2="16" y2="6" />
        <line x1="8" y1="2" x2="8" y2="6" />
        <line x1="3" y1="10" x2="21" y2="10" />
      </svg>
    ),
  },
  {
    id: "shop",
    label: "Shop",
    icon: (a) => (
      <svg
        width="22"
        height="22"
        viewBox="0 0 24 24"
        fill="none"
        stroke={a ? "#7C5CFF" : "var(--muted)"}
        strokeWidth="1.8"
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M6 2L3 6v14a2 2 0 002 2h14a2 2 0 002-2V6l-3-4z" />
        <line x1="3" y1="6" x2="21" y2="6" />
        <path d="M16 10a4 4 0 01-8 0" />
      </svg>
    ),
  },
]

export default function MainApp() {
  const [active, setActive] = useState<Tab>("home")
  const [menuOpen, setMenuOpen] = useState(false)
  const [studioOpen, setStudioOpen] = useState(false)
  const [settingsOpen, setSettingsOpen] = useState(false)
  const [chatOpen, setChatOpen] = useState(false)
  const [resource, setResource] = useState<ResourcePage | null>(null)

  return (
    <div
      className="flex flex-col flex-1 overflow-hidden"
      style={{ background: "var(--app-bg)", position: "relative" }}
    >
      <div className="flex-1 overflow-hidden">
        {active === "home" && <HomeTab onOpenMenu={() => setMenuOpen(true)} />}
        {active === "explore" && <ExploreTab />}
        {active === "events" && <EventsTab />}
        {active === "shop" && <ShopTab />}
        {active === "profile" && (
          <ProfileTab
            openSettings={settingsOpen}
            onSettingsOpened={() => setSettingsOpen(false)}
            onOpenResource={setResource}
          />
        )}
      </div>

      <div
        style={{
          display: "flex",
          background: "var(--surface)",
          borderTop: "1px solid var(--border)",
          paddingBottom: 8,
          paddingTop: 8,
          flexShrink: 0,
        }}
      >
        {tabs.slice(0, 2).map((t) => (
          <button
            key={t.id}
            onClick={() => setActive(t.id)}
            style={{
              flex: 1,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 3,
              background: "none",
              border: "none",
              cursor: "pointer",
              padding: "6px 0",
            }}
          >
            {t.icon(active === t.id)}
            <span
              style={{
                fontSize: 10,
                fontFamily: "Inter",
                color: active === t.id ? "#7C5CFF" : "var(--muted)",
                fontWeight: active === t.id ? 600 : 400,
              }}
            >
              {t.label}
            </span>
          </button>
        ))}
        <button
          onClick={() => setStudioOpen(true)}
          aria-label="Create"
          style={{
            flex: 1,
            display: "flex",
            flexDirection: "column",
            alignItems: "center",
            gap: 3,
            background: "none",
            border: "none",
            cursor: "pointer",
            padding: "6px 0",
          }}
        >
          <span
            style={{
              width: 40,
              height: 40,
              marginTop: -12,
              borderRadius: "50%",
              background: "linear-gradient(135deg, #8F72FF 0%, #7C5CFF 100%)",
              boxShadow: "0 8px 18px rgba(124,92,255,0.45)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <svg
              width="20"
              height="20"
              viewBox="0 0 24 24"
              fill="none"
              stroke="#FFFFFF"
              strokeWidth="2.6"
              strokeLinecap="round"
            >
              <line x1="12" y1="5" x2="12" y2="19" />
              <line x1="5" y1="12" x2="19" y2="12" />
            </svg>
          </span>
          <span
            style={{
              fontSize: 10,
              fontFamily: "Inter",
              color: "var(--muted)",
            }}
          >
            Create
          </span>
        </button>
        {tabs.slice(2).map((t) => (
          <button
            key={t.id}
            onClick={() => setActive(t.id)}
            style={{
              flex: 1,
              display: "flex",
              flexDirection: "column",
              alignItems: "center",
              gap: 3,
              background: "none",
              border: "none",
              cursor: "pointer",
              padding: "6px 0",
            }}
          >
            {t.icon(active === t.id)}
            <span
              style={{
                fontSize: 10,
                fontFamily: "Inter",
                color: active === t.id ? "#7C5CFF" : "var(--muted)",
                fontWeight: active === t.id ? 600 : 400,
              }}
            >
              {t.label}
            </span>
          </button>
        ))}
      </div>

      <button
        onClick={() => setChatOpen(true)}
        aria-label="Chat"
        style={{
          position: "absolute",
          right: 20,
          bottom: 88,
          width: 52,
          height: 52,
          borderRadius: "50%",
          background: "#7C5CFF",
          border: "none",
          cursor: "pointer",
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          boxShadow: "0 4px 20px rgba(124,92,255,0.4)",
          zIndex: 55,
        }}
      >
        <svg
          width="22"
          height="22"
          viewBox="0 0 24 24"
          fill="none"
          stroke="white"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
        >
          <path d="M21 15a2 2 0 01-2 2H7l-4 4V5a2 2 0 012-2h14a2 2 0 012 2z" />
        </svg>
      </button>

      {chatOpen && (
        <div
          style={{
            position: "absolute",
            top: 44,
            left: 10,
            right: 10,
            bottom: 14,
            zIndex: 60,
            borderRadius: 20,
            overflow: "hidden",
            background: "var(--app-bg)",
            border: "1px solid var(--border)",
            boxShadow: "0 20px 50px rgba(0,0,0,0.35)",
          }}
        >
          <AIChatSheet onClose={() => setChatOpen(false)} />
        </div>
      )}

      <SideDrawer
        open={menuOpen}
        onClose={() => setMenuOpen(false)}
        onNavigate={(t) => setActive(t)}
        onOpenResource={setResource}
        onOpenSettings={() => {
          setActive("profile")
          setSettingsOpen(true)
        }}
      />

      <CreatorStudio open={studioOpen} onClose={() => setStudioOpen(false)} />

      {resource && (
        <div
          style={{
            position: "absolute",
            inset: 0,
            zIndex: 58,
            background: "var(--app-bg)",
          }}
        >
          <ResourceScreen
            key={resource}
            initial={resource}
            onClose={() => setResource(null)}
          />
        </div>
      )}
    </div>
  )
}
