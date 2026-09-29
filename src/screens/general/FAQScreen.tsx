import { useState } from "react"
import { ChevronDown } from "lucide-react"
import TopBar from "../../components/TopBar"

const faqs = [
  {
    q: "What is Fandom Verse?",
    a: "Fandom Verse is a platform for pop-culture fans to discover content, find events, shop exclusive merch, and connect with their fandoms — all in one place.",
  },
  {
    q: "Is Fandom Verse free to use?",
    a: "Yes, the core app is completely free. You can browse content, track events, and explore fandoms without paying anything. Shop purchases are separate.",
  },
  {
    q: "How do I become an admin?",
    a: "Admin accounts are pre-configured by our team. If you represent a brand or event organizer, contact us through the Contact page.",
  },
  {
    q: "Can I download content for offline use?",
    a: "Yes! Open any article and tap the download icon. You can manage your offline content in Profile → Offline Content.",
  },
  {
    q: "Are shop purchases real?",
    a: "All purchases in the current version are simulated — no real payment is processed. This is a demo environment.",
  },
  {
    q: "How does the AI Fan Helper work?",
    a: "The AI Fan Helper is a chatbot trained to answer questions about fandoms, lore, and events. It uses contextual knowledge from our content library.",
  },
]

export default function FAQScreen() {
  const [open, setOpen] = useState<number | null>(null)

  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title="FAQ" />

      <div style={{ flex: 1, overflowY: "auto", padding: "16px 20px" }}>
        {faqs.map((faq, i) => (
          <div
            key={i}
            style={{
              background: "var(--surface)",
              border: "1px solid var(--border)",
              borderRadius: 14,
              marginBottom: 10,
              overflow: "hidden",
            }}
          >
            <button
              onClick={() => setOpen(open === i ? null : i)}
              style={{
                width: "100%",
                display: "flex",
                alignItems: "center",
                justifyContent: "space-between",
                padding: "16px 18px",
                background: "none",
                border: "none",
                cursor: "pointer",
                textAlign: "left",
                gap: 12,
              }}
            >
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",
                  fontSize: 14,
                  fontWeight: 600,
                  color: "var(--text)",
                  lineHeight: 1.3,
                }}
              >
                {faq.q}
              </span>
              <ChevronDown
                size={18}
                color="var(--muted)"
                style={{
                  flexShrink: 0,
                  transform: open === i ? "rotate(180deg)" : "none",
                  transition: "transform 0.2s",
                }}
              />
            </button>
            {open === i && (
              <div
                style={{
                  padding: "0 18px 16px",
                  fontFamily: "Inter, sans-serif",
                  fontSize: 14,
                  color: "var(--muted-2)",
                  lineHeight: 1.6,
                }}
              >
                {faq.a}
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  )
}
