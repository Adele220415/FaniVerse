import { useSyncExternalStore } from "react"
import { getTheme, onThemeChange, type Theme } from "./theme"

type RGB = [number, number, number]

export interface Anchors {
  deep: RGB
  mid: RGB
  light: RGB
}

export interface Wallpaper {
  id: string
  label: string
  desc: string
  src: string
  anchors: Anchors
}

const WALLPAPER_KEY = "app-wallpaper"
const CUSTOM_KEY = "app-wallpaper-custom"
const CUSTOM_ID = "custom"
const listeners = new Set<() => void>()

const clamp = (n: number) => (n < 0 ? 0 : n > 255 ? 255 : Math.round(n))

const mix = (a: RGB, b: RGB, t: number): RGB => [
  a[0] + (b[0] - a[0]) * t,
  a[1] + (b[1] - a[1]) * t,
  a[2] + (b[2] - a[2]) * t,
]

const rgb = (c: RGB) => `rgb(${clamp(c[0])}, ${clamp(c[1])}, ${clamp(c[2])})`

const rgba = (c: RGB, a: number) =>
  `rgba(${clamp(c[0])}, ${clamp(c[1])}, ${clamp(c[2])}, ${a})`

const luminance = (c: RGB) => 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]

type ThemeBase = {
  deep: RGB
  bg: RGB
  surface: RGB
  surface2: RGB
  border: RGB
  borderStrong: RGB
  border3: RGB
  light: boolean
}

const THEME_BASE: Record<Theme, ThemeBase> = {
  dark: {
    deep: [10, 10, 12],
    bg: [18, 18, 20],
    surface: [28, 28, 32],
    surface2: [37, 37, 41],
    border: [46, 46, 56],
    borderStrong: [58, 58, 68],
    border3: [74, 74, 87],
    light: false,
  },
  dim: {
    deep: [16, 24, 32],
    bg: [21, 32, 43],
    surface: [25, 39, 52],
    surface2: [34, 48, 60],
    border: [56, 68, 77],
    borderStrong: [70, 84, 95],
    border3: [85, 99, 110],
    light: false,
  },
  lightsout: {
    deep: [0, 0, 0],
    bg: [0, 0, 0],
    surface: [10, 10, 12],
    surface2: [22, 22, 26],
    border: [35, 35, 41],
    borderStrong: [46, 46, 54],
    border3: [61, 61, 71],
    light: false,
  },
  light: {
    deep: [232, 232, 238],
    bg: [255, 255, 255],
    surface: [247, 247, 250],
    surface2: [238, 238, 243],
    border: [228, 228, 236],
    borderStrong: [211, 211, 221],
    border3: [188, 188, 200],
    light: true,
  },
}

const VAR_KEYS = [
  "--app-bg-deep",
  "--app-bg",
  "--surface",
  "--surface-2",
  "--border",
  "--border-strong",
  "--border-3",
]

/**
 * Builds the colour set that matches a wallpaper, blended with the base theme
 * so text, borders and contrast still follow the selected theme.
 */
export function wallpaperVars(
  wallpaper: Wallpaper,
  theme: Theme,
): Record<string, string> {
  const base = THEME_BASE[theme]
  const { deep, mid, light } = wallpaper.anchors
  const tone: RGB = base.light ? light : mid
  const wash = base.light ? 0.55 : 0.45

  return {
    "--app-bg-deep": rgb(mix(base.deep, base.light ? light : deep, 0.7)),
    "--app-bg": rgba(mix(base.bg, tone, wash), 0.3),
    "--surface": rgba(mix(base.surface, tone, 0.4), 0.87),
    "--surface-2": rgba(mix(base.surface2, tone, 0.4), 0.94),
    "--border": rgb(mix(base.border, tone, 0.5)),
    "--border-strong": rgb(mix(base.borderStrong, tone, 0.5)),
    "--border-3": rgb(mix(base.border3, light, 0.3)),
  }
}

