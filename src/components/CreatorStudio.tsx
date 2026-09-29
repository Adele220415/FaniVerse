import { useEffect, useRef, useState, type ReactNode } from "react"

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
  <svg width={size} height={size} viewBox="0 0 24 24" {...stroke}>
    {path}
  </svg>
)

type Mode = "menu" | "video" | "photo" | "upload" | "post" | "text"

type Media = {
  url: string
  name: string
  kind: string
}

type Poll = {
  choices: string[]
  days: number
  hours: number
  minutes: number
}

type PostView = "compose" | "schedule" | "disclosure"

const options: {
  id: Exclude<Mode, "menu">
  title: string
  desc: string
  color: string
  icon: ReactNode
}[] = [
  {
    id: "video",
    title: "Make a video",
    desc: "Record a clip or upload one, up to 3 min",
    color: "#FF6B5C",
    icon: icon(
      <>
        <rect x="2" y="5" width="14" height="14" rx="3" />
        <path d="M22 8.5l-6 3.5 6 3.5v-7z" />
      </>,
      26,
    ),
  },
  {
    id: "photo",
    title: "Take a photo",
    desc: "Open the camera and add a filter",
    color: "#F5A623",
    icon: icon(
      <>
        <path d="M3 8a2 2 0 012-2h2l1.5-2h7L17 6h2a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
        <circle cx="12" cy="12.5" r="3.5" />
      </>,
      26,
    ),
  },
  {
    id: "upload",
    title: "Upload",
    desc: "Images, video or audio from your device",
    color: "#7C5CFF",
    icon: icon(
      <>
        <path d="M12 16V4" />
        <path d="M7 9l5-5 5 5" />
        <path d="M4 16v3a2 2 0 002 2h12a2 2 0 002-2v-3" />
      </>,
      24,
    ),
  },
  {
    id: "text",
    title: "Text",
    desc: "Write a note or a styled quote card",
    color: "#2FBF71",
    icon: icon(
      <>
        <path d="M4 7V5a1 1 0 011-1h14a1 1 0 011 1v2" />
        <path d="M12 4v16" />
        <path d="M9 20h6" />
      </>,
      24,
    ),
  },
]

const filters = [
  { label: "Original", css: "none" },
  { label: "Vivid", css: "saturate(1.6) contrast(1.1)" },
  { label: "Warm", css: "sepia(0.35) saturate(1.4)" },
  { label: "Mono", css: "grayscale(1)" },
  { label: "Noir", css: "grayscale(1) contrast(1.45) brightness(0.9)" },
]

const textStyles = [
  { id: "violet", bg: "linear-gradient(135deg,#8F72FF,#4A2FD0)", fg: "#fff" },
  { id: "sunset", bg: "linear-gradient(135deg,#FF6B5C,#F5A623)", fg: "#fff" },
  { id: "mint", bg: "linear-gradient(135deg,#2FBF71,#1D9BF0)", fg: "#fff" },
  {
    id: "ink",
    bg: "linear-gradient(135deg,var(--surface),var(--border))",
    fg: "var(--text)",
  },
]

const audiences = ["Everyone", "Followers", "Fandom only"]

const BLUE = "#1D9BF0"

const fmtDate = (iso: string) => {
  const d = new Date(`${iso}T00:00:00`)
  if (Number.isNaN(d.getTime())) return iso
  return d.toLocaleDateString("en-US", {
    weekday: "short",
    month: "short",
    day: "numeric",
    year: "numeric",
  })
}

const fmtTime = (t: string) => {
  const [h, m] = t.split(":").map(Number)
  if (Number.isNaN(h)) return t
  const suffix = h >= 12 ? "PM" : "AM"
  const hr = h % 12 === 0 ? 12 : h % 12
  return `${hr}:${String(m || 0).padStart(2, "0")} ${suffix}`
}

const fieldStyle: React.CSSProperties = {
  width: "100%",
  background: "var(--surface)",
  border: "1.5px solid var(--border)",
  borderRadius: 10,
  padding: "9px 14px 11px",
  boxSizing: "border-box",
}

const fieldInput: React.CSSProperties = {
  width: "100%",
  background: "transparent",
  border: "none",
  outline: "none",
  padding: 0,
  color: "var(--text)",
  fontSize: 17,
  fontFamily: "Inter, sans-serif",
  colorScheme: "dark",
}

const sheetRow: React.CSSProperties = {
  display: "flex",
  alignItems: "center",
  gap: 14,
  width: "100%",
  padding: "14px 4px",
  background: "none",
  border: "none",
  color: "var(--text)",
  fontFamily: "Inter, sans-serif",
  fontSize: 16.5,
  fontWeight: 600,
  cursor: "pointer",
  textAlign: "left",
}

function Switch({
  on,
  onToggle,
  label,
}: {
  on: boolean
  onToggle: () => void
  label: string
}) {
  return (
    <button
      role="switch"
      aria-checked={on}
      aria-label={label}
      onClick={onToggle}
      style={{
        width: 48,
        height: 28,
        padding: 0,
        borderRadius: 50,
        border: "none",
        background: on ? BLUE : "var(--border-strong)",
        position: "relative",
        cursor: "pointer",
        flexShrink: 0,
      }}
    >
      <span
        style={{
          position: "absolute",
          top: 3,
          left: on ? 23 : 3,
          width: 22,
          height: 22,
          borderRadius: "50%",
          background: "#fff",
        }}
      />
    </button>
  )
}

function DisclosureRow({
  title,
  desc,
  link,
  on,
  onToggle,
}: {
  title: string
  desc: string
  link?: string
  on: boolean
  onToggle: () => void
}) {
  return (
    <div>
      <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
        <span
          style={{
            flex: 1,
            fontFamily: "Inter, sans-serif",
            fontSize: 17,
            fontWeight: 500,
            color: "var(--text)",
          }}
        >
          {title}
        </span>
        <Switch on={on} onToggle={onToggle} label={title} />
      </div>
      <div
        style={{
          marginTop: 10,
          maxWidth: 300,
          fontFamily: "Inter, sans-serif",
          fontSize: 14,
          lineHeight: 1.5,
          color: "var(--muted)",
        }}
      >
        {desc}
        {link && (
          <div style={{ marginTop: 6, color: BLUE, fontWeight: 600 }}>
            {link}
          </div>
        )}
      </div>
    </div>
  )
}

type StudioHeaderProps = {
  title: string
  onBack: () => void
}

