import { useNavigate } from "react-router-dom"
import { ArrowLeft, Heart, ShoppingCart } from "lucide-react"

export default function ProductDetailScreen() {
  const navigate = useNavigate()

  return (
    <div
      style={{ height: "100%", background: "var(--app-bg)", overflowY: "auto" }}
    >
      {/* Hero */}
      <div
        style={{
          position: "relative",
          height: 280,
          background: "var(--surface)",
        }}
      >
        <img
          src="https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=390&h=280&fit=crop&auto=format"
          alt="Levi Ackerman Figure"
          style={{ width: "100%", height: "100%", objectFit: "cover" }}
        />
        <button
          onClick={() => navigate(-1)}
          style={{
            position: "absolute",
            top: 16,
            left: 16,
            background: "rgba(18,18,20,0.7)",
            backdropFilter: "blur(8px)",
            border: "1px solid rgba(255,255,255,0.1)",
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
      </div>

      <div style={{ padding: "20px 20px 100px" }}>
        <span
          className="badge-violet"
          style={{ marginBottom: 10, display: "inline-block" }}
        >
          Anime
        </span>
        <h1
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 22,
            fontWeight: 700,
            color: "var(--text)",
            margin: "0 0 6px",
          }}
        >
          Levi Ackerman Figure
        </h1>
        <div
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 26,
            fontWeight: 700,
            color: "#7C5CFF",
            marginBottom: 16,
          }}
        >
          $89.99
        </div>

        <div
          style={{ height: 1, background: "var(--border)", margin: "0 0 16px" }}
        />

        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 14,
            color: "var(--muted-2)",
            lineHeight: 1.7,
            margin: "0 0 20px",
          }}
        >
          Premium articulated figure of Captain Levi from Attack on Titan.
          Features interchangeable hand parts, Thunder Spear accessories, and
          detailed ODM gear. Officially licensed by MAPPA and Kodansha. Scale
          1:6.
        </p>

        <div
          style={{
            background: "var(--surface)",
            borderRadius: 12,
            padding: 16,
            border: "1px solid var(--border)",
            marginBottom: 20,
          }}
        >
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              marginBottom: 8,
            }}
          >
            <span
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
              }}
            >
              Brand
            </span>
            <span
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--text)",
              }}
            >
              Good Smile Company
            </span>
          </div>
          <div
            style={{
              display: "flex",
              justifyContent: "space-between",
              marginBottom: 8,
            }}
          >
            <span
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
              }}
            >
              Scale
            </span>
            <span
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--text)",
              }}
            >
              1:6 (28cm)
            </span>
          </div>
          <div style={{ display: "flex", justifyContent: "space-between" }}>
            <span
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "var(--muted)",
              }}
            >
              In stock
            </span>
            <span
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 13,
                color: "#4CAF50",
              }}
            >
              Available
            </span>
          </div>
        </div>
      </div>

      {/* Bottom CTA */}
      <div
        style={{
          position: "sticky",
          bottom: 0,
          background: "var(--app-bg)",
          borderTop: "1px solid var(--border)",
          padding: "16px 20px",
          display: "flex",
          gap: 12,
        }}
      >
        <button
          onClick={() => navigate("/wishlist")}
          style={{
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 8,
            width: 50,
            height: 50,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            color: "var(--muted)",
            flexShrink: 0,
          }}
        >
          <Heart size={20} />
        </button>
        <button
          className="btn-primary"
          onClick={() => navigate("/cart")}
          style={{
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            gap: 8,
          }}
        >
          <ShoppingCart size={18} /> Add to cart
        </button>
      </div>
    </div>
  )
}