/** Veil painted over the picture so content stays readable in any theme. */
export function wallpaperScrim(wallpaper: Wallpaper, theme: Theme): string {
  const base = THEME_BASE[theme]
  const { deep, mid, light } = wallpaper.anchors
  const brightness = luminance(mix(deep, mid, 0.6)) / 255
  const veil = base.light
    ? mix([255, 255, 255], light, 0.35)
    : mix(base.deep, deep, 0.9)
  const strong = base.light
    ? Math.min(0.65, 0.42 + 0.25 * (1 - brightness))
    : Math.min(0.65, 0.44 + 0.25 * brightness)
  const soft = Math.max(0.2, strong - 0.16)
  return `linear-gradient(180deg, ${rgba(veil, strong)}, ${rgba(veil, soft)} 42%, ${rgba(veil, Math.min(0.75, strong + 0.12))})`
}

const svgUri = (svg: string) =>
  `data:image/svg+xml,${encodeURIComponent(svg.replace(/\s+/g, " ").trim())}`

const auroraArt = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 844' preserveAspectRatio='xMidYMid slice'><defs><linearGradient id='sky' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#04060f'/><stop offset='.45' stop-color='#0a142c'/><stop offset='1' stop-color='#05101c'/></linearGradient><linearGradient id='r1' x1='0' y1='0' x2='1' y2='1'><stop offset='0' stop-color='#4ff0c0' stop-opacity='0'/><stop offset='.5' stop-color='#4ff0c0' stop-opacity='.8'/><stop offset='1' stop-color='#8f7cff' stop-opacity='0'/></linearGradient><linearGradient id='r2' x1='1' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#63a8ff' stop-opacity='0'/><stop offset='.5' stop-color='#63a8ff' stop-opacity='.6'/><stop offset='1' stop-color='#c47cff' stop-opacity='0'/></linearGradient><filter id='soft' x='-40%' y='-40%' width='180%' height='180%'><feGaussianBlur stdDeviation='24'/></filter></defs><rect width='390' height='844' fill='url(#sky)'/><g filter='url(#soft)' fill='none'><path d='M-60 300 C 80 170 220 350 460 200' stroke='url(#r1)' stroke-width='76'/><path d='M-60 430 C 110 330 250 500 460 350' stroke='url(#r2)' stroke-width='58'/><path d='M-60 170 C 120 90 240 240 460 120' stroke='url(#r1)' stroke-width='34' opacity='.7'/></g><g fill='#eafff7'><circle cx='44' cy='86' r='1.7' opacity='.9'/><circle cx='118' cy='54' r='1.2' opacity='.7'/><circle cx='196' cy='110' r='1.5' opacity='.8'/><circle cx='268' cy='62' r='1.3' opacity='.75'/><circle cx='330' cy='128' r='1.6' opacity='.85'/><circle cx='76' cy='180' r='1.1' opacity='.6'/><circle cx='300' cy='210' r='1.2' opacity='.65'/><circle cx='150' cy='250' r='1' opacity='.5'/></g><path d='M0 742 L64 654 L118 712 L188 618 L246 700 L312 640 L390 716 L390 844 L0 844 Z' fill='#040912' opacity='.92'/><path d='M0 792 L58 736 L116 782 L178 716 L244 788 L316 738 L390 796 L390 844 L0 844 Z' fill='#02050c'/></svg>`

