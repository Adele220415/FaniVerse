import { useState } from "react"
import BackButton from "../components/BackButton"

export default function RegisterScreen({
  onDone,
  onLogin,
  onBack,
}: {
  onDone: () => void
  onLogin: () => void
  onBack: () => void
}) {
  const [form, setForm] = useState({
    name: "",
    email: "",
    password: "",
    confirm: "",
  })
  const set = (k: keyof typeof form) => (v: string) =>
    setForm((f) => ({ ...f, [k]: v }))

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
          Create account
        </h1>
        <p style={{ fontSize: 14, color: "var(--muted)", margin: "6px 0 0" }}>
          Join the Fandom Verse community
        </p>
      </div>

      <div className="flex flex-col gap-4">
        {([
          { k: "name", label: "Full name", type: "text", ph: "Alex Kim" },
          { k: "email", label: "Email", type: "email", ph: "you@example.com" },
          {
            k: "password",
            label: "Password",
            type: "password",
            ph: "••••••••",
          },
          {
            k: "confirm",
            label: "Confirm password",
            type: "password",
            ph: "••••••••",
          },
        ] as const).map(({ k, label, type, ph }) => (
          <Field
            key={k}
            label={label}
            type={type}
            value={form[k]}
            onChange={set(k)}
            placeholder={ph}
          />
        ))}

        <button
          onClick={onDone}
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
          Create account
        </button>

        <div className="flex items-center gap-3">
          <div style={{ flex: 1, height: 1, background: "var(--border)" }} />
          <span style={{ fontSize: 13, color: "var(--muted)" }}>
            or continue with
          </span>
          <div style={{ flex: 1, height: 1, background: "var(--border)" }} />
        </div>

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
          }}
        >
          G &nbsp; Continue with Google
        </button>
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
          }}
        >
          🍎 &nbsp; Continue with Apple
        </button>

        <p
          style={{
            textAlign: "center",
            fontSize: 14,
            color: "var(--muted)",
            marginTop: 8,
          }}
        >
          Already have an account?{" "}
          <button
            onClick={onLogin}
            style={{
              color: "#7C5CFF",
              background: "none",
              border: "none",
              cursor: "pointer",
              fontWeight: 500,
            }}
          >
            Log in
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