function StudioHeader({ title, onBack }: StudioHeaderProps) {
  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        gap: 14,
        padding: "16px 18px",
        borderBottom: "1px solid var(--border)",
        flexShrink: 0,
      }}
    >
      <button
        onClick={onBack}
        aria-label="Back"
        style={{
          background: "var(--surface)",
          border: "1px solid var(--border)",
          borderRadius: 10,
          width: 36,
          height: 36,
          display: "flex",
          alignItems: "center",
          justifyContent: "center",
          cursor: "pointer",
          color: "var(--text)",
        }}
      >
        {icon(<path d="M19 12H5M12 5l-7 7 7 7" />, 18)}
      </button>
      <h2
        style={{
          fontFamily: "Space Grotesk, sans-serif",
          fontSize: 18,
          fontWeight: 700,
          color: "var(--text)",
          margin: 0,
        }}
      >
        {title}
      </h2>
    </div>
  )
}

function Label({ children }: { children: ReactNode }) {
  return (
    <div
      style={{
        fontSize: 12.5,
        fontWeight: 600,
        color: "var(--muted)",
        fontFamily: "Inter, sans-serif",
        textTransform: "uppercase",
        letterSpacing: "0.04em",
        marginBottom: 8,
      }}
    >
      {children}
    </div>
  )
}

function PrimaryButton({
  children,
  onClick,
  disabled,
}: {
  children: ReactNode
  onClick: () => void
  disabled?: boolean
}) {
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      style={{
        width: "100%",
        height: 48,
        borderRadius: 12,
        border: "none",
        background: disabled ? "var(--border)" : "#7C5CFF",
        color: disabled ? "var(--muted)" : "#fff",
        fontFamily: "Space Grotesk, sans-serif",
        fontSize: 16,
        fontWeight: 600,
        cursor: disabled ? "default" : "pointer",
      }}
    >
      {children}
    </button>
  )
}

