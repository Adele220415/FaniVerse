import { useNavigate, useParams } from "react-router-dom"
import TopBar from "../../components/TopBar"

const fieldSets: Record<string, {
  label: string
  type: string
  placeholder: string
}[]> = {
  content: [
    { label: "Title", type: "text", placeholder: "Article title" },
    { label: "Fandom Tag", type: "text", placeholder: "e.g. Anime" },
    {
      label: "Content Type",
      type: "text",
      placeholder: "Article / Video / Podcast",
    },
    { label: "Body", type: "textarea", placeholder: "Content body..." },
    { label: "Thumbnail URL", type: "text", placeholder: "https://..." },
  ],
  events: [
    { label: "Event Name", type: "text", placeholder: "Event name" },
    { label: "Date", type: "text", placeholder: "Jul 4–7, 2026" },
    { label: "City", type: "text", placeholder: "Los Angeles, CA" },
    {
      label: "Description",
      type: "textarea",
      placeholder: "Event description...",
    },
    { label: "Ticket URL", type: "text", placeholder: "https://..." },
  ],
  merchandise: [
    { label: "Product Name", type: "text", placeholder: "Product name" },
    { label: "Price", type: "text", placeholder: "$0.00" },
    { label: "Fandom Tag", type: "text", placeholder: "e.g. Marvel" },
    {
      label: "Description",
      type: "textarea",
      placeholder: "Product description...",
    },
    { label: "Image URL", type: "text", placeholder: "https://..." },
  ],
  users: [
    { label: "Full Name", type: "text", placeholder: "Full name" },
    { label: "Email", type: "text", placeholder: "email@example.com" },
    { label: "Role", type: "text", placeholder: "Fan / Admin" },
  ],
  categories: [
    { label: "Category Name", type: "text", placeholder: "e.g. Anime" },
    {
      label: "Description",
      type: "textarea",
      placeholder: "Category description...",
    },
  ],
}

export default function AdminFormScreen() {
  const navigate = useNavigate()
  const { type = "content", action = "new" } = useParams<{
    type: string
    action: string
  }>()
  const fields = fieldSets[type] ?? fieldSets.content
  const label = type.charAt(0).toUpperCase() + type.slice(1)
  const isEdit = action === "edit"

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title={`${isEdit ? "Edit" : "Add"} ${label}`} />

      <div style={{ flex: 1, overflowY: "auto", padding: "20px 20px" }}>
        <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
          {fields.map((field) => (
            <div key={field.label}>
              <label
                style={{
                  fontFamily: "Inter, sans-serif",
                  fontSize: 13,
                  color: "var(--muted)",
                  display: "block",
                  marginBottom: 6,
                }}
              >
                {field.label}
              </label>
              {field.type === "textarea" ? (
                <textarea
                  className="fv-input"
                  placeholder={field.placeholder}
                  rows={4}
                  style={{ resize: "none", lineHeight: 1.5 }}
                />
              ) : (
                <input
                  className="fv-input"
                  type={field.type}
                  placeholder={field.placeholder}
                />
              )}
            </div>
          ))}
        </div>
      </div>

      <div
        style={{
          padding: "16px 20px",
          borderTop: "1px solid var(--border)",
          display: "flex",
          gap: 10,
        }}
      >
        <button
          onClick={() => navigate(-1)}
          className="btn-secondary"
          style={{ flex: 0, padding: "14px 20px" }}
        >
          Cancel
        </button>
        <button
          onClick={() => navigate(-1)}
          className="btn-primary"
          style={{ background: "#FF6B5C" }}
          onMouseEnter={(e) => (e.currentTarget.style.background = "#E05546")}
          onMouseLeave={(e) => (e.currentTarget.style.background = "#FF6B5C")}
        >
          Save
        </button>
      </div>
    </div>
  )
}
