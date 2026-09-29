import { useNavigate } from "react-router-dom"
import { Camera } from "lucide-react"
import TopBar from "../../components/TopBar"

const interests = [
  "Anime",
  "Gaming",
  "Marvel",
  "Star Wars",
  "K-Pop",
  "Comics",
  "Sci-Fi",
]

export default function EditProfileScreen() {
  const navigate = useNavigate()

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title="Edit Profile" />

      <div style={{ flex: 1, overflowY: "auto", padding: "24px 20px" }}>
        {/* Avatar */}
        <div
          style={{
            display: "flex",
            justifyContent: "center",
            marginBottom: 28,
          }}
        >
          <div style={{ position: "relative" }}>
            <img
              src="https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=96&h=96&fit=crop&auto=format"
              alt="Avatar"
              style={{
                width: 88,
                height: 88,
                borderRadius: 26,
                objectFit: "cover",
                border: "2px solid #7C5CFF",
              }}
            />
            <button
              style={{
                position: "absolute",
                bottom: -6,
                right: -6,
                background: "#7C5CFF",
                border: "2px solid var(--app-bg)",
                borderRadius: 12,
                width: 30,
                height: 30,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                cursor: "pointer",
              }}
            >
              <Camera size={14} color="white" />
            </button>
          </div>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 14 }}>
          <div>
            <label
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
                display: "block",
                marginBottom: 6,
              }}
            >
              Name
            </label>
            <input className="fv-input" defaultValue="Alex Rivera" />
          </div>
          <div>
            <label
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
                display: "block",
                marginBottom: 6,
              }}
            >
              Bio
            </label>
            <textarea
              className="fv-input"
              defaultValue="Anime · Gaming · Marvel enthusiast"
              rows={3}
              style={{ resize: "none", lineHeight: 1.5 }}
            />
          </div>
          <div>
            <label
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
                display: "block",
                marginBottom: 10,
              }}
            >
              Fandom Interests
            </label>
            <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
              {interests.map((i) => (
                <button
                  key={i}
                  className="fv-chip active"
                  style={{ fontSize: 13 }}
                >
                  {i}
                </button>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div
        style={{ padding: "16px 20px", borderTop: "1px solid var(--border)" }}
      >
        <button className="btn-primary" onClick={() => navigate(-1)}>
          Save changes
        </button>
      </div>
    </div>
  )
}
