import { useState } from "react"
import { useNavigate } from "react-router-dom"
import { ShoppingCart, Heart } from "lucide-react"
import BottomTabBar from "../../components/BottomTabBar"

const categories = ["All", "Anime", "Gaming", "Marvel", "Star Wars", "K-Pop"]

const products = [
  {
    id: 1,
    name: "Levi Ackerman Figure",
    price: 89.99,
    tag: "Anime",
    img: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=200&h=200&fit=crop&auto=format",
  },
  {
    id: 2,
    name: "Iron Man Helmet Replica",
    price: 149.99,
    tag: "Marvel",
    img: "https://images.unsplash.com/photo-1531259683007-016a7b628fc3?w=200&h=200&fit=crop&auto=format",
  },
  {
    id: 3,
    name: "Gaming Mechanical Keyboard",
    price: 119.99,
    tag: "Gaming",
    img: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=200&h=200&fit=crop&auto=format",
  },
  {
    id: 4,
    name: "Lightsaber Replica",
    price: 199.99,
    tag: "Star Wars",
    img: "https://images.unsplash.com/photo-1472457897821-70d3819a0e24?w=200&h=200&fit=crop&auto=format",
  },
  {
    id: 5,
    name: "BTS ARMY Bomb Light Stick",
    price: 49.99,
    tag: "K-Pop",
    img: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=200&h=200&fit=crop&auto=format",
  },
  {
    id: 6,
    name: "Demon Slayer Cloak",
    price: 79.99,
    tag: "Anime",
    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=200&h=200&fit=crop&auto=format",
  },
]

export default function ShopScreen() {
  const navigate = useNavigate()
  const [activeCategory, setActiveCategory] = useState("All")

  const filtered =
    activeCategory === "All"
      ? products
      : products.filter((p) => p.tag === activeCategory)

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div style={{ padding: "20px 20px 0" }}>
        <div
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "space-between",
            marginBottom: 16,
          }}
        >
          <h2
            style={{
              fontFamily: "Space Grotesk, sans-serif",
              fontSize: 22,
              fontWeight: 700,
              color: "var(--text)",
              margin: 0,
            }}
          >
            Shop
          </h2>
          <button
            onClick={() => navigate("/cart")}
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 10,
              width: 38,
              height: 38,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: "pointer",
              color: "var(--text)",
              position: "relative",
            }}
          >
            <ShoppingCart size={18} />
            <div
              style={{
                position: "absolute",
                top: -4,
                right: -4,
                width: 16,
                height: 16,
                background: "#FF6B5C",
                borderRadius: 8,
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                fontSize: 10,
                fontWeight: 700,
                color: "white",
                fontFamily: "Inter, sans-serif",
              }}
            >
              2
            </div>
          </button>
        </div>

        {/* Category chips */}
        <div
          style={{
            display: "flex",
            gap: 8,
            overflowX: "auto",
            paddingBottom: 4,
            scrollbarWidth: "none",
            marginBottom: 4,
          }}
        >
          {categories.map((c) => (
            <button
              key={c}
              onClick={() => setActiveCategory(c)}
              className={`fv-chip ${activeCategory === c ? "active" : ""}`}
            >
              {c}
            </button>
          ))}
        </div>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px 80px" }}>
        <div
          style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 14 }}
        >
          {filtered.map((product) => (
            <div
              key={product.id}
              onClick={() => navigate(`/shop/${product.id}`)}
              style={{
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 14,
                overflow: "hidden",
                cursor: "pointer",
              }}
            >
              <div
                style={{
                  height: 130,
                  background: "var(--surface-2)",
                  position: "relative",
                  overflow: "hidden",
                }}
              >
                <img
                  src={product.img}
                  alt={product.name}
                  style={{ width: "100%", height: "100%", objectFit: "cover" }}
                />
                <button
                  onClick={(e) => e.stopPropagation()}
                  style={{
                    position: "absolute",
                    top: 8,
                    right: 8,
                    background: "rgba(18,18,20,0.7)",
                    backdropFilter: "blur(8px)",
                    border: "none",
                    borderRadius: 8,
                    width: 30,
                    height: 30,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor: "pointer",
                    color: "var(--muted)",
                  }}
                >
                  <Heart size={14} />
                </button>
              </div>
              <div style={{ padding: "10px 12px" }}>
                <span
                  className="badge-violet"
                  style={{
                    marginBottom: 6,
                    display: "inline-block",
                    fontSize: 10,
                  }}
                >
                  {product.tag}
                </span>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 13,
                    fontWeight: 600,
                    color: "var(--text)",
                    marginBottom: 6,
                    lineHeight: 1.3,
                  }}
                >
                  {product.name}
                </div>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 15,
                    fontWeight: 700,
                    color: "#7C5CFF",
                  }}
                >
                  ${product.price}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>

      <BottomTabBar />
    </div>
  )
}