const sunsetArt = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 844' preserveAspectRatio='xMidYMid slice'><defs><linearGradient id='sky' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#1a0b2e'/><stop offset='.3' stop-color='#5b1e4d'/><stop offset='.55' stop-color='#b03f63'/><stop offset='.75' stop-color='#ec7f52'/><stop offset='1' stop-color='#f8c07c'/></linearGradient><filter id='soft' x='-50%' y='-50%' width='200%' height='200%'><feGaussianBlur stdDeviation='18'/></filter></defs><rect width='390' height='844' fill='url(#sky)'/><g fill='#fff' opacity='.55'><circle cx='60' cy='96' r='1.4'/><circle cx='250' cy='60' r='1.2'/><circle cx='330' cy='140' r='1.3'/></g><circle cx='196' cy='548' r='104' fill='#ffcf92' opacity='.55' filter='url(#soft)'/><circle cx='196' cy='548' r='66' fill='#ffe7c0'/><path d='M0 640 L74 552 L140 616 L214 520 L286 604 L344 556 L390 606 L390 844 L0 844 Z' fill='#4a1740' opacity='.85'/><path d='M0 706 L66 636 L132 690 L204 612 L272 688 L338 630 L390 676 L390 844 L0 844 Z' fill='#300f30' opacity='.92'/><path d='M0 772 L58 716 L124 764 L196 700 L264 766 L330 718 L390 760 L390 844 L0 844 Z' fill='#1c0820'/></svg>`

const lagoonArt = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 844' preserveAspectRatio='xMidYMid slice'><defs><linearGradient id='sky' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#02152b'/><stop offset='.4' stop-color='#063a63'/><stop offset='.68' stop-color='#0b7d9b'/><stop offset='1' stop-color='#12b3a6'/></linearGradient><filter id='soft' x='-50%' y='-50%' width='200%' height='200%'><feGaussianBlur stdDeviation='16'/></filter></defs><rect width='390' height='844' fill='url(#sky)'/><g fill='#fff' opacity='.6'><circle cx='70' cy='80' r='1.3'/><circle cx='160' cy='140' r='1.1'/><circle cx='250' cy='70' r='1.4'/></g><circle cx='300' cy='186' r='84' fill='#d8fbff' opacity='.25' filter='url(#soft)'/><circle cx='300' cy='186' r='52' fill='#e6fdff' opacity='.9'/><path d='M0 560 C 90 528 150 596 240 566 C 310 542 350 578 390 558 L390 844 L0 844 Z' fill='#04314f' opacity='.65'/><path d='M0 646 C 80 612 160 678 250 646 C 320 622 356 654 390 636 L390 844 L0 844 Z' fill='#022640' opacity='.85'/><path d='M0 736 C 90 706 150 764 240 734 C 316 710 350 742 390 724 L390 844 L0 844 Z' fill='#011b30'/><g stroke='#9ff3ef' stroke-width='2' fill='none' opacity='.5'><path d='M30 604 C 70 594 90 614 130 604'/><path d='M200 682 C 240 672 260 692 300 682'/><path d='M60 768 C 100 758 120 778 160 768'/></g></svg>`

const blossomArt = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 844' preserveAspectRatio='xMidYMid slice'><defs><linearGradient id='bg' x1='0' y1='0' x2='1' y2='1'><stop offset='0' stop-color='#ffeff6'/><stop offset='.5' stop-color='#f4ebff'/><stop offset='1' stop-color='#e8f2ff'/></linearGradient><filter id='soft' x='-50%' y='-50%' width='200%' height='200%'><feGaussianBlur stdDeviation='42'/></filter></defs><rect width='390' height='844' fill='url(#bg)'/><g filter='url(#soft)'><circle cx='80' cy='150' r='110' fill='#ffc9dd' opacity='.85'/><circle cx='330' cy='300' r='130' fill='#d9c8ff' opacity='.8'/><circle cx='140' cy='540' r='150' fill='#bfe4ff' opacity='.75'/><circle cx='320' cy='720' r='120' fill='#ffd7c4' opacity='.7'/><circle cx='40' cy='780' r='100' fill='#e7d3ff' opacity='.7'/></g><g fill='#fff' opacity='.65'><ellipse cx='120' cy='260' rx='14' ry='9' transform='rotate(-24 120 260)'/><ellipse cx='250' cy='420' rx='12' ry='8' transform='rotate(18 250 420)'/><ellipse cx='170' cy='680' rx='13' ry='8' transform='rotate(-8 170 680)'/><ellipse cx='300' cy='130' rx='11' ry='7' transform='rotate(32 300 130)'/></g></svg>`

const dunesArt = `<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 390 844' preserveAspectRatio='xMidYMid slice'><defs><linearGradient id='sky' x1='0' y1='0' x2='0' y2='1'><stop offset='0' stop-color='#fff3da'/><stop offset='.45' stop-color='#fbd9a6'/><stop offset='1' stop-color='#f0b877'/></linearGradient><filter id='soft' x='-50%' y='-50%' width='200%' height='200%'><feGaussianBlur stdDeviation='20'/></filter></defs><rect width='390' height='844' fill='url(#sky)'/><circle cx='258' cy='230' r='90' fill='#fff8e6' opacity='.75' filter='url(#soft)'/><circle cx='258' cy='230' r='54' fill='#fffdf4'/><path d='M0 560 C 110 498 190 612 390 540 L390 844 L0 844 Z' fill='#e6a765'/><path d='M0 664 C 130 602 220 704 390 642 L390 844 L0 844 Z' fill='#d18e4f'/><path d='M0 764 C 120 714 230 798 390 746 L390 844 L0 844 Z' fill='#b5713e'/></svg>`

