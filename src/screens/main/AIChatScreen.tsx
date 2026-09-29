import { useState, useRef, useEffect } from "react"
import { useNavigate } from "react-router-dom"
import { ArrowLeft, Send, Sparkles } from "lucide-react"

type Message = {
  role: "user" | "ai"
  text: string
}

const suggestions = [
  "Tell me about Attack on Titan",
  "Best Marvel entry points",
  "Upcoming K-Pop comebacks",
  "Elden Ring lore explained",
]

const aiResponses: Record<string, string> = {
  default:
    "That's a great question! Fandom Verse has tons of resources on that topic. Check out the Deep Dive section for detailed lore, or the Beginner Hub if you're just getting started. Anything specific you'd like to know?",
}

export default function AIChatScreen() {
  const navigate = useNavigate()
  const [messages, setMessages] = useState<Message[]>([
    {
      role: "ai",
      text: "Hey! I'm your AI Fan Helper 🤖✨ Ask me anything about your favorite fandoms — lore, events, recommendations, you name it!",
    },
  ])
  const [input, setInput] = useState("")
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" })
  }, [messages])

  const send = (text?: string) => {
    const msg = text ?? input.trim()
    if (!msg) return
    setMessages((prev) => [...prev, { role: "user", text: msg }])
    setInput("")
    setTimeout(() => {
      setMessages((prev) => [
        ...prev,
        { role: "ai", text: aiResponses.default },
      ])
    }, 900)
  }

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      {/* Header */}
      <div
        style={{
          padding: "16px 20px",
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
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: 10,
              background: "#7C5CFF",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
            }}
          >
            <Sparkles size={18} color="white" />
          </div>
          <div>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",
                fontSize: 15,
                fontWeight: 700,
                color: "var(--text)",
              }}
            >
              AI Fan Helper
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",
                fontSize: 12,
                color: "#4CAF50",
              }}
            >
              ● Online
            </div>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div style={{ flex: 1, overflowY: "auto", padding: "16px 16px 8px" }}>
        {messages.map((msg, i) => (
          <div
            key={i}
            style={{
              display: "flex",
              justifyContent: msg.role === "user" ? "flex-end" : "flex-start",
              marginBottom: 12,
            }}
          >
            <div
              style={{
                maxWidth: "80%",
                background: msg.role === "user" ? "#7C5CFF" : "var(--surface)",
                border: msg.role === "ai" ? "1px solid var(--border)" : "none",
                borderRadius:
                  msg.role === "user"
                    ? "16px 16px 4px 16px"
                    : "16px 16px 16px 4px",
                padding: "12px 14px",
                fontFamily: "Inter, sans-serif",
                fontSize: 14,
                color: "var(--text)",
                lineHeight: 1.6,
              }}
            >
              {msg.text}
            </div>
          </div>
        ))}

        {/* Suggestions (only on initial) */}
        {messages.length === 1 && (
          <div
            style={{
              display: "flex",
              flexWrap: "wrap",
              gap: 8,
              margin: "8px 0",
            }}
          >
            {suggestions.map((s) => (
              <button
                key={s}
                onClick={() => send(s)}
                className="fv-chip"
                style={{ fontSize: 12 }}
              >
                {s}
              </button>
            ))}
          </div>
        )}

        <div ref={bottomRef} />
      </div>

      {/* Input */}
      <div
        style={{
          padding: "12px 16px",
          borderTop: "1px solid var(--border)",
          display: "flex",
          gap: 10,
          background: "var(--app-bg)",
        }}
      >
        <input
          className="fv-input"
          placeholder="Ask about any fandom..."
          value={input}
          onChange={(e) => setInput(e.target.value)}
          onKeyDown={(e) => e.key === "Enter" && send()}
          style={{ flex: 1, padding: "12px 14px" }}
        />
        <button
          onClick={() => send()}
          style={{
            background: "#7C5CFF",
            border: "none",
            borderRadius: 10,
            width: 44,
            height: 44,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            cursor: "pointer",
            flexShrink: 0,
          }}
        >
          <Send size={18} color="white" />
        </button>
      </div>
    </div>
  )
}
