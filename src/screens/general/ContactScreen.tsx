import TopBar from "../../components/TopBar"
import { Mail, Phone, MapPin } from "lucide-react"

export default function ContactScreen() {
  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title="Contact Us" />

      <div style={{ flex: 1, overflowY: "auto", padding: "20px 20px 40px" }}>
        <div
          style={{
            display: "flex",
            flexDirection: "column",
            gap: 14,
            marginBottom: 28,
          }}
        >
          <input className="fv-input" placeholder="Your name" />
          <input
            className="fv-input"
            type="email"
            placeholder="Email address"
          />
          <textarea
            className="fv-input"
            placeholder="How can we help?"
            rows={5}
            style={{ resize: "none", lineHeight: 1.5 }}
          />
          <button className="btn-primary">Submit</button>
        </div>

        <div
          style={{
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 14,
            padding: 20,
            marginBottom: 16,
          }}
        >
          <h3
            style={{
              fontFamily: "Space Grotesk, sans-serif",
              fontSize: 15,
              fontWeight: 600,
              color: "var(--text)",
              margin: "0 0 14px",
            }}
          >
            Contact details
          </h3>
          {[
            { icon: Mail, text: "hello@fandomverse.io", color: "#7C5CFF" },
            { icon: Phone, text: "+1 (800) 326-6683", color: "#4CAF50" },
            {
              icon: MapPin,
              text: "1234 Fan Ave, Los Angeles, CA",
              color: "#FF6B5C",
            },
          ].map((item, i) => {
            const Icon = item.icon
            return (
              <div
                key={i}
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: 12,
                  marginBottom: i < 2 ? 12 : 0,
                }}
              >
                <Icon size={16} color={item.color} />
                <span
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 14,
                    color: "var(--muted-2)",
                  }}
                >
                  {item.text}
                </span>
              </div>
            )
          })}
        </div>

        {/* Map placeholder */}
        <div
          style={{
            height: 140,
            background: "var(--surface)",
            border: "1px solid var(--border)",
            borderRadius: 14,
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
          }}
        >
          <div
            style={{
              textAlign: "center",
              color: "var(--muted)",
              fontFamily: "Inter, sans-serif",
              fontSize: 13,
            }}
          >
            <MapPin
              size={24}
              color="var(--muted)"
              style={{ marginBottom: 6 }}
            />
            <div>Map placeholder</div>
          </div>
        </div>
      </div>
    </div>
  )
}
