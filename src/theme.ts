import { useSyncExternalStore } from "react"

export type Theme = "dim" | "dark" | "lightsout" | "light"

export const THEMES: {
  id: Theme
  label: string
  desc: string
}[] = [
  { id: "dim", label: "Dim", desc: "Blue-toned dark background." },
  { id: "dark", label: "Dark", desc: "Default dark background." },
  { id: "lightsout", label: "Lights out", desc: "True black background." },
  { id: "light", label: "Light", desc: "Bright background." },
]

const STORAGE_KEY = "app-theme"
const listeners = new Set<() => void>()
const watchers = new Set<(theme: Theme) => void>()

function isTheme(value: string | null): value is Theme {
  return (
    value === "dim" ||
    value === "dark" ||
    value === "lightsout" ||
    value === "light"
  )
}

export function getTheme(): Theme {
  try {
    const stored = localStorage.getItem(STORAGE_KEY)
    if (isTheme(stored)) return stored
  } catch {
    // storage unavailable, fall back to default theme
  }
  return "dark"
}

export function applyTheme(theme: Theme) {
  document.documentElement.setAttribute("data-theme", theme)
  watchers.forEach((watcher) => watcher(theme))
}

export function onThemeChange(watcher: (theme: Theme) => void) {
  watchers.add(watcher)
  return () => {
    watchers.delete(watcher)
  }
}

export function setTheme(theme: Theme) {
  try {
    localStorage.setItem(STORAGE_KEY, theme)
  } catch {
    // storage unavailable, theme applies for this session only
  }
  applyTheme(theme)
  listeners.forEach((listener) => listener())
}

function subscribe(listener: () => void) {
  listeners.add(listener)
  return () => {
    listeners.delete(listener)
  }
}

export function useTheme(): Theme {
  return useSyncExternalStore(subscribe, getTheme, () => "dark" as Theme)
}

export function themeLabel(theme: Theme): string {
  return THEMES.find((t) => t.id === theme)?.label ?? "Dark"
}

applyTheme(getTheme())
