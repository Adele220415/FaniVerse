import { useState } from "react"
import { useNavigate } from "react-router-dom"
import { ArrowLeft, Trash2, Plus, Minus } from "lucide-react"

const initialItems = [
  {
    id: 1,
    name: "Levi Ackerman Figure",
    price: 89.99,
    qty: 1,
    img: "https://images.unsplash.com/photo-1607082348824-0a96f2a4b9da?w=80&h=80&fit=crop&auto=format",
  },
  {
    id: 2,
    name: "Demon Slayer Cloak",
    price: 79.99,
    qty: 2,
    img: "https://images.unsplash.com/photo-1578632767115-351597cf2477?w=80&h=80&fit=crop&auto=format",
  },
]

export default function CartScreen() {
  const navigate = useNavigate()
  const [items, setItems] = useState(initialItems)

  const changeQty = (id: number, delta: number) => {
    setItems((prev) =>
      prev.map((it) =>
        it.id === id ? { ...it, qty: Math.max(1, it.qty + delta) } : it,
      ),
    )
  }
  const remove = (id: number) =>
    setItems((prev) => prev.filter((it) => it.id !== id))
  const subtotal = items.reduce((acc, it) => acc + it.price * it.qty, 0)

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <div
        style={{
          padding: "20px 20px 16px",
          display: "flex",
          alignItems: "center",
          gap: 14,
          borderBottom: "1px solid var(--border)",
        }}
      >
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
        <h2
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 18,
            fontWeight: 700,
            color: "var(--text)",
            margin: 0,
          }}
        >
          Cart ({items.length})
        </h2>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        {items.map((item) => (
          <div
            key={item.id}
            style={{
              display: "flex",
              gap: 14,
              background: "var(--surface)",
              borderRadius: 14,
              padding: 14,
              border: "1px solid var(--border)",
              marginBottom: 12,
            }}
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
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                  marginBottom: 6,
                }}
              >
                {item.name}
              </div>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 16,
                  fontWeight: 700,
                  color: "#7C5CFF",
                  marginBottom: 8,
                }}
              >
                ${(item.price * item.qty).toFixed(2)}
              </div>
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <button
                  onClick={() => changeQty(item.id, -1)}
                  style={{
                    background: "var(--surface-2)",
                    border: "1px solid var(--border)",
                    borderRadius: 6,
                    width: 28,
                    height: 28,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor: "pointer",
                    color: "var(--text)",
                  }}
                >
                  <Minus size={12} />
                </button>
                <span
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 14,
                    fontWeight: 600,
                    color: "var(--text)",
                    minWidth: 20,
                    textAlign: "center",
                  }}
                >
                  {item.qty}
                </span>
                <button
                  onClick={() => changeQty(item.id, 1)}
                  style={{
                    background: "var(--surface-2)",
                    border: "1px solid var(--border)",
                    borderRadius: 6,
                    width: 28,
                    height: 28,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor: "pointer",
                    color: "var(--text)",
                  }}
                >
                  <Plus size={12} />
                </button>
                <button
                  onClick={() => remove(item.id)}
                  style={{
                    marginLeft: "auto",
                    background: "none",
                    border: "none",
                    cursor: "pointer",
                    color: "var(--muted)",
                  }}
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </div>
          </div>
        ))}
      </div>

      <div
        style={{
          padding: "16px 20px",
          borderTop: "1px solid var(--border)",
          background: "var(--app-bg)",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            marginBottom: 16,
          }}
        >
          <span
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 15,
              color: "var(--muted)",
            }}
          >
            Subtotal
          </span>
          <span
            style={{
              fontFamily: "Space Grotesk, sans-serif",
              fontSize: 17,
              fontWeight: 700,
              color: "var(--text)",
            }}
          >
            ${subtotal.toFixed(2)}
          </span>
        </div>
        <button className="btn-primary" onClick={() => navigate("/checkout")}>
          Checkout
        </button>
      </div>
    </div>
  )
}
