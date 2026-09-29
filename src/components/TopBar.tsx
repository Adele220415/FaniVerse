import { useNavigate } from "react-router-dom"
import { ArrowLeft } from "lucide-react"
import { ReactNode } from "react"

interface TopBarProps {
  title?: string
  back?: boolean
  right?: ReactNode
  transparent?: boolean
}

export default function TopBar({
  title,
  back = true,
  right,
  transparent,
}: TopBarProps) {
  const navigate = useNavigate()

  return (
    <div
      style={{
        display: "flex",
        alignItems: "center",
        justifyContent: "space-between",
        padding: "16px 20px",
        background: transparent ? "transparent" : "var(--app-bg)",
        borderBottom: transparent ? "none" : "1px solid var(--border)",
        position: "sticky",
        top: 0,
        zIndex: 30,
      }}
    >
      <div style={{ width: 40 }}>
        {back && (
          <button
            onClick={() => navigate(-1)}
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 8,
              width: 36,
              height: 36,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: "pointer",
              color: "var(--text)",
            }}
          >
            <ArrowLeft size={18} />
          </button>
        )}
      </div>
      {title && (
        <h2
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 17,
            fontWeight: 600,
            color: "var(--text)",
            margin: 0,
          }}
        >
          {title}
        </h2>
      )}
      <div style={{ width: 40, display: "flex", justifyContent: "flex-end" }}>
        {right}
      </div>
    </div>
  )
}
