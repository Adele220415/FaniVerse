import { useNavigate } from "react-router-dom"
import { Trash2 } from "lucide-react"
import TopBar from "../../components/TopBar"

const items = [
  {
    name: "Iron Man Helmet Replica",
    price: 149.99,
    originalPrice: 179.99,
    tag: "Marvel",
    img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=80&h=80&fit=crop&auto=format",
    priceDrop: true,
  },
  {
    name: "Lightsaber Replica",
    price: 199.99,
    originalPrice: 199.99,
    tag: "Star Wars",
    img: "https://images.unsplash.com/photo-1472457897821-70d3819a0e24?w=80&h=80&fit=crop&auto=format",
    priceDrop: false,
  },
  {
    name: "BTS ARMY Bomb Light Stick",
    price: 49.99,
    originalPrice: 49.99,
    tag: "K-Pop",
    img: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=80&h=80&fit=crop&auto=format",
    priceDrop: false,
  },
]

export default function WishlistScreen() {
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
      <TopBar title="Wishlist" />

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        {items.map((item, i) => (
          <div
            key={i}
            style={{
              display: "flex",
              gap: 14,
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              padding: 14,
              marginBottom: 10,
              cursor: "pointer",
            }}
            onClick={() => navigate("/shop/1")}
          >
            <img
              src={item.img}
              alt={item.name}
              style={{
                width: 64,
                height: 64,
                borderRadius: 10,
                objectFit: "cover",
                background: "var(--surface-2)",
                flexShrink: 0,
              }}
            />
            <div style={{ flex: 1 }}>
              <span
                className="badge-violet"
                style={{
                  fontSize: 10,
                  marginBottom: 6,
                  display: "inline-block",
                }}
              >
                {item.tag}
              </span>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                  marginBottom: 5,
                }}
              >
                {item.name}
              </div>
              <div style={{ display: "flex", gap: 8, alignItems: "center" }}>
                <span
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 15,
                    fontWeight: 700,
                    color: "#7C5CFF",
                  }}
                >
                  ${item.price}
                </span>
                {item.priceDrop && (
                  <>
                    <span
                      style={{
                        fontFamily: "Inter, sans-serif",
                        fontSize: 12,
                        color: "var(--muted)",
                        textDecoration: "line-through",
                      }}
                    >
                      ${item.originalPrice}
                    </span>
                    <span className="badge-coral">Price drop</span>
                  </>
                )}
              </div>
            </div>
            <button
              onClick={(e) => e.stopPropagation()}
              style={{
                background: "none",
                border: "none",
                cursor: "pointer",
                color: "var(--muted)",
                alignSelf: "center",
              }}
            >
              <Trash2 size={18} />
            </button>
          </div>
        ))}
      </div>
    </div>
  )
}