export const PRESETS: Wallpaper[] = [
  {
    id: "aurora",
    label: "Aurora",
    desc: "Green ribbons over a starlit sky.",
    src: svgUri(auroraArt),
    anchors: { deep: [5, 8, 20], mid: [14, 34, 56], light: [186, 255, 232] },
  },
  {
    id: "sunset",
    label: "Sunset ridge",
    desc: "Warm sun sinking behind the hills.",
    src: svgUri(sunsetArt),
    anchors: { deep: [34, 14, 44], mid: [176, 70, 88], light: [255, 226, 184] },
  },
  {
    id: "lagoon",
    label: "Lagoon",
    desc: "Deep water fading into bright teal.",
    src: svgUri(lagoonArt),
    anchors: { deep: [3, 26, 50], mid: [16, 104, 130], light: [196, 246, 240] },
  },
  {
    id: "blossom",
    label: "Blossom",
    desc: "Soft pastel blooms on a pale sky.",
    src: svgUri(blossomArt),
    anchors: {
      deep: [176, 130, 192],
      mid: [255, 214, 234],
      light: [255, 247, 251],
    },
  },
  {
    id: "dunes",
    label: "Dunes",
    desc: "Golden desert light and warm sand.",
    src: svgUri(dunesArt),
    anchors: {
      deep: [146, 88, 52],
      mid: [240, 196, 148],
      light: [255, 240, 214],
    },
  },
]

let custom: Wallpaper | null = null
let current: Wallpaper | null = null
let list: Wallpaper[] = PRESETS
let sessionId: string | null = null

function isAnchors(value: unknown): value is Anchors {
  const a = value as Anchors | null
  return (
    !!a &&
    Array.isArray(a.deep) &&
    Array.isArray(a.mid) &&
    Array.isArray(a.light) &&
    a.deep.length === 3 &&
    a.mid.length === 3 &&
    a.light.length === 3
  )
}

interface StoredCustom {
  src?: string
  anchors?: unknown
}

interface ColorBucket {
  r: number
  g: number
  b: number
  n: number
}

function loadCustom(): Wallpaper | null {
  try {
    const raw = localStorage.getItem(CUSTOM_KEY)
    if (!raw) return null
    const stored = JSON.parse(raw) as StoredCustom
    if (!stored.src || !isAnchors(stored.anchors)) return null
    return {
      id: CUSTOM_ID,
      label: "My image",
      desc: "Your own picture, with matching colours.",
      src: stored.src,
      anchors: stored.anchors,
    }
  } catch {
    return null
  }
}

function loadId(): string | null {
  try {
    const stored = localStorage.getItem(WALLPAPER_KEY)
    if (stored !== null) return stored === "none" ? null : stored
  } catch {
    // storage unavailable, fall back to this session's choice
  }
  return sessionId
}

function resolve(id: string | null): Wallpaper | null {
  if (!id) return null
  if (id === CUSTOM_ID) return custom
  return PRESETS.find((item) => item.id === id) ?? null
}

function apply(wallpaper: Wallpaper | null) {
  const root = document.documentElement
  const vars = wallpaper ? wallpaperVars(wallpaper, getTheme()) : null
  for (const key of VAR_KEYS) {
    const value = vars?.[key]
    if (value) root.style.setProperty(key, value)
    else root.style.removeProperty(key)
  }
  if (wallpaper) root.setAttribute("data-wallpaper", wallpaper.id)
  else root.removeAttribute("data-wallpaper")
}

function refresh() {
  current = resolve(loadId())
  list = custom ? [...PRESETS, custom] : PRESETS
  apply(current)
  listeners.forEach((listener) => listener())
}

function subscribe(listener: () => void) {
  listeners.add(listener)
  return () => {
    listeners.delete(listener)
  }
}

export function getWallpaper(): Wallpaper | null {
  return current
}

export function getWallpapers(): Wallpaper[] {
  return list
}

export function setWallpaper(id: string | null) {
  sessionId = id
  try {
    localStorage.setItem(WALLPAPER_KEY, id ?? "none")
  } catch {
    // storage unavailable, wallpaper applies for this session only
  }
  refresh()
}

export function useWallpaper(): Wallpaper | null {
  return useSyncExternalStore(subscribe, getWallpaper, () => null)
}

export function useWallpapers(): Wallpaper[] {
  return useSyncExternalStore(subscribe, getWallpapers, () => PRESETS)
}

