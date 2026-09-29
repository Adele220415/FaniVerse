import TopBar from "../../components/TopBar"

const team = [
  {
    name: "Maya Chen",
    role: "Founder & CEO",
    img: "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=60&h=60&fit=crop&auto=format",
  },
  {
    name: "Jordan Park",
    role: "Head of Design",
    img: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=60&h=60&fit=crop&auto=format",
  },
  {
    name: "Alex Torres",
    role: "Lead Engineer",
    img: "https://images.unsplash.com/photo-1527980965255-d3b416303d12?w=60&h=60&fit=crop&auto=format",
  },
  {
    name: "Sam Okonkwo",
    role: "Community Lead",
    img: "https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=60&h=60&fit=crop&auto=format",
  },
]

export default function AboutScreen() {
  return (
    <div
      style={{
        height: "100%",
        background: "var(--app-bg)",
        display: "flex",
        flexDirection: "column",
      }}
    >
      <TopBar title="About Us" />

      <div style={{ flex: 1, overflowY: "auto", padding: "20px 20px 40px" }}>
        <div
          style={{
            background: "#7C5CFF",
            borderRadius: 18,
            padding: "24px 22px",
            marginBottom: 24,
            position: "relative",
            overflow: "hidden",
          }}
        >
          <div
            style={{
              position: "absolute",
              top: -20,
              right: -20,
              width: 100,
              height: 100,
              background: "rgba(255,255,255,0.08)",
              borderRadius: "50%",
            }}
          />
          <div
            style={{
              position: "absolute",
              bottom: -30,
              right: 20,
              width: 70,
              height: 70,
              background: "rgba(255,255,255,0.06)",
              borderRadius: "50%",
            }}
          />
          <h2
            style={{
              fontFamily: "Space Grotesk, sans-serif",
              fontSize: 20,
              fontWeight: 700,
              color: "#fff",
              margin: "0 0 10px",
            }}
          >
            Built by fans, for fans
          </h2>
          <p
            style={{
              fontFamily: "Inter, sans-serif",
              fontSize: 14,
              color: "rgba(255,255,255,0.8)",
              margin: 0,
              lineHeight: 1.6,
            }}
          >
            Fandom Verse was born out of a simple frustration: fan content,
            events, and merchandise were scattered across dozens of platforms.
            We built one place to bring it all together.
          </p>
        </div>

        <p
          style={{
            fontFamily: "Inter, sans-serif",
            fontSize: 15,
            color: "var(--muted-2)",
            lineHeight: 1.7,
            margin: "0 0 28px",
          }}
        >
          Our team of 12 is spread across Los Angeles, Seoul, and Tokyo — all
          united by the fandoms that shaped us growing up. We believe pop
          culture communities deserve a dedicated home, not just a hashtag.
        </p>

        <h3
          style={{
            fontFamily: "Space Grotesk, sans-serif",
            fontSize: 17,
            fontWeight: 700,
            color: "var(--text)",
            margin: "0 0 16px",
          }}
        >
          The team
        </h3>

        <div
          style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 12 }}
        >
          {team.map((member) => (
            <div
              key={member.name}
              style={{
                background: "var(--surface)",
                border: "1px solid var(--border)",
                borderRadius: 14,
                padding: "16px",
                display: "flex",
                flexDirection: "column",
                alignItems: "center",
                gap: 10,
              }}
            >
              <img
                src={member.img}
                alt={member.name}
                style={{
                  width: 52,
                  height: 52,
                  borderRadius: 16,
                  objectFit: "cover",
                  border: "2px solid var(--border)",
                }}
              />
              <div style={{ textAlign: "center" }}>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",
                    fontSize: 14,
                    fontWeight: 600,
                    color: "var(--text)",
                    marginBottom: 3,
                  }}
                >
                  {member.name}
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",
                    fontSize: 12,
                    color: "var(--muted)",
                  }}
                >
                  {member.role}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
