import type { CSSProperties } from "react"

export default function BackButton({
  onClick,
  label = "Back",
  size = 22,
  color = "var(--muted)",
  style,
}: {
  onClick: () => void
  label?: string
  size?: number
  color?: string
  style?: CSSProperties
}) {
  return (
    <button
      onClick={onClick}
      aria-label={label}
      style={{
        background: "none",
        border: "none",
        cursor: "pointer",
        padding: 0,
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        color,
        ...style,
      }}
    >
      <svg
        width={size}
        height={size}
        viewBox="0 0 24 24"
        fill="none"
        stroke="currentColor"
        strokeWidth={2}
        strokeLinecap="round"
        strokeLinejoin="round"
      >
        <path d="M19 12H5" />
        <path d="M12 19l-7-7 7-7" />
      </svg>
    </button>
  )
}
