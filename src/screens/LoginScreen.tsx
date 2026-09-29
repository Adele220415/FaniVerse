import { useState } from "react"
import BackButton from "../components/BackButton"

export default function LoginScreen({
  onLogin,
  onRegister,
  onBack,
}: {
  onLogin: () => void
  onRegister: () => void
  onBack: () => void
}) {
  const [email, setEmail] = useState("")
  const [password, setPassword] = useState("")

  return (
    <div
      className="flex flex-col flex-1 px-6 pb-10 overflow-y-auto"
      style={{ background: "var(--app-bg)" }}
    >
      <div className="pt-14 pb-8">
        <BackButton onClick={onBack} style={{ marginBottom: 14 }} />
        <h1
          style={{
            fontFamily: "Space Grotesk",
            fontSize: 28,
            fontWeight: 700,
            color: "var(--text)",
            margin: 0,
          }}
        >
          Welcome back
        </h1>
        <p style={{ fontSize: 14, color: "var(--muted)", margin: "6px 0 0" }}>
          Log in to your Fandom Verse account
        </p>
      </div>

      <div className="flex flex-col gap-4">
        <Field
          label="Email"
          type="email"
          value={email}
          onChange={setEmail}
          placeholder="you@example.com"
        />
        <div className="flex flex-col gap-1.5">
          <Field
            label="Password"
            type="password"
            value={password}
            onChange={setPassword}
            placeholder="••••••••"
          />
          <div className="flex justify-end">
            <button
              style={{
                fontSize: 13,
                color: "#7C5CFF",
                background: "none",
                border: "none",
                cursor: "pointer",
              }}
            >
              Forgot password?
            </button>
          </div>
        </div>

        <button
          onClick={onLogin}
          style={{
            background: "#7C5CFF",
            color: "#fff",
            fontFamily: "Space Grotesk",
            fontWeight: 600,
            fontSize: 16,
            padding: "14px",
            borderRadius: 8,
            border: "none",
            cursor: "pointer",
            marginTop: 4,
          }}
        >
          Log in
        </button>

        <Divider />

        <OAuthButton icon="G" label="Continue with Google" />
        <OAuthButton icon="🍎" label="Continue with Apple" />

        <p
          style={{
            textAlign: "center",
            fontSize: 14,
            color: "var(--muted)",
            marginTop: 8,
          }}
        >
          Don't have an account?{" "}
          <button
            onClick={onRegister}
            style={{
              color: "#7C5CFF",
              background: "none",
              border: "none",
              cursor: "pointer",
              fontWeight: 500,
            }}
          >
            Create one
          </button>
        </p>
      </div>
    </div>
  )
}

function Field({
  label,
  type,
  value,
  onChange,
  placeholder,
}: {
  label: string
  type: string
  value: string
  onChange: (v: string) => void
  placeholder: string
}) {
  return (
    <div className="flex flex-col gap-1.5">
      <label style={{ fontSize: 13, fontWeight: 500, color: "var(--muted)" }}>
        {label}
      </label>
      <input
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        placeholder={placeholder}
        style={{
          background: "var(--surface)",
          border: "1.5px solid var(--border)",
          borderRadius: 8,
          padding: "12px 14px",
          color: "var(--text)",
          fontSize: 15,
          fontFamily: "Inter",
          outline: "none",
        }}
        onFocus={(e) => (e.target.style.borderColor = "#7C5CFF")}
        onBlur={(e) => (e.target.style.borderColor = "var(--border)")}
      />
    </div>
  )
}

function Divider() {
  return (
    <div className="flex items-center gap-3">
      <div style={{ flex: 1, height: 1, background: "var(--border)" }} />
      <span style={{ fontSize: 13, color: "var(--muted)" }}>
        or continue with
      </span>
      <div style={{ flex: 1, height: 1, background: "var(--border)" }} />
    </div>
  )
}

type OAuthButtonProps = {
  icon: string
  label: string
}

function OAuthButton({ icon, label }: OAuthButtonProps) {
  return (
    <button
      style={{
        background: "var(--surface)",
        border: "1.5px solid var(--border)",
        borderRadius: 8,
        padding: "12px",
        color: "var(--text)",
        fontSize: 15,
        fontFamily: "Inter",
        fontWeight: 500,
        cursor: "pointer",
        display: "flex",
        alignItems: "center",
        justifyContent: "center",
        gap: 10,
      }}
    >
      <span style={{ fontSize: icon.length === 1 ? 18 : 16 }}>{icon}</span>
      {label}
    </button>
  )
}