export function removeCustomWallpaper() {
  custom = null
  try {
    localStorage.removeItem(CUSTOM_KEY)
  } catch {
    // storage unavailable, nothing to clear
  }
  if (loadId() === CUSTOM_ID) setWallpaper(null)
  else refresh()
}

function readFile(file: File): Promise<string> {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.onload = () => resolve(String(reader.result))
    reader.onerror = () =>
      reject(reader.error ?? new Error("Could not read file"))
    reader.readAsDataURL(file)
  })
}

function loadImage(src: string): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const image = new Image()
    image.onload = () => resolve(image)
    image.onerror = () => reject(new Error("Could not decode that image"))
    image.src = src
  })
}

function average(bucket: ColorBucket): RGB {
  if (bucket.n === 0) return [128, 128, 128]
  return [bucket.r / bucket.n, bucket.g / bucket.n, bucket.b / bucket.n]
}

function sampleAnchors(image: HTMLImageElement): Anchors {
  const size = 48
  const canvas = document.createElement("canvas")
  canvas.width = size
  canvas.height = size
  const ctx = canvas.getContext("2d", { willReadFrequently: true })
  if (!ctx)
    return { deep: [16, 16, 20], mid: [64, 64, 72], light: [235, 235, 245] }
  ctx.drawImage(image, 0, 0, size, size)

  const dark = { r: 0, g: 0, b: 0, n: 0 }
  const mid = { r: 0, g: 0, b: 0, n: 0 }
  const bright = { r: 0, g: 0, b: 0, n: 0 }
  const all = { r: 0, g: 0, b: 0, n: 0 }

  const { data } = ctx.getImageData(0, 0, size, size)
  for (let i = 0; i < data.length; i += 4) {
    if (data[i + 3] < 125) continue
    const pixel: RGB = [data[i], data[i + 1], data[i + 2]]
    const tone = luminance(pixel)
    const bucket = tone < 85 ? dark : tone < 175 ? mid : bright
    bucket.r += pixel[0]
    bucket.g += pixel[1]
    bucket.b += pixel[2]
    bucket.n += 1
    all.r += pixel[0]
    all.g += pixel[1]
    all.b += pixel[2]
    all.n += 1
  }

  const overall = average(all)
  const deep = dark.n > 0 ? average(dark) : mix(overall, [0, 0, 0], 0.45)
  const middle = mid.n > 0 ? average(mid) : overall
  const light =
    bright.n > 0 ? average(bright) : mix(overall, [255, 255, 255], 0.45)

  const anchors = { deep, mid: middle, light }
  if (luminance(deep) > luminance(light)) {
    anchors.deep = light
    anchors.light = deep
  }
  return anchors
}

function resize(image: HTMLImageElement): string {
  const max = 1080
  const scale = Math.min(
    1,
    max / Math.max(image.naturalWidth, image.naturalHeight),
  )
  const width = Math.max(1, Math.round(image.naturalWidth * scale))
  const height = Math.max(1, Math.round(image.naturalHeight * scale))
  const canvas = document.createElement("canvas")
  canvas.width = width
  canvas.height = height
  const ctx = canvas.getContext("2d")
  if (!ctx) return image.src
  ctx.fillStyle = "#ffffff"
  ctx.fillRect(0, 0, width, height)
  ctx.drawImage(image, 0, 0, width, height)
  try {
    return canvas.toDataURL("image/jpeg", 0.8)
  } catch {
    return image.src
  }
}

/** Stores an uploaded picture and switches to it, deriving matching colours. */
export async function addCustomWallpaper(file: File): Promise<Wallpaper> {
  const source = await readFile(file)
  const image = await loadImage(source)
  const wallpaper: Wallpaper = {
    id: CUSTOM_ID,
    label: "My image",
    desc: "Your own picture, with matching colours.",
    src: resize(image),
    anchors: sampleAnchors(image),
  }
  custom = wallpaper
  try {
    localStorage.setItem(
      CUSTOM_KEY,
      JSON.stringify({ src: wallpaper.src, anchors: wallpaper.anchors }),
    )
  } catch {
    // storage unavailable or image too large, keeps the wallpaper for this session
  }
  setWallpaper(CUSTOM_ID)
  return wallpaper
}

custom = loadCustom()
onThemeChange(() => apply(current))
refresh()