export default function CreatorStudio({
  open,
  onClose,
}: {
  open: boolean
  onClose: () => void
}) {
  const [mode, setMode] = useState<Mode>("menu")
  const [media, setMedia] = useState<Media[]>([])
  const [caption, setCaption] = useState("")
  const [body, setBody] = useState("")
  const [filter, setFilter] = useState(filters[0])
  const [textStyle, setTextStyle] = useState(textStyles[0])
  const [audience, setAudience] = useState(0)
  const [toast, setToast] = useState<string | null>(null)
  const [resetOnDone, setResetOnDone] = useState(true)
  const [postView, setPostView] = useState<PostView>("compose")
  const [sheet, setSheet] = useState(false)
  const [poll, setPoll] = useState<Poll | null>(null)
  const [place, setPlace] = useState<string | null>(null)
  const [date, setDate] = useState("2026-09-28")
  const [time, setTime] = useState("12:25")
  const [paid, setPaid] = useState(false)
  const [withAi, setWithAi] = useState(false)

  const cameraInput = useRef<HTMLInputElement>(null)
  const galleryInput = useRef<HTMLInputElement>(null)
  const videoInput = useRef<HTMLInputElement>(null)
  const fileInput = useRef<HTMLInputElement>(null)

  useEffect(() => {
    if (!open) return
    setMode("menu")
    setMedia([])
    setCaption("")
    setBody("")
    setFilter(filters[0])
    setTextStyle(textStyles[0])
    setAudience(0)
    setToast(null)
    setPostView("compose")
    setSheet(false)
    setPoll(null)
    setPlace(null)
    setPaid(false)
    setWithAi(false)
  }, [open])

  useEffect(() => {
    if (!toast) return
    const reset = resetOnDone
    const t = setTimeout(() => {
      setToast(null)
      if (!reset) return
      setMode("menu")
      setMedia([])
      setCaption("")
      setBody("")
      setPostView("compose")
      setSheet(false)
      setPoll(null)
      setPlace(null)
    }, 1500)
    return () => clearTimeout(t)
  }, [toast, resetOnDone])

  if (!open) return null

  const addFiles = (files: FileList | null) => {
    if (!files) return
    const next: Media[] = Array.from(files).map((f) => ({
      url: URL.createObjectURL(f),
      name: f.name,
      kind: f.type.startsWith("video")
        ? "video"
        : f.type.startsWith("audio")
          ? "audio"
          : "image",
    }))
    setMedia((m) => [...m, ...next])
  }

  const publish = (label: string) => {
    setResetOnDone(true)
    setToast(`${label} — it's live in your studio feed.`)
  }

  const note = (label: string) => {
    setResetOnDone(false)
    setToast(label)
  }

  const tool = (
    path: ReactNode,
    label: string,
    onClick: () => void,
    color = "var(--muted)",
  ) => (
    <button
      key={label}
      aria-label={label}
      title={label}
      onClick={onClick}
      style={{
        background: "none",
        border: "none",
        color,
        cursor: "pointer",
        display: "flex",
        padding: 7,
      }}
    >
      {icon(path, 20)}
    </button>
  )

  const togglePoll = () =>
    setPoll((p) =>
      p ? null : { choices: ["", ""], days: 1, hours: 0, minutes: 0 },
    )

  const setChoice = (i: number, value: string) =>
    setPoll((p) =>
      p
        ? { ...p, choices: p.choices.map((c, idx) => (idx === i ? value : c)) }
        : p,
    )

  const setLength = (key: "days" | "hours" | "minutes", value: number) =>
    setPoll((p) => (p ? { ...p, [key]: value } as Poll : p))

  const filePicker = (
    ref: React.RefObject<HTMLInputElement | null>,
    accept: string,
    capture?: boolean | "user" | "environment",
  ) => (
    <input
      ref={ref}
      type="file"
      accept={accept}
      capture={capture}
      multiple={accept !== "video/*" && !capture}
      style={{ display: "none" }}
      onChange={(e) => {
        addFiles(e.target.files)
        e.target.value = ""
      }}
    />
  )

  return (
    <div
      style={{
        position: "absolute",
        inset: 0,
        zIndex: 60,
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      {filePicker(cameraInput, "image/*", "environment")}
      {filePicker(galleryInput, "image/*")}
      {filePicker(videoInput, "video/*")}
      {filePicker(fileInput, "image/*,video/*,audio/*")}

      {mode === "menu" && (
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 14,
            padding: "18px 20px 14px",
            flexShrink: 0,
          }}
        >
          <button
            onClick={onClose}
            aria-label="Close"
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 10,
              width: 36,
              height: 36,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: "pointer",
              color: "var(--text)",
              flexShrink: 0,
            }}
          >
            {icon(<path d="M19 12H5M12 5l-7 7 7 7" />, 18)}
          </button>
          <div>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 22,
                fontWeight: 700,
                color: "var(--text)",
                letterSpacing: "-0.01em",
              }}
            >
              Creator Studio
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13.5,
                color: "var(--muted)",
                marginTop: 2,
              }}
            >
              What do you want to make today?
            </div>
          </div>
        </div>
      )}

      {mode === "menu" && (
        <div
          style={{
            flex: 1,
            overflowY: "auto",
            padding: "4px 20px 28px",
            display: "flex",
            flexDirection: "column",
            gap: 12,
          }}
        >
          <div
            style={{
              display: "grid",
              gridTemplateColumns: "1fr 1fr",
              gap: 12,
            }}
          >
            {options.map((o) => (
              <button
                key={o.id}
                onClick={() => setMode(o.id)}
                aria-label={o.title}
                title={o.title}
                style={{
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  padding: 24,
                  borderRadius: 16,
                  border: "1px solid var(--border)",
                  background: "var(--surface)",
                  cursor: "pointer",
                  minHeight: 120,
                }}
              >
                <span
                  style={{
                    width: 48,
                    height: 48,
                    borderRadius: 14,
                    background: `${o.color}22`,
                    border: `1px solid ${o.color}55`,
                    color: o.color,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  {o.icon}
                </span>
              </button>
            ))}
          </div>

          <div
            style={{
              marginTop: 6,
              padding: 16,
              borderRadius: 16,
              border: "1px dashed var(--border)",
              display: "flex",
              alignItems: "center",
              gap: 12,
            }}
          >
            <img
              src={u(ME, 80, 80)}
              alt="Alex Kim"
              style={{
                width: 40,
                height: 40,
                borderRadius: "50%",
                objectFit: "cover",
                flexShrink: 0,
              }}
            />
            <div style={{ minWidth: 0 }}>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13.5,
                  color: "var(--text)",
                  fontWeight: 600,
                }}
              >
                Drafts
              </div>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 12.5,
                  color: "var(--muted)",
                  marginTop: 2,
                }}
              >
                Nothing saved yet — start something new.
              </div>
            </div>
          </div>
        </div>
      )}

      {mode === "video" && (
        <>
          <StudioHeader title="Make a video" onBack={() => setMode("menu")} />
          <div
            style={{
              flex: 1,
              overflowY: "auto",
              padding: "18px 20px",
              display: "flex",
              flexDirection: "column",
              gap: 16,
            }}
          >
            {media.length === 0 ? (
              <div
                style={{
                  border: "1.5px dashed var(--border)",
                  borderRadius: 18,
                  padding: "40px 24px",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: 14,
                  textAlign: "center",
                }}
              >
                <div
                  style={{
                    width: 72,
                    height: 72,
                    borderRadius: "50%",
                    background: "rgba(255,107,92,0.15)",
                    border: "1px solid rgba(255,107,92,0.4)",
                    color: "#FF6B5C",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  {icon(
                    <>
                      <rect x="2" y="5" width="14" height="14" rx="3" />
                      <path d="M22 8.5l-6 3.5 6 3.5v-7z" />
                    </>,
                    30,
                  )}
                </div>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 17,
                    fontWeight: 700,
                    color: "var(--text)",
                  }}
                >
                  Shoot or pick a clip
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 13.5,
                    color: "var(--muted)",
                    maxWidth: 240,
                    lineHeight: 1.5,
                  }}
                >
                  Up to 3 minutes, 1080p. You can trim it before posting.
                </div>
                <div
                  style={{
                    display: "flex",
                    gap: 10,
                    width: "100%",
                    marginTop: 4,
                  }}
                >
                  <button
                    onClick={() => videoInput.current?.click()}
                    style={{
                      flex: 1,
                      height: 46,
                      borderRadius: 12,
                      border: "none",
                      background: "#FF6B5C",
                      color: "#fff",
                      fontFamily: "Space Grotesk, sans-serif",
                      fontWeight: 600,
                      fontSize: 15,
                      cursor: "pointer",
                    }}
                  >
                    Record video
                  </button>
                  <button
                    onClick={() => videoInput.current?.click()}
                    style={{
                      flex: 1,
                      height: 46,
                      borderRadius: 12,
                      border: "1px solid var(--border-strong)",
                      background: "transparent",
                      color: "var(--text)",
                      fontFamily: "Inter, sans-serif",
                      fontWeight: 500,
                      fontSize: 15,
                      cursor: "pointer",
                    }}
                  >
                    Gallery
                  </button>
                </div>
              </div>
            ) : (
              <>
                <video
                  src={media[0].url}
                  controls
                  style={{
                    width: "100%",
                    borderRadius: 16,
                    border: "1px solid var(--border)",
                    background: "#000",
                    maxHeight: 320,
                  }}
                />
                <div>
                  <Label>Caption</Label>
                  <textarea
                    value={caption}
                    onChange={(e) => setCaption(e.target.value)}
                    rows={3}
                    placeholder="Say something about this clip…"
                    style={{
                      width: "100%",
                      background: "var(--surface)",
                      border: "1.5px solid var(--border)",
                      borderRadius: 12,
                      padding: "12px 14px",
                      color: "var(--text)",
                      fontSize: 15,
                      fontFamily: "Inter, sans-serif",
                      outline: "none",
                      resize: "none",
                      boxSizing: "border-box",
                    }}
                    onFocus={(e) => (e.target.style.borderColor = "#7C5CFF")}
                    onBlur={(e) =>
                      (e.target.style.borderColor = "var(--border)")
                    }
                  />
                </div>
                <button
                  onClick={() => setMedia([])}
                  style={{
                    background: "none",
                    border: "none",
                    color: "#FF6B5C",
                    fontFamily: "Inter, sans-serif",
                    fontSize: 14,
                    cursor: "pointer",
                    padding: 0,
                  }}
                >
                  Remove clip
                </button>
              </>
            )}
          </div>
          <div
            style={{
              padding: "14px 20px 22px",
              borderTop: "1px solid var(--border)",
            }}
          >
            <PrimaryButton
              disabled={media.length === 0}
              onClick={() => publish("Video posted")}
            >
              Post video
            </PrimaryButton>
          </div>
        </>
      )}

      {mode === "photo" && (
        <>
          <StudioHeader title="Take a photo" onBack={() => setMode("menu")} />
          <div
            style={{
              flex: 1,
              overflowY: "auto",
              padding: "18px 20px",
              display: "flex",
              flexDirection: "column",
              gap: 16,
            }}
          >
            {media.length === 0 ? (
              <div
                style={{
                  border: "1.5px dashed var(--border)",
                  borderRadius: 18,
                  padding: "40px 24px",
                  display: "flex",
                  flexDirection: "column",
                  alignItems: "center",
                  gap: 14,
                  textAlign: "center",
                }}
              >
                <div
                  style={{
                    width: 72,
                    height: 72,
                    borderRadius: "50%",
                    background: "rgba(245,166,35,0.15)",
                    border: "1px solid rgba(245,166,35,0.4)",
                    color: "#F5A623",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                  }}
                >
                  {icon(
                    <>
                      <path d="M3 8a2 2 0 012-2h2l1.5-2h7L17 6h2a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2z" />
                      <circle cx="12" cy="12.5" r="3.5" />
                    </>,
                    30,
                  )}
                </div>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 17,
                    fontWeight: 700,
                    color: "var(--text)",
                  }}
                >
                  Camera ready
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 13.5,
                    color: "var(--muted)",
                    maxWidth: 240,
                    lineHeight: 1.5,
                  }}
                >
                  Snap a new photo or pick one from your gallery.
                </div>
                <div
                  style={{
                    display: "flex",
                    gap: 10,
                    width: "100%",
                    marginTop: 4,
                  }}
                >
                  <button
                    onClick={() => cameraInput.current?.click()}
                    style={{
                      flex: 1,
                      height: 46,
                      borderRadius: 12,
                      border: "none",
                      background: "#F5A623",
                      color: "#17110a",
                      fontFamily: "Space Grotesk, sans-serif",
                      fontWeight: 700,
                      fontSize: 15,
                      cursor: "pointer",
                    }}
                  >
                    Open camera
                  </button>
                  <button
                    onClick={() => galleryInput.current?.click()}
                    style={{
                      flex: 1,
                      height: 46,
                      borderRadius: 12,
                      border: "1px solid var(--border-strong)",
                      background: "transparent",
                      color: "var(--text)",
                      fontFamily: "Inter, sans-serif",
                      fontWeight: 500,
                      fontSize: 15,
                      cursor: "pointer",
                    }}
                  >
                    Gallery
                  </button>
                </div>
              </div>
            ) : (
              <>
                <img
                  src={media[0].url}
                  alt="Preview"
                  style={{
                    width: "100%",
                    height: 300,
                    objectFit: "cover",
                    borderRadius: 16,
                    border: "1px solid var(--border)",
                    filter: filter.css,
                  }}
                />
                <div>
                  <Label>Filter</Label>
                  <div style={{ display: "flex", gap: 8, flexWrap: "wrap" }}>
                    {filters.map((f) => (
                      <button
                        key={f.label}
                        onClick={() => setFilter(f)}
                        style={{
                          padding: "7px 14px",
                          borderRadius: 50,
                          border: `1.5px solid ${
                            filter.label === f.label
                              ? "#7C5CFF"
                              : "var(--border)"
                          }`,
                          background:
                            filter.label === f.label
                              ? "rgba(124,92,255,0.15)"
                              : "var(--surface)",
                          color:
                            filter.label === f.label
                              ? "#7C5CFF"
                              : "var(--muted)",
                          fontSize: 13,
                          fontFamily: "Inter, sans-serif",
                          cursor: "pointer",
                        }}
                      >
                        {f.label}
                      </button>
                    ))}
                  </div>
                </div>
                <div>
                  <Label>Caption</Label>
                  <textarea
                    value={caption}
                    onChange={(e) => setCaption(e.target.value)}
                    rows={3}
                    placeholder="Add a caption…"
                    style={{
                      width: "100%",
                      background: "var(--surface)",
                      border: "1.5px solid var(--border)",
                      borderRadius: 12,
                      padding: "12px 14px",
                      color: "var(--text)",
                      fontSize: 15,
                      fontFamily: "Inter, sans-serif",
                      outline: "none",
                      resize: "none",
                      boxSizing: "border-box",
                    }}
                    onFocus={(e) => (e.target.style.borderColor = "#7C5CFF")}
                    onBlur={(e) =>
                      (e.target.style.borderColor = "var(--border)")
                    }
                  />
                </div>
                <button
                  onClick={() => setMedia([])}
                  style={{
                    background: "none",
                    border: "none",
                    color: "#FF6B5C",
                    fontFamily: "Inter, sans-serif",
                    fontSize: 14,
                    cursor: "pointer",
                    padding: 0,
                  }}
                >
                  Retake
                </button>
              </>
            )}
          </div>
          <div
            style={{
              padding: "14px 20px 22px",
              borderTop: "1px solid var(--border)",
            }}
          >
            <PrimaryButton
              disabled={media.length === 0}
              onClick={() => publish("Photo posted")}
            >
              Post photo
            </PrimaryButton>
          </div>
        </>
      )}

      {mode === "upload" && (
        <>
          <StudioHeader title="Upload" onBack={() => setMode("menu")} />
          <div
            style={{
              flex: 1,
              overflowY: "auto",
              padding: "18px 20px",
              display: "flex",
              flexDirection: "column",
              gap: 16,
            }}
          >
            <button
              onClick={() => fileInput.current?.click()}
              style={{
                border: "1.5px dashed var(--border-strong)",
                borderRadius: 18,
                padding: "34px 24px",
                background: "var(--surface)",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 12,
                cursor: "pointer",
              }}
            >
              <span
                style={{
                  width: 56,
                  height: 56,
                  borderRadius: "50%",
                  background: "rgba(124,92,255,0.15)",
                  border: "1px solid rgba(124,92,255,0.45)",
                  color: "#7C5CFF",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                {icon(
                  <>
                    <path d="M12 16V4" />
                    <path d="M7 9l5-5 5 5" />
                    <path d="M4 16v3a2 2 0 002 2h12a2 2 0 002-2v-3" />
                  </>,
                  26,
                )}
              </span>
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 16,
                  fontWeight: 700,
                  color: "var(--text)",
                }}
              >
                Choose files
              </span>
              <span
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 12.5,
                  color: "var(--muted)",
                }}
              >
                Images, video or audio · up to 500 MB each
              </span>
            </button>

            {media.length > 0 && (
              <div
                style={{ display: "flex", flexDirection: "column", gap: 10 }}
              >
                <Label>
                  {media.length} file{media.length > 1 ? "s" : ""} ready
                </Label>
                {media.map((m, i) => (
                  <div
                    key={`${m.url}-${i}`}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: 12,
                      padding: 12,
                      borderRadius: 14,
                      background: "var(--surface)",
                      border: "1px solid var(--border)",
                    }}
                  >
                    {m.kind === "image" ? (
                      <img
                        src={m.url}
                        alt=""
                        style={{
                          width: 46,
                          height: 46,
                          borderRadius: 10,
                          objectFit: "cover",
                          flexShrink: 0,
                        }}
                      />
                    ) : (
                      <span
                        style={{
                          width: 46,
                          height: 46,
                          borderRadius: 10,
                          background: "rgba(124,92,255,0.15)",
                          color: "#7C5CFF",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          flexShrink: 0,
                        }}
                      >
                        {icon(
                          m.kind === "video" ? (
                            <polygon points="6 4 20 12 6 20 6 4" />
                          ) : (
                            <>
                              <path d="M9 18V5l12-2v13" />
                              <circle cx="6" cy="18" r="3" />
                              <circle cx="18" cy="16" r="3" />
                            </>
                          ),
                          20,
                        )}
                      </span>
                    )}
                    <span
                      style={{
                        flex: 1,
                        minWidth: 0,
                        fontFamily: "Inter, sans-serif",
                        fontSize: 14,
                        color: "var(--text)",
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                        whiteSpace: "nowrap",
                      }}
                    >
                      {m.name}
                    </span>
                    <button
                      aria-label="Remove file"
                      onClick={() =>
                        setMedia((list) => list.filter((x) => x.url !== m.url))
                      }
                      style={{
                        background: "none",
                        border: "none",
                        color: "var(--muted)",
                        cursor: "pointer",
                        display: "flex",
                        padding: 4,
                      }}
                    >
                      {icon(
                        <>
                          <line x1="18" y1="6" x2="6" y2="18" />
                          <line x1="6" y1="6" x2="18" y2="18" />
                        </>,
                        15,
                      )}
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
          <div
            style={{
              padding: "14px 20px 22px",
              borderTop: "1px solid var(--border)",
            }}
          >
            <PrimaryButton
              disabled={media.length === 0}
              onClick={() => publish("Upload published")}
            >
              Publish upload
            </PrimaryButton>
          </div>
        </>
      )}

      {mode === "post" && postView === "compose" && (
        <>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 14,
              padding: "14px 18px",
              borderBottom: "1px solid var(--border)",
              flexShrink: 0,
            }}
          >
            <button
              onClick={() => setMode("menu")}
              aria-label="Back"
              style={{
                background: "none",
                border: "none",
                color: "var(--text)",
                cursor: "pointer",
                display: "flex",
                padding: 0,
              }}
            >
              {icon(<path d="M19 12H5M12 5l-7 7 7 7" />, 20)}
            </button>
            <div
              style={{
                marginLeft: "auto",
                display: "flex",
                alignItems: "center",
                gap: 18,
              }}
            >
              <button
                onClick={() => note("Draft saved.")}
                style={{
                  background: "none",
                  border: "none",
                  padding: 0,
                  color: BLUE,
                  fontFamily: "Inter, sans-serif",
                  fontSize: 15,
                  fontWeight: 600,
                  cursor: "pointer",
                }}
              >
                Drafts
              </button>
              <button
                disabled={body.trim().length === 0}
                onClick={() => publish("Post published")}
                style={{
                  height: 36,
                  padding: "0 20px",
                  borderRadius: 50,
                  border: "none",
                  background: body.trim().length === 0 ? "#1D9BF066" : BLUE,
                  color: "#fff",
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 15,
                  fontWeight: 700,
                  cursor: body.trim().length === 0 ? "default" : "pointer",
                }}
              >
                Post
              </button>
            </div>
          </div>
          <div
            style={{
              flex: 1,
              overflowY: "auto",
              padding: "18px 20px",
              display: "flex",
              flexDirection: "column",
              gap: 16,
            }}
          >
            <div style={{ display: "flex", gap: 12 }}>
              <img
                src={u(ME, 96, 96)}
                alt="Alex Kim"
                style={{
                  width: 44,
                  height: 44,
                  borderRadius: "50%",
                  objectFit: "cover",
                  flexShrink: 0,
                }}
              />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 15,
                    fontWeight: 700,
                    color: "var(--text)",
                    marginBottom: 8,
                  }}
                >
                  Alex Kim{" "}
                  <span style={{ color: "var(--muted)", fontWeight: 400 }}>
                    @alexkim
                  </span>
                </div>
                <textarea
                  value={body}
                  onChange={(e) => setBody(e.target.value.slice(0, 280))}
                  rows={6}
                  placeholder="What's happening?"
                  autoFocus
                  style={{
                    width: "100%",
                    background: "transparent",
                    border: "none",
                    color: "var(--text)",
                    fontSize: 17,
                    lineHeight: 1.5,
                    fontFamily: "Inter, sans-serif",
                    outline: "none",
                    resize: "none",
                    boxSizing: "border-box",
                  }}
                />
              </div>
            </div>

            {media.map((m, i) => (
              <div key={`${m.url}-${i}`} style={{ position: "relative" }}>
                <img
                  src={m.url}
                  alt=""
                  style={{
                    width: "100%",
                    height: 200,
                    objectFit: "cover",
                    borderRadius: 14,
                    border: "1px solid var(--border)",
                  }}
                />
                <button
                  aria-label="Remove image"
                  onClick={() =>
                    setMedia((list) => list.filter((x) => x.url !== m.url))
                  }
                  style={{
                    position: "absolute",
                    top: 8,
                    right: 8,
                    width: 28,
                    height: 28,
                    borderRadius: "50%",
                    background: "rgba(0,0,0,0.65)",
                    border: "none",
                    color: "#fff",
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor: "pointer",
                  }}
                >
                  {icon(
                    <>
                      <line x1="18" y1="6" x2="6" y2="18" />
                      <line x1="6" y1="6" x2="18" y2="18" />
                    </>,
                    14,
                  )}
                </button>
              </div>
            ))}

            {poll && (
              <div
                style={{
                  border: "1px solid var(--border)",
                  borderRadius: 16,
                  overflow: "hidden",
                }}
              >
                <div
                  style={{
                    padding: 14,
                    display: "flex",
                    flexDirection: "column",
                    gap: 10,
                  }}
                >
                  {poll.choices.map((c, i) => (
                    <div key={i} style={{ display: "flex", gap: 10 }}>
                      <div
                        style={{
                          width: 58,
                          height: 58,
                          borderRadius: 10,
                          border: "1.5px dashed var(--border-strong)",
                          display: "flex",
                          alignItems: "center",
                          justifyContent: "center",
                          color: "var(--muted)",
                          flexShrink: 0,
                        }}
                      >
                        {icon(
                          <>
                            <rect x="3" y="3" width="18" height="18" rx="4" />
                            <circle cx="8.5" cy="8.5" r="1.5" />
                            <path d="M21 15l-5-5L5 21" />
                          </>,
                          18,
                        )}
                      </div>
                      <div
                        style={{
                          flex: 1,
                          minWidth: 0,
                          position: "relative",
                          background: "var(--surface)",
                          border: "1.5px solid var(--border)",
                          borderRadius: 10,
                          padding: "10px 52px 10px 12px",
                          boxSizing: "border-box",
                        }}
                      >
                        <input
                          value={c}
                          maxLength={25}
                          placeholder={`Choice ${i + 1}`}
                          onChange={(e) => setChoice(i, e.target.value)}
                          style={{
                            width: "100%",
                            background: "transparent",
                            border: "none",
                            outline: "none",
                            padding: 0,
                            color: c ? BLUE : "var(--text)",
                            fontSize: 15,
                            fontFamily: "Inter, sans-serif",
                          }}
                        />
                        <span
                          style={{
                            position: "absolute",
                            right: 12,
                            top: 12,
                            fontSize: 12.5,
                            fontFamily: "Inter, sans-serif",
                            color: "var(--muted)",
                          }}
                        >
                          {c.length} / 25
                        </span>
                      </div>
                      {poll.choices.length > 2 && (
                        <button
                          aria-label="Remove choice"
                          onClick={() =>
                            setPoll({
                              ...poll,
                              choices: poll.choices.filter(
                                (_, idx) => idx !== i,
                              ),
                            })
                          }
                          style={{
                            background: "none",
                            border: "none",
                            color: "var(--muted)",
                            cursor: "pointer",
                            display: "flex",
                            padding: 0,
                          }}
                        >
                          {icon(
                            <>
                              <line x1="18" y1="6" x2="6" y2="18" />
                              <line x1="6" y1="6" x2="18" y2="18" />
                            </>,
                            16,
                          )}
                        </button>
                      )}
                    </div>
                  ))}
                  {poll.choices.length < 4 && (
                    <button
                      onClick={() =>
                        setPoll({ ...poll, choices: [...poll.choices, ""] })
                      }
                      style={{
                        background: "none",
                        border: "none",
                        padding: 0,
                        display: "flex",
                        alignItems: "center",
                        gap: 7,
                        color: BLUE,
                        fontFamily: "Inter, sans-serif",
                        fontSize: 14,
                        fontWeight: 600,
                        cursor: "pointer",
                      }}
                    >
                      {icon(
                        <>
                          <line x1="12" y1="5" x2="12" y2="19" />
                          <line x1="5" y1="12" x2="19" y2="12" />
                        </>,
                        16,
                      )}
                      Add choice
                    </button>
                  )}
                </div>

                <div
                  style={{
                    padding: "12px 14px 14px",
                    borderTop: "1px solid var(--border)",
                  }}
                >
                  <div
                    style={{
                      marginBottom: 10,
                      fontFamily: "Inter, sans-serif",
                      fontSize: 14.5,
                      fontWeight: 600,
                      color: "var(--text)",
                    }}
                  >
                    Poll length
                  </div>
                  <div style={{ display: "flex", gap: 10 }}>
                    {([
                      ["Days", "days"],
                      ["Hours", "hours"],
                      ["Minutes", "minutes"],
                    ] as const).map(([label, key]) => (
                      <div
                        key={key}
                        style={{
                          flex: 1,
                          position: "relative",
                          border: "1px solid var(--border-strong)",
                          borderRadius: 10,
                          padding: "7px 30px 8px 10px",
                          boxSizing: "border-box",
                        }}
                      >
                        <div
                          style={{
                            fontSize: 11.5,
                            fontFamily: "Inter, sans-serif",
                            color: "var(--muted)",
                          }}
                        >
                          {label}
                        </div>
                        <input
                          type="number"
                          min={0}
                          value={poll[key]}
                          onChange={(e) =>
                            setLength(key, Math.max(0, Number(e.target.value)))
                          }
                          style={{
                            width: "100%",
                            background: "transparent",
                            border: "none",
                            outline: "none",
                            padding: 0,
                            color: "var(--text)",
                            fontSize: 17,
                            fontFamily: "Inter, sans-serif",
                          }}
                        />
                        <span
                          style={{
                            position: "absolute",
                            right: 8,
                            top: 13,
                            color: "var(--muted)",
                            display: "flex",
                          }}
                        >
                          {icon(<path d="M6 9l6 6 6-6" />, 16)}
                        </span>
                      </div>
                    ))}
                  </div>
                </div>

                <button
                  onClick={() => setPoll(null)}
                  style={{
                    width: "100%",
                    padding: 14,
                    background: "var(--app-bg)",
                    border: "none",
                    borderTop: "1px solid var(--border)",
                    color: "#FF6B5C",
                    fontFamily: "Inter, sans-serif",
                    fontSize: 15,
                    fontWeight: 600,
                    cursor: "pointer",
                  }}
                >
                  Remove poll
                </button>
              </div>
            )}

            {place && (
              <button
                onClick={() => setPlace(null)}
                style={{
                  alignSelf: "flex-start",
                  display: "flex",
                  alignItems: "center",
                  gap: 7,
                  padding: "7px 13px",
                  borderRadius: 50,
                  border: "1px solid var(--border)",
                  background: "var(--surface)",
                  color: BLUE,
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13,
                  fontWeight: 500,
                  cursor: "pointer",
                }}
              >
                {icon(
                  <>
                    <path d="M12 21s7-5.6 7-11a7 7 0 10-14 0c0 5.4 7 11 7 11z" />
                    <circle cx="12" cy="10" r="2.5" />
                  </>,
                  14,
                )}
                {place}
              </button>
            )}

            <div style={{ flex: 1, minHeight: 12 }} />

            <button
              onClick={() => setAudience((a) => (a + 1) % audiences.length)}
              style={{
                display: "flex",
                alignItems: "center",
                gap: 8,
                background: "none",
                border: "none",
                padding: 0,
                color: BLUE,
                fontFamily: "Inter, sans-serif",
                fontSize: 14.5,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              {icon(
                <>
                  <circle cx="12" cy="12" r="9" />
                  <path d="M3 12h18M12 3a15 15 0 010 18M12 3a15 15 0 000 18" />
                </>,
                16,
              )}
              {audiences[audience]} can reply
            </button>

            <div
              style={{
                borderTop: "1px solid var(--border)",
                paddingTop: 8,
                display: "flex",
                alignItems: "center",
                gap: 2,
              }}
            >
              {tool(
                <>
                  <rect x="3" y="3" width="18" height="18" rx="4" />
                  <circle cx="8.5" cy="8.5" r="1.5" />
                  <path d="M21 15l-5-5L5 21" />
                </>,
                "Media",
                () => setSheet(true),
              )}
              {tool(
                <>
                  <rect x="3" y="6" width="18" height="12" rx="3" />
                  <text
                    x="12"
                    y="15.5"
                    fontSize="8"
                    textAnchor="middle"
                    fill="currentColor"
                    stroke="none"
                    fontFamily="Inter, sans-serif"
                    fontWeight="700"
                  >
                    GIF
                  </text>
                </>,
                "GIF",
                () => note("GIF library is coming soon."),
              )}
              {tool(
                <>
                  <path d="M5 7v10M9.5 7v6M14 7v8M18.5 7v4" />
                </>,
                "Poll",
                togglePoll,
                poll ? BLUE : "var(--muted)",
              )}
              {tool(
                <>
                  <circle cx="12" cy="12" r="9" />
                  <path d="M12 7v5l3.5 2" />
                </>,
                "Schedule",
                () => setPostView("schedule"),
              )}
              {tool(
                <>
                  <path d="M12 21s7-5.6 7-11a7 7 0 10-14 0c0 5.4 7 11 7 11z" />
                  <circle cx="12" cy="10" r="2.5" />
                </>,
                "Location",
                () => setPlace((p) => (p ? null : "Lagos, Nigeria")),
                place ? BLUE : "var(--muted)",
              )}
              {tool(
                <>
                  <path d="M12 3l7 3v5c0 4.5-3 8.3-7 10-4-1.7-7-5.5-7-10V6l7-3z" />
                </>,
                "Content disclosure",
                () => setPostView("disclosure"),
              )}
              <span
                style={{
                  marginLeft: "auto",
                  paddingRight: 4,
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13,
                  color: body.length > 250 ? "#FF6B5C" : "var(--muted)",
                }}
              >
                {280 - body.length}
              </span>
            </div>
          </div>
        </>
      )}

      {mode === "post" && postView === "schedule" && (
        <>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              gap: 14,
              padding: "16px 18px",
              borderBottom: "1px solid var(--border)",
              flexShrink: 0,
            }}
          >
            <button
              onClick={() => setPostView("compose")}
              aria-label="Back"
              style={{
                background: "none",
                border: "none",
                color: "var(--text)",
                cursor: "pointer",
                display: "flex",
                padding: 0,
              }}
            >
              {icon(<path d="M19 12H5M12 5l-7 7 7 7" />, 20)}
            </button>
            <h2
              style={{
                margin: 0,
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 18,
                fontWeight: 700,
                color: "var(--text)",
              }}
            >
              Schedule
            </h2>
            <button
              onClick={() => {
                setPostView("compose")
                note(`Scheduled for ${fmtDate(date)} at ${fmtTime(time)}`)
              }}
              style={{
                marginLeft: "auto",
                height: 36,
                padding: "0 18px",
                borderRadius: 50,
                border: "none",
                background: "var(--text)",
                color: "var(--app-bg)",
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 15,
                fontWeight: 700,
                cursor: "pointer",
              }}
            >
              Confirm
            </button>
          </div>

          <div
            style={{
              flex: 1,
              overflowY: "auto",
              padding: "18px 20px",
              display: "flex",
              flexDirection: "column",
              gap: 18,
            }}
          >
            <div
              style={{
                display: "flex",
                alignItems: "center",
                gap: 10,
                fontFamily: "Inter, sans-serif",
                fontSize: 14,
                color: "var(--muted)",
              }}
            >
              {icon(
                <>
                  <circle cx="12" cy="12" r="9" />
                  <path d="M12 7v5l3.5 2" />
                </>,
                18,
              )}
              Will send on {fmtDate(date)} at {fmtTime(time)}
            </div>

            <div>
              <Label>Date</Label>
              <div style={fieldStyle}>
                <div
                  style={{
                    fontSize: 12,
                    fontFamily: "Inter, sans-serif",
                    color: "var(--muted)",
                  }}
                >
                  Date
                </div>
                <input
                  type="date"
                  value={date}
                  onChange={(e) => setDate(e.target.value)}
                  style={fieldInput}
                />
              </div>
            </div>

            <div>
              <Label>Time</Label>
              <div style={fieldStyle}>
                <div
                  style={{
                    fontSize: 12,
                    fontFamily: "Inter, sans-serif",
                    color: "var(--muted)",
                  }}
                >
                  Time
                </div>
                <input
                  type="time"
                  value={time}
                  onChange={(e) => setTime(e.target.value)}
                  style={fieldInput}
                />
              </div>
            </div>

            <div>
              <Label>Time zone</Label>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 20,
                  fontWeight: 500,
                  color: "var(--text)",
                }}
              >
                West Africa Standard Time
              </div>
            </div>
          </div>

          <div
            style={{
              padding: "14px 20px 22px",
              borderTop: "1px solid var(--border)",
            }}
          >
            <button
              onClick={() => note("You have no scheduled posts yet.")}
              style={{
                background: "none",
                border: "none",
                padding: 0,
                color: BLUE,
                fontFamily: "Inter, sans-serif",
                fontSize: 15,
                fontWeight: 700,
                cursor: "pointer",
              }}
            >
              Scheduled posts
            </button>
          </div>
        </>
      )}

      {mode === "post" && postView === "disclosure" && (
        <>
          <div
            style={{
              display: "flex",
              alignItems: "center",
              padding: "16px 18px",
              borderBottom: "1px solid var(--border)",
              flexShrink: 0,
            }}
          >
            <h2
              style={{
                margin: 0,
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 18,
                fontWeight: 700,
                color: "var(--text)",
              }}
            >
              Content disclosure
            </h2>
            <button
              onClick={() => setPostView("compose")}
              style={{
                marginLeft: "auto",
                background: "none",
                border: "none",
                padding: 0,
                color: BLUE,
                fontFamily: "Inter, sans-serif",
                fontSize: 16,
                fontWeight: 700,
                cursor: "pointer",
              }}
            >
              Done
            </button>
          </div>

          <div
            style={{
              flex: 1,
              overflowY: "auto",
              padding: "24px 20px",
              display: "flex",
              flexDirection: "column",
              gap: 30,
            }}
          >
            <DisclosureRow
              title="Paid partnership"
              desc="Let others know this post promotes a brand or business."
              link="Learn more"
              on={paid}
              onToggle={() => setPaid((v) => !v)}
            />
            <DisclosureRow
              title="Made with AI"
              desc="Mark this post as containing synthetically generated content."
              on={withAi}
              onToggle={() => setWithAi((v) => !v)}
            />
          </div>
        </>
      )}

      {sheet && (
        <div
          onClick={() => setSheet(false)}
          style={{
            position: "absolute",
            inset: 0,
            background: "rgba(0,0,0,0.6)",
            zIndex: 80,
            display: "flex",
            flexDirection: "column",
            justifyContent: "flex-end",
          }}
        >
          <div
            onClick={(e) => e.stopPropagation()}
            style={{
              background: "var(--surface)",
              borderTop: "1px solid var(--border)",
              borderRadius: "22px 22px 0 0",
              padding: "10px 18px 22px",
              boxShadow: "0 -12px 40px rgba(0,0,0,0.5)",
            }}
          >
            <div
              style={{
                width: 40,
                height: 4,
                borderRadius: 3,
                background: "var(--border-strong)",
                margin: "0 auto 12px",
              }}
            />
            <button
              onClick={() => {
                setSheet(false)
                galleryInput.current?.click()
              }}
              style={sheetRow}
            >
              {icon(
                <>
                  <rect x="3" y="3" width="18" height="18" rx="4" />
                  <circle cx="8.5" cy="8.5" r="1.5" />
                  <path d="M21 15l-5-5L5 21" />
                </>,
                20,
              )}
              Upload
            </button>
            <button
              onClick={() => {
                setSheet(false)
                note("AI creation is coming soon.")
              }}
              style={sheetRow}
            >
              {icon(
                <path d="M12 3l1.9 5.1L19 10l-5.1 1.9L12 17l-1.9-5.1L5 10l5.1-1.9z" />,
                20,
              )}
              Create with AI
            </button>
            <button
              onClick={() => setSheet(false)}
              style={{
                width: "100%",
                height: 48,
                marginTop: 14,
                borderRadius: 50,
                border: "1px solid var(--border-strong)",
                background: "transparent",
                color: "var(--text)",
                fontFamily: "Inter, sans-serif",
                fontSize: 15.5,
                fontWeight: 600,
                cursor: "pointer",
              }}
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {mode === "text" && (
        <>
          <StudioHeader title="Text post" onBack={() => setMode("menu")} />
          <div
            style={{
              flex: 1,
              overflowY: "auto",
              padding: "18px 20px",
              display: "flex",
              flexDirection: "column",
              gap: 16,
            }}
          >
            <div
              style={{
                background: textStyle.bg,
                borderRadius: 18,
                minHeight: 210,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                padding: 26,
                textAlign: "center",
                border: "1px solid var(--border)",
              }}
            >
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 24,
                  fontWeight: 700,
                  lineHeight: 1.35,
                  color: textStyle.fg,
                  wordBreak: "break-word",
                }}
              >
                {body.trim() ? body : "Your words, front and center…"}
              </div>
            </div>

            <div>
              <Label>Card style</Label>
              <div style={{ display: "flex", gap: 10 }}>
                {textStyles.map((s) => (
                  <button
                    key={s.id}
                    aria-label={s.id}
                    onClick={() => setTextStyle(s)}
                    style={{
                      width: 42,
                      height: 42,
                      borderRadius: 12,
                      background: s.bg,
                      border: `2px solid ${
                        textStyle.id === s.id ? "#7C5CFF" : "var(--border)"
                      }`,
                      cursor: "pointer",
                    }}
                  />
                ))}
              </div>
            </div>

            <div>
              <Label>Text</Label>
              <textarea
                value={body}
                onChange={(e) => setBody(e.target.value.slice(0, 280))}
                rows={4}
                placeholder="Write something worth reading…"
                autoFocus
                style={{
                  width: "100%",
                  background: "var(--surface)",
                  border: "1.5px solid var(--border)",
                  borderRadius: 12,
                  padding: "12px 14px",
                  color: "var(--text)",
                  fontSize: 15,
                  fontFamily: "Inter, sans-serif",
                  outline: "none",
                  resize: "none",
                  boxSizing: "border-box",
                }}
                onFocus={(e) => (e.target.style.borderColor = "#7C5CFF")}
                onBlur={(e) => (e.target.style.borderColor = "var(--border)")}
              />
            </div>
          </div>
          <div
            style={{
              padding: "14px 20px 22px",
              borderTop: "1px solid var(--border)",
            }}
          >
            <PrimaryButton
              disabled={body.trim().length === 0}
              onClick={() => publish("Text post shared")}
            >
              Share text post
            </PrimaryButton>
          </div>
        </>
      )}

      {toast && (
        <div
          style={{
            position: "absolute",
            left: 20,
            right: 20,
            bottom: 28,
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 14,
            padding: "14px 16px",
            display: "flex",
            alignItems: "center",
            gap: 12,
            boxShadow: "0 12px 40px rgba(0,0,0,0.55)",
            zIndex: 70,
          }}
        >
          <span
            style={{
              width: 30,
              height: 30,
              borderRadius: "50%",
              background: "rgba(47,191,113,0.18)",
              color: "#2FBF71",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              flexShrink: 0,
            }}
          >
            {icon(<path d="M7.5 12.2l3 3 6-6.4" />, 16)}
          </span>
          <span
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 14.5,
              color: "var(--text)",
              fontWeight: 500,
            }}
          >
            {toast}
          </span>
        </div>
      )}
    </div>
  )
}
