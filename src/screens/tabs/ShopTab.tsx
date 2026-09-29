import { useEffect, useMemo, useState } from "react"

import {
  ArrowDown,
  ArrowUp,
  Check,
  ChevronLeft,
  ChevronRight,
  CreditCard,
  Heart,
  MapPin,
  MessageCircle,
  Minus,
  Plus,
  Search,
  Share2,
  ShoppingCart,
  Star,
  Store,
  Ticket,
  Trash2,
  Truck,
  X,
} from "lucide-react"

const BG = "var(--app-bg)"

const SURFACE = "var(--surface)"

const SURFACE2 = "var(--surface-2)"

const BORDER = "var(--border)"

const TEXT = "var(--text)"

const MUTED = "var(--muted)"

const VIOLET = "#7C5CFF"

const CORAL = "#FF6B5C"

const GOLD = "#FFC107"

const u = (id: string, w: number, h: number) =>
  `https://images.unsplash.com/${id}?w=${w}&h=${h}&fit=crop&auto=format`

const money = (n: number) => `$${n.toFixed(2)}`

const compact = (n: number) =>
  n >= 1000 ? `${(n / 1000).toFixed(1).replace(".0", "")}k` : `${n}`

const off = (price: number, old: number) => Math.round((1 - price / old) * 100)

type Review = {
  user: string

  stars: number

  text: string

  when: string
}

type Variant = {
  label: string

  options: string[]
}

type Product = {
  id: number

  name: string

  price: number

  oldPrice: number

  tag: string

  shop: string

  images: string[]

  desc: string

  rating: number

  reviewCount: number

  sold: number

  freeShip: boolean

  isNew?: boolean

  flash?: boolean

  variants?: Variant[]

  reviews: Review[]
}

const products: Product[] = [
  {
    id: 1,

    name: "Attack on Titan Survey Corps Jacket",

    price: 89,

    oldPrice: 129,

    tag: "Anime",

    shop: "Scout Supply Co.",

    images: [
      "photo-1542291026-7eec264c27ff",

      "photo-1556821840-3a63f15732ce",

      "photo-1581833971358-2c8b550f87b3",
    ],

    desc: "Premium embroidered jacket modeled after the iconic Scout Regiment uniform. 100% cotton, embroidered patches, regular and relaxed fit.",

    rating: 4.8,

    reviewCount: 124,

    sold: 2300,

    freeShip: true,

    flash: true,

    variants: [{ label: "Size", options: ["S", "M", "L", "XL"] }],

    reviews: [
      {
        user: "Mika T.",

        stars: 5,

        text: "Stitching is incredible and the patch quality is way above the price. Runs slightly large.",

        when: "2d ago",
      },

      {
        user: "cole.exe",

        stars: 4,

        text: "Great jacket, shipping took a week but worth it. Zipper feels solid.",

        when: "1w ago",
      },
    ],
  },

  {
    id: 2,

    name: "Elden Ring Erdtree Art Print",

    price: 35,

    oldPrice: 49,

    tag: "Gaming",

    shop: "Golden Order Prints",

    images: [
      "photo-1611532736597-de2d4265fba3",

      "photo-1612404730960-5c71577fca11",

      "photo-1607082348824-0a96f2a4b9da",
    ],

    desc: "Museum-quality art print on 300gsm paper. 18×24 inches, unframed, archival inks that won't fade.",

    rating: 4.6,

    reviewCount: 58,

    sold: 860,

    freeShip: false,

    reviews: [
      {
        user: "TarnishedOne",

        stars: 5,

        text: "Colors pop way more in person. Paper is thick and didn't curl at all.",

        when: "4d ago",
      },

      {
        user: "rin",

        stars: 4,

        text: "Beautiful print but I wish it came in a tube instead of a flat box.",

        when: "3w ago",
      },
    ],
  },

  {
    id: 3,

    name: "Marvel Infinity Gauntlet Replica",

    price: 149,

    oldPrice: 199,

    tag: "Marvel",

    shop: "Marvel Vault Official",

    images: [
      "photo-1608889335941-32ac5f2041b9",

      "photo-1612036782180-6f0b6cd846fe",

      "photo-1531259683007-016a7b628fc3",
    ],

    desc: "Die-cast metal replica with light-up gems. Limited edition of 500 worldwide with numbered certificate.",

    rating: 4.9,

    reviewCount: 211,

    sold: 4100,

    freeShip: true,

    flash: true,

    reviews: [
      {
        user: "Avenger07",

        stars: 5,

        text: "Heavy, detailed, lights work perfectly. Displayed it the day it arrived.",

        when: "1d ago",
      },

      {
        user: "jules",

        stars: 5,

        text: "Got the numbered certificate too. Collector's dream.",

        when: "5d ago",
      },
    ],
  },

  {
    id: 4,

    name: "Star Wars Lightsaber Display Stand",

    price: 59,

    oldPrice: 79,

    tag: "Star Wars",

    shop: "Outer Rim Works",

    images: [
      "photo-1606041008023-472dfb5e530f",

      "photo-1472457897821-70d3819a0e24",

      "photo-1446776877081-d282a0f896e2",
    ],

    desc: "Acrylic display stand for lightsaber hilt collection. Holds up to 3 sabers with felt-lined cradles.",

    rating: 4.3,

    reviewCount: 47,

    sold: 640,

    freeShip: false,

    reviews: [
      {
        user: "PadawanKai",

        stars: 4,

        text: "Clean look, though assembly took longer than expected. Stable once set.",

        when: "6d ago",
      },

      {
        user: "neroni",

        stars: 3,

        text: "Acrylic scratches easily — handle with care. Does the job though.",

        when: "2w ago",
      },
    ],
  },

  {
    id: 5,

    name: "BTS Butter Tour Hoodie",

    price: 72,

    oldPrice: 95,

    tag: "K-Pop",

    shop: "ARMY Merch Store",

    images: [
      "photo-1556821840-3a63f15732ce",

      "photo-1571380401583-72ca84994796",

      "photo-1493711662062-fa541adb3fc8",
    ],

    desc: "Official tour merchandise hoodie. Heavyweight fleece, unisex fit, puff-print tour artwork on the back.",

    rating: 4.7,

    reviewCount: 302,

    sold: 5200,

    freeShip: true,

    flash: true,

    variants: [
      { label: "Size", options: ["S", "M", "L", "XL"] },

      { label: "Color", options: ["Cream", "Black", "Butter Yellow"] },
    ],

    reviews: [
      {
        user: "ARMY 서연",

        stars: 5,

        text: "So soft and the print hasn't cracked after 10 washes. Size up for oversized fit.",

        when: "3h ago",
      },

      {
        user: "jhopeful",

        stars: 4,

        text: "True to size, warm. Wish the drawstrings were a bit longer.",

        when: "1w ago",
      },
    ],
  },

  {
    id: 6,

    name: "One Piece Wanted Poster Set",

    price: 28,

    oldPrice: 40,

    tag: "Anime",

    shop: "Grand Line Goods",

    images: [
      "photo-1578632767115-351597cf2477",

      "photo-1612404730960-5c71577fca11",

      "photo-1581833971358-2c8b550f87b3",
    ],

    desc: "Set of 6 vintage-style wanted posters on aged parchment paper. 11×17 inches each.",

    rating: 4.5,

    reviewCount: 89,

    sold: 1900,

    freeShip: false,

    reviews: [
      {
        user: "StrawHatDan",

        stars: 5,

        text: "Aged paper effect is spot on. Pinned all six above my desk.",

        when: "2d ago",
      },

      {
        user: "nami-fan",

        stars: 4,

        text: "Great set, slightly thinner paper than I expected but the art is crisp.",

        when: "4w ago",
      },
    ],
  },

  {
    id: 7,

    name: "Apex Pro Mechanical Keyboard",

    price: 119,

    oldPrice: 149,

    tag: "Gaming",

    shop: "Frame Perfect Gear",

    images: [
      "photo-1511512578047-dfb367046420",

      "photo-1550745165-9bc0b252726f",

      "photo-1542751371-adc38448a05e",
    ],

    desc: "Hot-swappable 65% mechanical keyboard with RGB, PBT keycaps and lubed stabilizers. Wired + Bluetooth.",

    rating: 4.7,

    reviewCount: 176,

    sold: 1200,

    freeShip: true,

    variants: [
      { label: "Switch", options: ["Red", "Brown", "Blue"] },

      { label: "Layout", options: ["ANSI", "ISO"] },
    ],

    reviews: [
      {
        user: "kk_",

        stars: 5,

        text: "Sounds stock-lubed out of the box. Best board under $150, no contest.",

        when: "5d ago",
      },

      {
        user: "frameTrades",

        stars: 4,

        text: "Great feel, software could be less bloated though.",

        when: "2w ago",
      },
    ],
  },

  {
    id: 8,

    name: "Neon Genesis Evangelion Figure",

    price: 64,

    oldPrice: 89,

    tag: "Anime",

    shop: "Tokyo Figure Import",

    images: [
      "photo-1607082348824-0a96f2a4b9da",

      "photo-1531259683007-016a7b628fc3",

      "photo-1578632767115-351597cf2477",
    ],

    desc: "1/7 scale painted PVC figure with base and effect parts. Import edition with collector box.",

    rating: 4.6,

    reviewCount: 64,

    sold: 780,

    freeShip: false,

    isNew: true,

    reviews: [
      {
        user: "pilot02",

        stars: 5,

        text: "Paint application is flawless, no shading issues on mine.",

        when: "1d ago",
      },

      {
        user: "unit00",

        stars: 4,

        text: "Base is a little wobbly but the figure itself is gorgeous.",

        when: "1w ago",
      },
    ],
  },

  {
    id: 9,

    name: "Spider-Man Mask Replica",

    price: 54,

    oldPrice: 75,

    tag: "Marvel",

    shop: "Marvel Vault Official",

    images: [
      "photo-1531259683007-016a7b628fc3",

      "photo-1608889335941-32ac5f2041b9",

      "photo-1612036782180-6f0b6cd846fe",
    ],

    desc: "Wearable half-mask with magnetic lenses and adjustable strap. Fits most teen and adult heads.",

    rating: 4.8,

    reviewCount: 143,

    sold: 2800,

    freeShip: true,

    reviews: [
      {
        user: "webhead",

        stars: 5,

        text: "The magnetic lenses are so satisfying to swap. Great for cons.",

        when: "3d ago",
      },

      {
        user: "mj_",

        stars: 5,

        text: "Comfortable enough to wear all day, ventilation is decent.",

        when: "1w ago",
      },
    ],
  },

  {
    id: 10,

    name: "K-Pop Photocard Collector Binder",

    price: 24,

    oldPrice: 35,

    tag: "K-Pop",

    shop: "ARMY Merch Store",

    images: [
      "photo-1493711662062-fa541adb3fc8",

      "photo-1493225457124-a3eb161ffa5f",

      "photo-1571380401583-72ca84994796",
    ],

    desc: "60-pocket A5 binder with 4 removable sleeves, PU cover and a pen loop. Fits standard photocard size.",

    rating: 4.9,

    reviewCount: 412,

    sold: 6400,

    freeShip: true,

    variants: [{ label: "Cover", options: ["Lavender", "Midnight", "Blush"] }],

    reviews: [
      {
        user: "sana.archive",

        stars: 5,

        text: "Pockets are snug so cards don't slide out. Bought two.",

        when: "6h ago",
      },

      {
        user: "carat",

        stars: 5,

        text: "Exactly the size I needed and the rings don't snag cards.",

        when: "5d ago",
      },
    ],
  },

  {
    id: 11,

    name: "Mandalorian Beskar Coin Set",

    price: 39,

    oldPrice: 55,

    tag: "Star Wars",

    shop: "Outer Rim Works",

    images: [
      "photo-1446776877081-d282a0f896e2",

      "photo-1472457897821-70d3819a0e24",

      "photo-1606041008023-472dfb5e530f",
    ],

    desc: "Set of 3 antique-finish metal coins with magnetic display case. Die-struck details, 40mm each.",

    rating: 4.5,

    reviewCount: 52,

    sold: 1100,

    freeShip: false,

    isNew: true,

    reviews: [
      {
        user: "bountyhunter",

        stars: 5,

        text: "Heavier than expected in the best way. Case is a nice touch.",

        when: "2d ago",
      },

      {
        user: "din_fan",

        stars: 4,

        text: "Finish is great, wish it came with four coins instead of three.",

        when: "3w ago",
      },
    ],
  },

  {
    id: 12,

    name: "Retro Wireless Controller",

    price: 45,

    oldPrice: 60,

    tag: "Gaming",

    shop: "Frame Perfect Gear",

    images: [
      "photo-1550745165-9bc0b252726f",

      "photo-1511512578047-dfb367046420",

      "photo-1542751371-adc38448a05e",
    ],

    desc: "Low-latency wireless controller with Hall effect sticks, 2.4GHz dongle and 30-hour battery.",

    rating: 4.4,

    reviewCount: 231,

    sold: 3300,

    freeShip: true,

    flash: true,

    variants: [
      { label: "Color", options: ["Grey", "Transparent Purple", "Coral"] },
    ],

    reviews: [
      {
        user: "speedrun_j",

        stars: 5,

        text: "No drift after three months of daily use. D-pad is snappy.",

        when: "4d ago",
      },

      {
        user: "pixel",

        stars: 4,

        text: "Bluetooth pairing is easy, dongle storage is a bit tight.",

        when: "2w ago",
      },
    ],
  },

  {
    id: 13,

    name: "Berserk Manga Box Set (Vol. 1-12)",

    price: 68,

    oldPrice: 92,

    tag: "Comics",

    shop: "Panel & Ink",

    images: [
      "photo-1612404730960-5c71577fca11",

      "photo-1578632767115-351597cf2477",

      "photo-1611532736597-de2d4265fba3",
    ],

    desc: "Collector box set of volumes 1-12 with exclusive bookmark set. English translation, unread condition.",

    rating: 4.9,

    reviewCount: 96,

    sold: 1500,

    freeShip: true,

    reviews: [
      {
        user: "gutscore",

        stars: 5,

        text: "Print quality is way better than the singles. Box is sturdy too.",

        when: "1d ago",
      },

      {
        user: "miura_fan",

        stars: 5,

        text: "Arrived without a single bent corner. Packaging was solid.",

        when: "1w ago",
      },
    ],
  },

  {
    id: 14,

    name: "Watchmen Deluxe Graphic Novel",

    price: 32,

    oldPrice: 45,

    tag: "Comics",

    shop: "Panel & Ink",

    images: [
      "photo-1611532736597-de2d4265fba3",

      "photo-1612404730960-5c71577fca11",

      "photo-1607082348824-0a96f2a4b9da",
    ],

    desc: "Hardcover deluxe edition with restored coloring, bonus sketches and a sewn binding that lays flat.",

    rating: 4.6,

    reviewCount: 74,

    sold: 990,

    freeShip: false,

    isNew: true,

    reviews: [
      {
        user: "owl_ship",

        stars: 5,

        text: "Binding lays flat, colors are rich. Best edition to own.",

        when: "3d ago",
      },

      {
        user: "panelbeat",

        stars: 4,

        text: "Dust jacket is glossy, but the book itself is perfect.",

        when: "2w ago",
      },
    ],
  },
]

type Tile = {
  key: string

  label: string

  emoji: string
}

const tiles: Tile[] = [
  { key: "All", label: "All", emoji: "🛍️" },

  { key: "Anime", label: "Anime", emoji: "⛩️" },

  { key: "Gaming", label: "Gaming", emoji: "🎮" },

  { key: "Marvel", label: "Marvel", emoji: "🕷️" },

  { key: "Star Wars", label: "Star Wars", emoji: "⚔️" },

  { key: "K-Pop", label: "K-Pop", emoji: "🎤" },

  { key: "Comics", label: "Comics", emoji: "📚" },

  { key: "Deals", label: "Deals", emoji: "⚡" },

  { key: "New", label: "New", emoji: "✨" },
]

type Voucher = {
  id: string

  label: string

  amount: number

  min: number

  shipping?: boolean
}

const vouchers: Voucher[] = [
  { id: "v1", label: "$10 off orders $50+", amount: 10, min: 50 },

  { id: "v2", label: "$5 off any order", amount: 5, min: 0 },

  { id: "v3", label: "Free shipping", amount: 0, min: 0, shipping: true },
]

const payments = ["Card •••• 4242", "Apple Pay", "PayPal", "Fandom Wallet"]

type CartLine = {
  id: number

  qty: number

  variant: string

  checked: boolean
}

type View = "home" | "detail" | "cart" | "checkout" | "confirmed"

type Sort = "popular" | "selling" | "price"

const byId = (id: number) => products.find((p) => p.id === id)!

const newOrderId = () => `#FV-${Math.floor(100000 + Math.random() * 899999)}`

const shopGroups = (lines: CartLine[]) =>
  Array.from(
    lines

      .reduce((m, l) => {
        const s = byId(l.id).shop

        m.set(s, [...(m.get(s) ?? []), l])

        return m
      }, new Map<string, CartLine[]>())

      .entries(),
  )

type StarsProps = {
  value: number

  size?: number
}

function Stars({ value, size = 12 }: StarsProps) {
  return (
    <span style={{ display: "inline-flex", gap: 1, alignItems: "center" }}>
      {[1, 2, 3, 4, 5].map((i) => (
        <Star
          key={i}
          size={size}
          fill={i <= Math.round(value) ? GOLD : "transparent"}
          stroke={i <= Math.round(value) ? GOLD : "var(--border-3)"}
          strokeWidth={2}
        />
      ))}
    </span>
  )
}

function Countdown({ seconds }: { seconds: number }) {
  const h = Math.floor(seconds / 3600)

  const m = Math.floor((seconds % 3600) / 60)

  const s = seconds % 60

  const box = (v: number, k: string) => (
    <span
      key={k}
      style={{
        background: "var(--app-bg-deep)",

        border: `1px solid ${BORDER}`,

        borderRadius: 6,

        padding: "3px 5px",

        fontFamily: "Space Grotesk, sans-serif",

        fontWeight: 700,

        fontSize: 13,

        color: TEXT,

        minWidth: 26,

        textAlign: "center",

        display: "inline-block",
      }}
    >
      {String(v).padStart(2, "0")}
    </span>
  )

  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: 3 }}>
      {box(h, "h")}
      <span style={{ color: CORAL, fontWeight: 700 }}>:</span>
      {box(m, "m")}
      <span style={{ color: CORAL, fontWeight: 700 }}>:</span>
      {box(s, "s")}
    </span>
  )
}

function Stepper({
  value,

  onChange,
}: {
  value: number

  onChange: (n: number) => void
}) {
  const btn = {
    width: 26,

    height: 26,

    display: "flex",

    alignItems: "center",

    justifyContent: "center",

    background: SURFACE2,

    border: `1px solid ${BORDER}`,

    borderRadius: 6,

    cursor: "pointer",

    color: TEXT,

    padding: 0,
  } as const

  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: 8 }}>
      <button
        style={btn}
        onClick={() => onChange(value - 1)}
        aria-label="Decrease"
      >
        <Minus size={13} />
      </button>
      <span
        style={{
          fontFamily: "Space Grotesk, sans-serif",

          fontSize: 13,

          fontWeight: 600,

          color: TEXT,

          minWidth: 16,

          textAlign: "center",
        }}
      >
        {value}
      </span>
      <button
        style={btn}
        onClick={() => onChange(value + 1)}
        aria-label="Increase"
      >
        <Plus size={13} />
      </button>
    </span>
  )
}

function Checkbox({
  checked,

  onClick,
}: {
  checked: boolean

  onClick: (e: React.MouseEvent) => void
}) {
  return (
    <button
      onClick={onClick}
      aria-label={checked ? "Deselect" : "Select"}
      style={{
        width: 20,

        height: 20,

        borderRadius: "50%",

        flexShrink: 0,

        background: checked ? VIOLET : "transparent",

        border: `1.5px solid ${checked ? VIOLET : "var(--border-3)"}`,

        cursor: "pointer",

        display: "flex",

        alignItems: "center",

        justifyContent: "center",

        padding: 0,

        color: "#fff",
      }}
    >
      {checked && <Check size={12} strokeWidth={3} />}
    </button>
  )
}

export default function ShopTab() {
  const [view, setView] = useState<View>("home")

  const [selected, setSelected] = useState<Product | null>(null)

  const [cart, setCart] = useState<CartLine[]>([])

  const [wishlist, setWishlist] = useState<Set<number>>(new Set())

  const [query, setQuery] = useState("")

  const [activeTag, setActiveTag] = useState("All")

  const [sort, setSort] = useState<Sort>("popular")

  const [priceAsc, setPriceAsc] = useState(true)

  const [galleryIdx, setGalleryIdx] = useState(0)

  const [picked, setPicked] = useState<string[]>([])

  const [claimed, setClaimed] = useState<Set<string>>(new Set())

  const [myStars, setMyStars] = useState<Record<number, number>>({})

  const [myReview, setMyReview] = useState<Record<number, Review>>({})

  const [draftStars, setDraftStars] = useState(0)

  const [draftText, setDraftText] = useState("")

  const [editCart, setEditCart] = useState(false)

  const [cartVoucher, setCartVoucher] = useState<string | null>(null)

  const [payment, setPayment] = useState(payments[0])

  const [toast, setToast] = useState<string | null>(null)

  const [flash, setFlash] = useState(2 * 3600 + 14 * 60 + 33)

  const [orderId, setOrderId] = useState(() => newOrderId())

  useEffect(() => {
    const t = setInterval(() => setFlash((s) => (s > 0 ? s - 1 : 0)), 1000)

    return () => clearInterval(t)
  }, [])

  useEffect(() => {
    if (!toast) return

    const t = setTimeout(() => setToast(null), 1800)

    return () => clearTimeout(t)
  }, [toast])

  const cartCount = useMemo(() => cart.reduce((s, l) => s + l.qty, 0), [cart])

  const checkedLines = cart.filter((l) => l.checked)

  const subtotal = checkedLines.reduce(
    (s, l) => s + byId(l.id).price * l.qty,

    0,
  )

  const voucher = vouchers.find((v) => v.id === cartVoucher) ?? null

  const discount =
    voucher && voucher.amount > 0 && subtotal >= voucher.min
      ? Math.min(voucher.amount, subtotal)
      : 0

  const baseShipping = subtotal >= 100 ? 0 : 4.99

  const shipping =
    subtotal === 0
      ? 0
      : voucher?.shipping
        ? 0
        : checkedLines.every((l) => byId(l.id).freeShip)
          ? 0
          : baseShipping

  const total = Math.max(0, subtotal - discount + shipping)

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()

    let list = products.filter((p) => {
      const matchQuery =
        !q ||
        p.name.toLowerCase().includes(q) ||
        p.tag.toLowerCase().includes(q) ||
        p.shop.toLowerCase().includes(q) ||
        p.desc.toLowerCase().includes(q)

      let matchTag = true

      if (activeTag === "Deals") matchTag = p.price < 50
      else if (activeTag === "New") matchTag = !!p.isNew
      else if (activeTag !== "All") matchTag = p.tag === activeTag

      return matchQuery && matchTag
    })

    list = [...list]

    if (sort === "selling") list.sort((a, b) => b.sold - a.sold)
    else if (sort === "price")
      list.sort((a, b) => (priceAsc ? a.price - b.price : b.price - a.price))
    else list.sort((a, b) => b.rating * b.sold - a.rating * a.sold)

    return list
  }, [query, activeTag, sort, priceAsc])

  const toggleWish = (id: number) => {
    const had = wishlist.has(id)

    setWishlist((s) => {
      const n = new Set(s)

      if (had) n.delete(id)
      else n.add(id)

      return n
    })

    setToast(had ? "Removed from saved" : "Saved to your list")
  }

  const addLine = (p: Product, variant: string, qty = 1) => {
    setCart((c) => {
      const i = c.findIndex((l) => l.id === p.id && l.variant === variant)

      if (i >= 0) {
        const n = [...c]

        n[i] = { ...n[i], qty: n[i].qty + qty, checked: true }

        return n
      }

      return [...c, { id: p.id, qty, variant, checked: true }]
    })
  }

  const quickAdd = (p: Product, e: React.MouseEvent) => {
    e.stopPropagation()

    const variant = p.variants?.map((v) => v.options[0]).join(" / ") ?? ""

    addLine(p, variant)

    setToast("Added to cart")
  }

  const openDetail = (p: Product) => {
    setSelected(p)

    setPicked(p.variants?.map((v) => v.options[0]) ?? [])

    setGalleryIdx(0)

    setDraftStars(myStars[p.id] ?? 0)

    setDraftText("")

    setView("detail")
  }

  const visibleReviews = (p: Product) =>
    myReview[p.id] ? [myReview[p.id], ...p.reviews] : p.reviews

  const submitReview = () => {
    if (!selected || draftStars < 1) return

    setMyStars((s) => ({ ...s, [selected.id]: draftStars }))

    if (draftText.trim()) {
      setMyReview((s) => ({
        ...s,

        [selected.id]: {
          user: "You",

          stars: draftStars,

          text: draftText.trim(),

          when: "just now",
        },
      }))
    }

    setDraftText("")

    setToast("Review posted")
  }

  const buyNow = () => {
    if (!selected) return

    addLine(selected, selected.variants ? picked.join(" / ") : "", 1)

    setCart((c) =>
      c.map((l) =>
        l.id === selected.id
          ? { ...l, checked: true }
          : { ...l, checked: false },
      ),
    )

    setView("checkout")
  }

  const setQty = (idx: number, qty: number) => {
    if (qty < 1) {
      setCart((c) => c.filter((_, i) => i !== idx))

      return
    }

    setCart((c) => c.map((l, i) => (i === idx ? { ...l, qty } : l)))
  }

  const headerBg = {
    background: BG,

    boxShadow: "0 10px 20px -14px rgba(0,0,0,0.9)",
  }

  const pageHeader = (
    title: string,

    right?: React.ReactNode,

    onBack?: () => void,
  ) => (
    <div
      className="flex items-center gap-2 px-4 pt-12 pb-3"
      style={{ flexShrink: 0, ...headerBg }}
    >
      {onBack && (
        <button
          onClick={onBack}
          aria-label="Back"
          style={{
            background: "none",

            border: "none",

            color: TEXT,

            cursor: "pointer",

            display: "flex",

            padding: 0,
          }}
        >
          <ChevronLeft size={22} />
        </button>
      )}
      <h2
        style={{
          fontFamily: "Space Grotesk, sans-serif",

          fontSize: 18,

          fontWeight: 700,

          color: TEXT,

          margin: 0,

          flex: 1,
        }}
      >
        {title}
      </h2>
      {right}
    </div>
  )

  const cartBadge = (size = 20) => (
    <span
      style={{
        position: "absolute",

        top: -5,

        right: -5,

        minWidth: size,

        height: size,

        padding: "0 4px",

        borderRadius: size / 2,

        background: CORAL,

        color: "#fff",

        fontSize: 10,

        fontWeight: 700,

        display: "flex",

        alignItems: "center",

        justifyContent: "center",

        fontFamily: "Inter, sans-serif",

        border: `2px solid ${BG}`,
      }}
    >
      {cartCount > 99 ? "99+" : cartCount}
    </span>
  )

  const toggleVoucher = (v: Voucher) => {
    const wasOn = claimed.has(v.id)

    setClaimed((s) => {
      const n = new Set(s)

      if (n.has(v.id)) n.delete(v.id)
      else n.add(v.id)

      return n
    })

    if (!wasOn) {
      setCartVoucher(v.id)

      setToast("Voucher applied at checkout")
    }
  }

  /* ------------------------------- CATALOG ------------------------------ */

  const renderHome = () => {
    const sortBtn = (key: Sort, label: string) => (
      <button
        key={key}
        onClick={() => setSort(key)}
        style={{
          flexShrink: 0,

          background: sort === key ? "rgba(124,92,255,0.14)" : "transparent",

          color: sort === key ? VIOLET : MUTED,

          border: "none",

          borderRadius: 999,

          padding: "5px 9px",

          fontSize: 11,

          fontWeight: 600,

          fontFamily: "Inter, sans-serif",

          cursor: "pointer",

          whiteSpace: "nowrap",
        }}
      >
        {label}
      </button>
    )

    return (
      <div className="flex flex-col h-full" style={{ background: BG }}>
        <div
          className="flex items-center gap-2.5 px-4 pt-12 pb-3"
          style={headerBg}
        >
          <div
            style={{
              flex: 1,

              display: "flex",

              alignItems: "center",

              gap: 8,

              background: SURFACE2,

              border: `1px solid ${BORDER}`,

              borderRadius: 999,

              padding: "9px 14px",

              minWidth: 0,
            }}
          >
            <Search size={15} color={MUTED} style={{ flexShrink: 0 }} />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search fandom merch"
              style={{
                flex: 1,

                minWidth: 0,

                background: "none",

                border: "none",

                outline: "none",

                color: TEXT,

                fontSize: 13,

                fontFamily: "Inter, sans-serif",
              }}
            />
            {query && (
              <button
                onClick={() => setQuery("")}
                aria-label="Clear"
                style={{
                  background: "none",

                  border: "none",

                  color: MUTED,

                  cursor: "pointer",

                  display: "flex",

                  padding: 0,
                }}
              >
                <X size={14} />
              </button>
            )}
          </div>
          <button
            onClick={() => setView("cart")}
            aria-label="Cart"
            style={{
              position: "relative",

              width: 38,

              height: 38,

              borderRadius: "50%",

              background: SURFACE2,

              border: `1px solid ${BORDER}`,

              display: "flex",

              alignItems: "center",

              justifyContent: "center",

              cursor: "pointer",

              color: TEXT,

              flexShrink: 0,
            }}
          >
            <ShoppingCart size={17} />
            {cartCount > 0 && cartBadge(17)}
          </button>
        </div>

        <div className="flex-1 overflow-y-auto">
          {/* Category tiles */}
          <div
            style={{
              display: "grid",

              gridTemplateColumns: "repeat(5, 1fr)",

              gap: "14px 4px",

              padding: "6px 12px 4px",
            }}
          >
            {tiles.map((t) => {
              const active = activeTag === t.key

              return (
                <button
                  key={t.key}
                  onClick={() => setActiveTag(t.key)}
                  style={{
                    display: "flex",

                    flexDirection: "column",

                    alignItems: "center",

                    gap: 6,

                    background: "none",

                    border: "none",

                    cursor: "pointer",

                    padding: 0,
                  }}
                >
                  <span
                    style={{
                      width: 46,

                      height: 46,

                      borderRadius: "50%",

                      display: "flex",

                      alignItems: "center",

                      justifyContent: "center",

                      fontSize: 20,

                      lineHeight: 1,

                      background: active ? "rgba(124,92,255,0.16)" : SURFACE2,

                      border: active
                        ? `2px solid ${VIOLET}`
                        : `1px solid ${BORDER}`,
                    }}
                  >
                    {t.emoji}
                  </span>
                  <span
                    style={{
                      fontSize: 10,

                      color: active ? TEXT : MUTED,

                      fontWeight: active ? 600 : 400,

                      fontFamily: "Inter, sans-serif",

                      maxWidth: 62,

                      overflow: "hidden",

                      textOverflow: "ellipsis",

                      whiteSpace: "nowrap",
                    }}
                  >
                    {t.label}
                  </span>
                </button>
              )
            })}
          </div>

          {/* Flash sale */}
          <div
            style={{
              margin: "12px 16px 0",

              padding: "12px 14px 13px",

              background: SURFACE,

              border: "1px solid rgba(255,107,92,0.35)",

              borderRadius: 14,
            }}
          >
            <div
              style={{
                display: "flex",

                alignItems: "center",

                justifyContent: "space-between",

                gap: 10,
              }}
            >
              <div>
                <div
                  style={{
                    display: "flex",

                    alignItems: "center",

                    gap: 6,

                    fontFamily: "Space Grotesk, sans-serif",

                    fontSize: 15,

                    fontWeight: 700,

                    color: TEXT,
                  }}
                >
                  ⚡ Flash Sale
                </div>
                <div style={{ fontSize: 11, color: MUTED, marginTop: 2 }}>
                  Up to 40% off · ends in
                </div>
              </div>
              <Countdown seconds={flash} />
            </div>
            <div
              style={{
                marginTop: 10,

                height: 6,

                borderRadius: 3,

                background: "var(--app-bg-deep)",

                overflow: "hidden",
              }}
            >
              <div
                style={{
                  width: "68%",

                  height: "100%",

                  background: CORAL,

                  borderRadius: 3,
                }}
              />
            </div>
            <div
              style={{
                display: "flex",

                justifyContent: "space-between",

                marginTop: 6,

                fontSize: 10,

                color: MUTED,
              }}
            >
              <span>Claimed 68%</span>
              <span style={{ color: CORAL, fontWeight: 600 }}>162 left</span>
            </div>
          </div>

          {/* Vouchers */}
          <div
            className="flex gap-2.5 overflow-x-auto"
            style={{ padding: "12px 16px 4px", scrollbarWidth: "none" }}
          >
            {vouchers.map((v) => {
              const on = claimed.has(v.id)

              return (
                <button
                  key={v.id}
                  onClick={() => toggleVoucher(v)}
                  style={{
                    flexShrink: 0,

                    display: "flex",

                    alignItems: "center",

                    gap: 6,

                    background: on
                      ? "rgba(124,92,255,0.12)"
                      : "rgba(255,107,92,0.1)",

                    border: `1px dashed ${
                      on ? VIOLET : "rgba(255,107,92,0.55)"
                    }`,

                    borderRadius: 8,

                    padding: "7px 11px",

                    color: on ? VIOLET : CORAL,

                    fontSize: 11,

                    fontWeight: 600,

                    fontFamily: "Inter, sans-serif",

                    cursor: "pointer",

                    whiteSpace: "nowrap",
                  }}
                >
                  <Ticket size={13} />
                  {v.label}
                  <span style={{ opacity: 0.85, fontWeight: 700 }}>
                    {on ? "Claimed" : "Claim"}
                  </span>
                </button>
              )
            })}
          </div>

          {/* Feed header */}
          <div
            className="flex items-center justify-between"
            style={{ padding: "10px 12px 8px" }}
          >
            <span
              style={{
                fontFamily: "Space Grotesk, sans-serif",

                fontSize: 15,

                fontWeight: 700,

                color: TEXT,
              }}
            >
              {activeTag === "All" ? "For You" : activeTag}
            </span>
            <div style={{ display: "flex", alignItems: "center", gap: 2 }}>
              {sortBtn("popular", "Top picks")}
              {sortBtn("selling", "Best selling")}
              <button
                onClick={() => {
                  if (sort === "price") setPriceAsc((v) => !v)
                  else {
                    setSort("price")

                    setPriceAsc(true)
                  }
                }}
                style={{
                  display: "flex",

                  alignItems: "center",

                  gap: 3,

                  background:
                    sort === "price" ? "rgba(124,92,255,0.14)" : "transparent",

                  color: sort === "price" ? VIOLET : MUTED,

                  border: "none",

                  borderRadius: 999,

                  padding: "5px 9px",

                  fontSize: 11,

                  fontWeight: 600,

                  fontFamily: "Inter, sans-serif",

                  cursor: "pointer",
                }}
              >
                Price
                {sort === "price" &&
                  (priceAsc ? <ArrowUp size={12} /> : <ArrowDown size={12} />)}
              </button>
            </div>
          </div>

          {/* Product grid */}
          <div
            style={{
              display: "grid",

              gridTemplateColumns: "1fr 1fr",

              gap: 10,

              padding: "0 12px 28px",
            }}
          >
            {filtered.length === 0 && (
              <div
                style={{
                  gridColumn: "1 / -1",

                  textAlign: "center",

                  padding: "40px 16px",

                  color: MUTED,

                  fontSize: 13,

                  lineHeight: 1.6,
                }}
              >
                <div style={{ fontSize: 34, marginBottom: 8 }}>🔍</div>
                Nothing matches “{query || activeTag}”.
                <br />
                Try another keyword or category.
              </div>
            )}
            {filtered.map((p) => {
              const saved = wishlist.has(p.id)

              return (
                <div
                  key={p.id}
                  onClick={() => openDetail(p)}
                  style={{
                    background: SURFACE,

                    borderRadius: 12,

                    overflow: "hidden",

                    border: `1px solid ${BORDER}`,

                    cursor: "pointer",

                    display: "flex",

                    flexDirection: "column",
                  }}
                >
                  <div
                    style={{
                      position: "relative",

                      height: 148,

                      background: SURFACE2,
                    }}
                  >
                    <img
                      src={u(p.images[0], 400, 400)}
                      alt={p.name}
                      style={{
                        width: "100%",

                        height: "100%",

                        objectFit: "cover",
                      }}
                    />
                    <span
                      style={{
                        position: "absolute",

                        top: 8,

                        left: 8,

                        background: CORAL,

                        color: "#fff",

                        fontSize: 10,

                        fontWeight: 700,

                        padding: "2px 6px",

                        borderRadius: 5,

                        fontFamily: "Inter, sans-serif",
                      }}
                    >
                      −{off(p.price, p.oldPrice)}%
                    </span>
                    <button
                      onClick={(e) => {
                        e.stopPropagation()

                        toggleWish(p.id)
                      }}
                      aria-label="Save"
                      style={{
                        position: "absolute",

                        top: 6,

                        right: 6,

                        width: 28,

                        height: 28,

                        borderRadius: "50%",

                        background: "rgba(10,10,12,0.55)",

                        border: "none",

                        display: "flex",

                        alignItems: "center",

                        justifyContent: "center",

                        cursor: "pointer",

                        color: saved ? CORAL : "#fff",

                        padding: 0,
                      }}
                    >
                      <Heart size={14} fill={saved ? CORAL : "transparent"} />
                    </button>
                    <span
                      style={{
                        position: "absolute",

                        left: 8,

                        bottom: 8,

                        background: "rgba(10,10,12,0.72)",

                        color: "#fff",

                        fontSize: 10,

                        fontWeight: 600,

                        padding: "3px 7px",

                        borderRadius: 999,

                        fontFamily: "Inter, sans-serif",
                      }}
                    >
                      {compact(p.sold)}+ sold
                    </span>
                    <button
                      onClick={(e) => quickAdd(p, e)}
                      aria-label="Add to cart"
                      style={{
                        position: "absolute",

                        right: 8,

                        bottom: 8,

                        width: 30,

                        height: 30,

                        borderRadius: "50%",

                        background: VIOLET,

                        border: "none",

                        display: "flex",

                        alignItems: "center",

                        justifyContent: "center",

                        cursor: "pointer",

                        color: "#fff",

                        padding: 0,

                        boxShadow: "0 4px 12px rgba(124,92,255,0.45)",
                      }}
                    >
                      <ShoppingCart size={14} />
                    </button>
                  </div>
                  <div style={{ padding: "8px 9px 10px" }}>
                    <p
                      style={{
                        fontSize: 12.5,

                        fontWeight: 500,

                        color: TEXT,

                        margin: 0,

                        lineHeight: 1.35,

                        height: 34,

                        overflow: "hidden",

                        display: "-webkit-box",

                        WebkitLineClamp: 2,

                        WebkitBoxOrient: "vertical",
                      }}
                    >
                      {p.name}
                    </p>
                    <div
                      style={{
                        display: "flex",

                        alignItems: "baseline",

                        gap: 5,

                        marginTop: 5,
                      }}
                    >
                      <span
                        style={{
                          fontFamily: "Space Grotesk, sans-serif",

                          fontSize: 16,

                          fontWeight: 700,

                          color: CORAL,
                        }}
                      >
                        {money(p.price)}
                      </span>
                      <span
                        style={{
                          fontSize: 11,

                          color: "var(--muted-3)",

                          textDecoration: "line-through",
                        }}
                      >
                        {money(p.oldPrice)}
                      </span>
                    </div>
                    <div
                      style={{
                        display: "flex",

                        alignItems: "center",

                        gap: 4,

                        marginTop: 4,
                      }}
                    >
                      <Stars value={p.rating} size={10} />
                      <span style={{ fontSize: 10.5, color: MUTED }}>
                        {p.rating.toFixed(1)} · {compact(p.reviewCount)} reviews
                      </span>
                    </div>
                    <div
                      style={{
                        display: "flex",

                        alignItems: "center",

                        justifyContent: "space-between",

                        gap: 6,

                        marginTop: 6,
                      }}
                    >
                      <span
                        style={{
                          display: "flex",

                          alignItems: "center",

                          gap: 4,

                          fontSize: 10,

                          color: MUTED,

                          minWidth: 0,

                          overflow: "hidden",

                          whiteSpace: "nowrap",

                          textOverflow: "ellipsis",
                        }}
                      >
                        <Store size={11} style={{ flexShrink: 0 }} />
                        {p.shop}
                      </span>
                      {p.freeShip && (
                        <span
                          style={{
                            flexShrink: 0,

                            fontSize: 9,

                            fontWeight: 700,

                            color: "#4ade80",

                            background: "rgba(74,222,128,0.12)",

                            padding: "2px 5px",

                            borderRadius: 4,
                          }}
                        >
                          FREE SHIP
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              )
            })}
          </div>

          <div
            style={{
              textAlign: "center",

              fontSize: 11,

              color: "var(--muted-3)",

              padding: "0 0 20px",
            }}
          >
            — you're all caught up ✦ —
          </div>
        </div>
      </div>
    )
  }

  /* ---------------------------- PRODUCT DETAIL --------------------------- */

  const renderDetail = () => {
    if (!selected) return null

    const p = selected

    const saved = wishlist.has(p.id)

    const rc = p.reviewCount + (myReview[p.id] ? 1 : 0)

    return (
      <div className="flex flex-col h-full" style={{ background: BG }}>
        <div className="flex-1 overflow-y-auto">
          {/* Gallery */}
          <div style={{ position: "relative" }}>
            <div
              onScroll={(e) => {
                const el = e.currentTarget

                setGalleryIdx(Math.round(el.scrollLeft / el.clientWidth))
              }}
              style={{
                display: "flex",

                overflowX: "auto",

                scrollSnapType: "x mandatory",

                scrollbarWidth: "none",

                height: 300,

                background: SURFACE2,
              }}
            >
              {p.images.map((img) => (
                <img
                  key={img}
                  src={u(img, 780, 780)}
                  alt={p.name}
                  style={{
                    width: "100%",

                    flexShrink: 0,

                    scrollSnapAlign: "start",

                    objectFit: "cover",

                    height: 300,
                  }}
                />
              ))}
            </div>
            <button
              onClick={() => setView("home")}
              aria-label="Back"
              style={{
                position: "absolute",

                top: 52,

                left: 14,

                width: 34,

                height: 34,

                borderRadius: "50%",

                background: "rgba(10,10,12,0.55)",

                border: "none",

                color: "#fff",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                cursor: "pointer",

                padding: 0,
              }}
            >
              <ChevronLeft size={19} />
            </button>
            <button
              aria-label="Share"
              style={{
                position: "absolute",

                top: 52,

                right: 56,

                width: 34,

                height: 34,

                borderRadius: "50%",

                background: "rgba(10,10,12,0.55)",

                border: "none",

                color: "#fff",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                cursor: "pointer",

                padding: 0,
              }}
            >
              <Share2 size={16} />
            </button>
            <button
              onClick={() => toggleWish(p.id)}
              aria-label="Save"
              style={{
                position: "absolute",

                top: 52,

                right: 14,

                width: 34,

                height: 34,

                borderRadius: "50%",

                background: "rgba(10,10,12,0.55)",

                border: "none",

                color: saved ? CORAL : "#fff",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                cursor: "pointer",

                padding: 0,
              }}
            >
              <Heart size={16} fill={saved ? CORAL : "transparent"} />
            </button>
            <span
              style={{
                position: "absolute",

                right: 14,

                bottom: 12,

                background: "rgba(10,10,12,0.7)",

                color: "#fff",

                fontSize: 11,

                fontWeight: 600,

                padding: "3px 9px",

                borderRadius: 999,
              }}
            >
              {galleryIdx + 1}/{p.images.length}
            </span>
            <span
              style={{
                position: "absolute",

                left: 14,

                bottom: 12,

                display: "flex",

                gap: 5,
              }}
            >
              {p.images.map((img, i) => (
                <span
                  key={img}
                  style={{
                    width: i === galleryIdx ? 16 : 6,

                    height: 6,

                    borderRadius: 3,

                    background:
                      i === galleryIdx ? CORAL : "rgba(255,255,255,0.5)",

                    transition: "width 0.2s ease",
                  }}
                />
              ))}
            </span>
          </div>

          {/* Price block */}
          <div style={{ padding: "14px 16px 0" }}>
            <div
              style={{
                display: "flex",

                alignItems: "flex-end",

                gap: 8,

                flexWrap: "wrap",
              }}
            >
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 28,

                  fontWeight: 700,

                  color: CORAL,

                  lineHeight: 1,
                }}
              >
                {money(p.price)}
              </span>
              <span
                style={{
                  fontSize: 13,

                  color: "var(--muted-3)",

                  textDecoration: "line-through",
                }}
              >
                {money(p.oldPrice)}
              </span>
              <span
                style={{
                  background: CORAL,

                  color: "#fff",

                  fontSize: 11,

                  fontWeight: 700,

                  padding: "2px 7px",

                  borderRadius: 5,
                }}
              >
                −{off(p.price, p.oldPrice)}%
              </span>
              {p.flash && (
                <span
                  style={{
                    display: "flex",

                    alignItems: "center",

                    gap: 6,

                    marginLeft: "auto",

                    fontSize: 11,

                    color: MUTED,
                  }}
                >
                  ⚡ ends in <Countdown seconds={flash} />
                </span>
              )}
            </div>
            <div
              style={{
                display: "flex",

                alignItems: "center",

                gap: 8,

                marginTop: 8,

                flexWrap: "wrap",
              }}
            >
              <span style={{ display: "flex", alignItems: "center", gap: 4 }}>
                <Stars value={p.rating} size={12} />
                <span style={{ fontSize: 12, color: TEXT, fontWeight: 600 }}>
                  {p.rating.toFixed(1)}
                </span>
              </span>
              <span style={{ fontSize: 12, color: MUTED }}>{rc} reviews</span>
              <span style={{ fontSize: 12, color: MUTED }}>
                · {compact(p.sold)} sold
              </span>
              <span
                style={{
                  marginLeft: "auto",

                  fontSize: 11,

                  fontWeight: 700,

                  color: "#4ade80",

                  background: "rgba(74,222,128,0.12)",

                  padding: "3px 8px",

                  borderRadius: 5,
                }}
              >
                {p.freeShip ? "FREE SHIPPING" : "SHIPS IN 24H"}
              </span>
            </div>
            <p
              style={{
                fontSize: 14,

                fontWeight: 600,

                color: TEXT,

                lineHeight: 1.45,

                margin: "12px 0 0",
              }}
            >
              {p.name}
            </p>
          </div>

          {/* Vouchers */}
          <div
            className="flex gap-2.5 overflow-x-auto"
            style={{ padding: "14px 16px 0", scrollbarWidth: "none" }}
          >
            {vouchers.map((v) => {
              const on = claimed.has(v.id)

              return (
                <button
                  key={v.id}
                  onClick={() => toggleVoucher(v)}
                  style={{
                    flexShrink: 0,

                    display: "flex",

                    alignItems: "center",

                    gap: 6,

                    background: on
                      ? "rgba(124,92,255,0.12)"
                      : "rgba(255,107,92,0.1)",

                    border: `1px dashed ${
                      on ? VIOLET : "rgba(255,107,92,0.55)"
                    }`,

                    borderRadius: 8,

                    padding: "6px 10px",

                    color: on ? VIOLET : CORAL,

                    fontSize: 11,

                    fontWeight: 600,

                    cursor: "pointer",

                    whiteSpace: "nowrap",
                  }}
                >
                  <Ticket size={12} />
                  {v.label}
                  <span style={{ fontWeight: 700 }}>
                    {on ? "Claimed" : "Claim"}
                  </span>
                </button>
              )
            })}
          </div>

          {/* Shipping row */}
          <div
            style={{
              margin: "14px 16px 0",

              background: SURFACE,

              border: `1px solid ${BORDER}`,

              borderRadius: 12,

              overflow: "hidden",
            }}
          >
            <div
              style={{
                display: "flex",

                alignItems: "center",

                gap: 10,

                padding: "12px 14px",

                borderBottom: `1px solid ${BORDER}`,
              }}
            >
              <Truck size={15} color={VIOLET} />
              <span style={{ fontSize: 12.5, color: TEXT, flex: 1 }}>
                {p.freeShip ? "Free shipping" : "Shipping $4.99"} · Delivery in
                3–5 days
              </span>
              <ChevronRight size={15} color={MUTED} />
            </div>
            <div
              style={{
                display: "flex",

                alignItems: "center",

                gap: 10,

                padding: "12px 14px",
              }}
            >
              <Store size={15} color={VIOLET} />
              <span style={{ fontSize: 12.5, color: TEXT, flex: 1 }}>
                {p.shop} · 98% positive
              </span>
              <span
                style={{
                  fontSize: 11,

                  fontWeight: 600,

                  color: VIOLET,

                  background: "rgba(124,92,255,0.12)",

                  padding: "4px 10px",

                  borderRadius: 999,
                }}
              >
                Visit shop
              </span>
            </div>
          </div>

          {/* Variants */}
          {p.variants && (
            <div style={{ padding: "16px 16px 0" }}>
              {p.variants.map((v, vi) => (
                <div key={v.label} style={{ marginBottom: 12 }}>
                  <div
                    style={{
                      fontSize: 12,

                      color: MUTED,

                      marginBottom: 8,

                      fontWeight: 600,
                    }}
                  >
                    {v.label}
                  </div>
                  <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
                    {v.options.map((o) => {
                      const on = picked[vi] === o

                      return (
                        <button
                          key={o}
                          onClick={() =>
                            setPicked((s) =>
                              s.map((x, i) => (i === vi ? o : x)),
                            )
                          }
                          style={{
                            background: on ? "rgba(124,92,255,0.14)" : SURFACE2,

                            border: `1px solid ${on ? VIOLET : BORDER}`,

                            color: on ? VIOLET : TEXT,

                            borderRadius: 8,

                            padding: "8px 14px",

                            fontSize: 12.5,

                            fontWeight: 600,

                            fontFamily: "Inter, sans-serif",

                            cursor: "pointer",
                          }}
                        >
                          {o}
                        </button>
                      )
                    })}
                  </div>
                </div>
              ))}
            </div>
          )}

          {/* Description */}
          <div style={{ padding: "4px 16px 0" }}>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",

                fontSize: 15,

                fontWeight: 700,

                color: TEXT,

                marginBottom: 8,
              }}
            >
              Description
            </div>
            <p
              style={{
                fontSize: 13.5,

                color: "var(--muted-2)",

                lineHeight: 1.7,

                margin: 0,
              }}
            >
              {p.desc}
            </p>
          </div>

          {/* Reviews */}
          <div style={{ padding: "18px 16px 0" }}>
            <div
              style={{
                display: "flex",

                alignItems: "center",

                justifyContent: "space-between",

                marginBottom: 10,
              }}
            >
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 15,

                  fontWeight: 700,

                  color: TEXT,
                }}
              >
                Ratings & reviews
              </span>
              <span style={{ fontSize: 12, color: MUTED }}>{rc} reviews</span>
            </div>

            <div
              style={{
                display: "flex",

                alignItems: "center",

                gap: 16,

                background: SURFACE,

                border: `1px solid ${BORDER}`,

                borderRadius: 12,

                padding: 14,

                marginBottom: 12,
              }}
            >
              <div style={{ textAlign: "center", flexShrink: 0 }}>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",

                    fontSize: 32,

                    fontWeight: 700,

                    color: TEXT,

                    lineHeight: 1,
                  }}
                >
                  {p.rating.toFixed(1)}
                </div>
                <div style={{ marginTop: 6 }}>
                  <Stars value={p.rating} size={12} />
                </div>
                <div style={{ fontSize: 10.5, color: MUTED, marginTop: 5 }}>
                  {compact(p.sold)} sold
                </div>
              </div>
              <div
                style={{
                  flex: 1,

                  display: "flex",

                  flexDirection: "column",

                  gap: 5,
                }}
              >
                {[5, 4, 3, 2, 1].map((n, i) => {
                  const w = [78, 15, 4, 2, 1][i]

                  return (
                    <div
                      key={n}
                      style={{ display: "flex", alignItems: "center", gap: 6 }}
                    >
                      <span style={{ fontSize: 10, color: MUTED, width: 8 }}>
                        {n}
                      </span>
                      <div
                        style={{
                          flex: 1,

                          height: 5,

                          borderRadius: 3,

                          background: "var(--app-bg-deep)",

                          overflow: "hidden",
                        }}
                      >
                        <div
                          style={{
                            width: `${w}%`,

                            height: "100%",

                            background: GOLD,

                            borderRadius: 3,
                          }}
                        />
                      </div>
                      <span style={{ fontSize: 10, color: MUTED, width: 26 }}>
                        {w}%
                      </span>
                    </div>
                  )
                })}
              </div>
            </div>

            <div style={{ display: "flex", flexDirection: "column", gap: 10 }}>
              {visibleReviews(p).map((r, i) => (
                <div
                  key={`${r.user}-${i}`}
                  style={{
                    background: SURFACE,

                    border: `1px solid ${BORDER}`,

                    borderRadius: 12,

                    padding: 12,
                  }}
                >
                  <div
                    style={{
                      display: "flex",

                      alignItems: "center",

                      gap: 8,

                      marginBottom: 6,
                    }}
                  >
                    <span
                      style={{
                        width: 26,

                        height: 26,

                        borderRadius: "50%",

                        background: "rgba(124,92,255,0.18)",

                        color: VIOLET,

                        fontSize: 11,

                        fontWeight: 700,

                        display: "flex",

                        alignItems: "center",

                        justifyContent: "center",

                        flexShrink: 0,
                      }}
                    >
                      {r.user.slice(0, 1).toUpperCase()}
                    </span>
                    <span
                      style={{ fontSize: 13, fontWeight: 600, color: TEXT }}
                    >
                      {r.user}
                    </span>
                    <span
                      style={{ marginLeft: "auto", fontSize: 11, color: MUTED }}
                    >
                      {r.when}
                    </span>
                  </div>
                  <Stars value={r.stars} size={12} />
                  <p
                    style={{
                      fontSize: 13,

                      color: "var(--muted-2)",

                      lineHeight: 1.6,

                      margin: "7px 0 0",
                    }}
                  >
                    {r.text}
                  </p>
                </div>
              ))}
            </div>

            <div
              style={{
                marginTop: 12,

                background: SURFACE,

                border: `1px solid ${BORDER}`,

                borderRadius: 12,

                padding: 14,
              }}
            >
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 13.5,

                  fontWeight: 700,

                  color: TEXT,

                  marginBottom: 10,
                }}
              >
                Write a review
              </div>
              <div
                style={{
                  display: "flex",

                  gap: 6,

                  alignItems: "center",

                  marginBottom: 10,
                }}
              >
                {[1, 2, 3, 4, 5].map((i) => (
                  <button
                    key={i}
                    onClick={() => setDraftStars(i)}
                    aria-label={`Rate ${i} star${i > 1 ? "s" : ""}`}
                    style={{
                      background: "none",

                      border: "none",

                      padding: 2,

                      cursor: "pointer",

                      display: "flex",
                    }}
                  >
                    <Star
                      size={26}
                      fill={i <= draftStars ? GOLD : "transparent"}
                      stroke={i <= draftStars ? GOLD : "var(--border-3)"}
                      strokeWidth={2}
                    />
                  </button>
                ))}
                {draftStars > 0 && (
                  <span style={{ fontSize: 12, color: MUTED, marginLeft: 4 }}>
                    {draftStars}/5
                  </span>
                )}
              </div>
              <textarea
                value={draftText}
                onChange={(e) => setDraftText(e.target.value)}
                placeholder="Share your thoughts (optional)..."
                rows={3}
                style={{
                  width: "100%",

                  background: BG,

                  border: `1px solid ${BORDER}`,

                  borderRadius: 8,

                  padding: 10,

                  color: TEXT,

                  fontSize: 13,

                  fontFamily: "Inter, sans-serif",

                  resize: "none",

                  marginBottom: 10,

                  boxSizing: "border-box",

                  outline: "none",
                }}
              />
              <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
                <button
                  onClick={submitReview}
                  disabled={draftStars < 1}
                  style={{
                    background:
                      draftStars < 1 ? "var(--border-strong)" : VIOLET,

                    color: "#fff",

                    fontFamily: "Space Grotesk, sans-serif",

                    fontWeight: 700,

                    fontSize: 13.5,

                    padding: "10px 20px",

                    borderRadius: 8,

                    border: "none",

                    cursor: draftStars < 1 ? "default" : "pointer",
                  }}
                >
                  Post review
                </button>
                {myStars[selected.id] > 0 && (
                  <span style={{ fontSize: 12, color: "#4ade80" }}>
                    Thanks for rating!
                  </span>
                )}
              </div>
            </div>
          </div>

          <div style={{ height: 96 }} />
        </div>

        {/* Sticky action bar */}
        <div
          className="flex items-center gap-2.5 px-4 py-2.5"
          style={{
            flexShrink: 0,

            background: SURFACE,

            borderTop: `1px solid ${BORDER}`,
          }}
        >
          <button
            style={{
              width: 44,

              height: 44,

              borderRadius: 10,

              background: "transparent",

              border: "none",

              display: "flex",

              flexDirection: "column",

              alignItems: "center",

              justifyContent: "center",

              gap: 2,

              cursor: "pointer",

              color: MUTED,

              padding: 0,
            }}
          >
            <MessageCircle size={18} />
            <span style={{ fontSize: 9 }}>Chat</span>
          </button>
          <button
            onClick={() => setView("cart")}
            style={{
              width: 44,

              height: 44,

              borderRadius: 10,

              background: "transparent",

              border: "none",

              display: "flex",

              flexDirection: "column",

              alignItems: "center",

              justifyContent: "center",

              gap: 2,

              cursor: "pointer",

              color: MUTED,

              padding: 0,

              position: "relative",
            }}
          >
            <ShoppingCart size={18} />
            {cartCount > 0 && cartBadge(16)}
            <span style={{ fontSize: 9 }}>Cart</span>
          </button>
          <button
            onClick={() => {
              const variant = p.variants ? picked.join(" / ") : ""

              addLine(p, variant)

              setToast("Added to cart")
            }}
            style={{
              flex: 1,

              height: 44,

              borderRadius: 10,

              background: "rgba(124,92,255,0.16)",

              border: `1px solid ${VIOLET}`,

              color: VIOLET,

              fontFamily: "Space Grotesk, sans-serif",

              fontWeight: 700,

              fontSize: 14,

              cursor: "pointer",
            }}
          >
            Add to cart
          </button>
          <button
            onClick={buyNow}
            style={{
              flex: 1,

              height: 44,

              borderRadius: 10,

              background: CORAL,

              border: "none",

              color: "#fff",

              fontFamily: "Space Grotesk, sans-serif",

              fontWeight: 700,

              fontSize: 14,

              cursor: "pointer",
            }}
          >
            Buy now
          </button>
        </div>
      </div>
    )
  }

  /* -------------------------------- CART -------------------------------- */

  const grouped = useMemo(() => {
    const map = new Map<string, {
      line: CartLine

      index: number
    }[]>()

    cart.forEach((line, index) => {
      const shop = byId(line.id).shop

      const arr = map.get(shop) ?? []

      arr.push({ line, index })

      map.set(shop, arr)
    })

    return Array.from(map.entries())
  }, [cart])

  const allChecked = cart.length > 0 && cart.every((l) => l.checked)

  const checkedCount = checkedLines.reduce((s, l) => s + l.qty, 0)

  const toggleAll = () =>
    setCart((c) => c.map((l) => ({ ...l, checked: !allChecked })))

  const renderCart = () => {
    if (cart.length === 0) {
      return (
        <div className="flex flex-col h-full" style={{ background: BG }}>
          {pageHeader("Cart", undefined, () => setView("home"))}
          <div
            className="flex-1 flex flex-col items-center justify-center px-8"
            style={{ textAlign: "center" }}
          >
            <div
              style={{
                width: 84,

                height: 84,

                borderRadius: "50%",

                background: SURFACE,

                border: `1px solid ${BORDER}`,

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                marginBottom: 16,
              }}
            >
              <ShoppingCart size={34} color={MUTED} />
            </div>
            <p
              style={{
                fontFamily: "Space Grotesk, sans-serif",

                fontSize: 16,

                fontWeight: 700,

                color: TEXT,

                margin: "0 0 6px",
              }}
            >
              Your cart is empty
            </p>
            <p
              style={{
                fontSize: 13,

                color: MUTED,

                margin: "0 0 20px",

                lineHeight: 1.6,
              }}
            >
              Grab the flash sale deals before the timer runs out.
            </p>
            <button
              onClick={() => setView("home")}
              style={{
                background: VIOLET,

                color: "#fff",

                fontFamily: "Space Grotesk, sans-serif",

                fontWeight: 700,

                fontSize: 14,

                padding: "12px 28px",

                borderRadius: 10,

                border: "none",

                cursor: "pointer",
              }}
            >
              Browse deals
            </button>
          </div>
        </div>
      )
    }

    return (
      <div className="flex flex-col h-full" style={{ background: BG }}>
        {pageHeader(
          editCart ? `Edit cart (${cartCount})` : `Cart (${cartCount})`,

          <button
            onClick={() => setEditCart((v) => !v)}
            style={{
              background: "none",

              border: "none",

              color: VIOLET,

              fontSize: 13,

              fontWeight: 600,

              cursor: "pointer",

              fontFamily: "Inter, sans-serif",
            }}
          >
            {editCart ? "Done" : "Edit"}
          </button>,

          () => setView("home"),
        )}

        <div
          className="flex-1 overflow-y-auto"
          style={{ padding: "4px 12px 16px" }}
        >
          {grouped.map(([shop, entries]) => {
            const shopChecked = entries.every((e) => e.line.checked)

            return (
              <div
                key={shop}
                style={{
                  background: SURFACE,

                  border: `1px solid ${BORDER}`,

                  borderRadius: 14,

                  overflow: "hidden",

                  marginBottom: 12,
                }}
              >
                <div
                  className="flex items-center gap-2.5"
                  style={{
                    padding: "11px 12px",

                    borderBottom: `1px solid ${BORDER}`,
                  }}
                >
                  <Checkbox
                    checked={shopChecked}
                    onClick={() =>
                      setCart((c) =>
                        c.map((l) =>
                          byId(l.id).shop === shop
                            ? { ...l, checked: !shopChecked }
                            : l,
                        ),
                      )
                    }
                  />
                  <Store size={14} color={VIOLET} />
                  <span
                    style={{
                      fontSize: 13,

                      fontWeight: 600,

                      color: TEXT,

                      flex: 1,

                      overflow: "hidden",

                      whiteSpace: "nowrap",

                      textOverflow: "ellipsis",
                    }}
                  >
                    {shop}
                  </span>
                  <span style={{ fontSize: 11, color: MUTED }}>›</span>
                </div>

                {entries.map(({ line, index }) => {
                  const p = byId(line.id)

                  return (
                    <div
                      key={`${line.id}-${line.variant}`}
                      className="flex items-center gap-3"
                      style={{
                        padding: "12px",

                        borderBottom: `1px solid var(--surface-2)`,
                      }}
                    >
                      <Checkbox
                        checked={line.checked}
                        onClick={() =>
                          setCart((c) =>
                            c.map((l, i) =>
                              i === index ? { ...l, checked: !l.checked } : l,
                            ),
                          )
                        }
                      />
                      <img
                        src={u(p.images[0], 160, 160)}
                        alt={p.name}
                        style={{
                          width: 64,

                          height: 64,

                          borderRadius: 10,

                          objectFit: "cover",

                          flexShrink: 0,
                        }}
                      />
                      <div style={{ flex: 1, minWidth: 0 }}>
                        <p
                          style={{
                            fontSize: 12.5,

                            fontWeight: 500,

                            color: TEXT,

                            margin: 0,

                            lineHeight: 1.35,

                            display: "-webkit-box",

                            WebkitLineClamp: 2,

                            WebkitBoxOrient: "vertical",

                            overflow: "hidden",
                          }}
                        >
                          {p.name}
                        </p>
                        {line.variant && (
                          <div
                            style={{
                              fontSize: 10.5,

                              color: MUTED,

                              marginTop: 4,

                              background: SURFACE2,

                              border: `1px solid ${BORDER}`,

                              borderRadius: 5,

                              padding: "2px 7px",

                              display: "inline-block",
                            }}
                          >
                            {line.variant}
                          </div>
                        )}
                        <div
                          style={{
                            display: "flex",

                            alignItems: "center",

                            gap: 6,

                            marginTop: 6,
                          }}
                        >
                          <span
                            style={{
                              fontFamily: "Space Grotesk, sans-serif",

                              fontSize: 15,

                              fontWeight: 700,

                              color: CORAL,
                            }}
                          >
                            {money(p.price)}
                          </span>
                          <span
                            style={{
                              fontSize: 10.5,

                              color: "var(--muted-3)",

                              textDecoration: "line-through",
                            }}
                          >
                            {money(p.oldPrice)}
                          </span>
                        </div>
                        <div
                          style={{
                            display: "flex",

                            alignItems: "center",

                            justifyContent: "space-between",

                            marginTop: 8,
                          }}
                        >
                          {editCart ? (
                            <button
                              onClick={() =>
                                setCart((c) => c.filter((_, i) => i !== index))
                              }
                              aria-label="Remove"
                              style={{
                                background: "none",

                                border: "none",

                                color: CORAL,

                                cursor: "pointer",

                                display: "flex",

                                padding: 0,
                              }}
                            >
                              <Trash2 size={15} />
                            </button>
                          ) : (
                            <span />
                          )}
                          <Stepper
                            value={line.qty}
                            onChange={(n) => setQty(index, n)}
                          />
                        </div>
                      </div>
                    </div>
                  )
                })}
              </div>
            )
          })}

          {/* Voucher picker */}
          <div
            style={{
              background: SURFACE,

              border: `1px solid ${BORDER}`,

              borderRadius: 14,

              padding: "12px 14px",

              marginBottom: 12,
            }}
          >
            <div
              className="flex items-center gap-2.5"
              style={{ marginBottom: 10 }}
            >
              <Ticket size={15} color={CORAL} />
              <span
                style={{ fontSize: 13, fontWeight: 600, color: TEXT, flex: 1 }}
              >
                Voucher
              </span>
              {cartVoucher && (
                <button
                  onClick={() => setCartVoucher(null)}
                  style={{
                    background: "none",

                    border: "none",

                    color: MUTED,

                    fontSize: 12,

                    cursor: "pointer",
                  }}
                >
                  Remove
                </button>
              )}
            </div>
            <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
              {vouchers.map((v) => {
                const on = cartVoucher === v.id

                const usable = subtotal >= v.min

                return (
                  <button
                    key={v.id}
                    disabled={!usable}
                    onClick={() => setCartVoucher(on ? null : v.id)}
                    style={{
                      display: "flex",

                      alignItems: "center",

                      gap: 8,

                      background: on
                        ? "rgba(124,92,255,0.12)"
                        : "var(--surface)",

                      border: `1px dashed ${
                        on ? VIOLET : usable ? "rgba(255,107,92,0.5)" : BORDER
                      }`,

                      borderRadius: 10,

                      padding: "9px 11px",

                      cursor: usable ? "pointer" : "default",

                      opacity: usable ? 1 : 0.45,

                      color: on ? VIOLET : TEXT,

                      fontSize: 12,

                      fontWeight: 600,

                      textAlign: "left",
                    }}
                  >
                    <span
                      style={{
                        width: 8,

                        height: 8,

                        borderRadius: "50%",

                        border: `2px solid ${
                          on ? VIOLET : usable ? CORAL : "var(--border-3)"
                        }`,

                        flexShrink: 0,
                      }}
                    />
                    <span style={{ flex: 1 }}>{v.label}</span>
                    {on && <Check size={14} />}
                  </button>
                )
              })}
            </div>
          </div>

          {/* Summary */}
          <div
            style={{
              background: SURFACE,

              border: `1px solid ${BORDER}`,

              borderRadius: 14,

              padding: "12px 14px",
            }}
          >
            {[
              ["Subtotal", money(subtotal)],

              ["Shipping", shipping === 0 ? "FREE" : money(shipping)],

              ["Voucher", discount > 0 ? `−${money(discount)}` : "—"],
            ].map(([k, v]) => (
              <div
                key={k}
                style={{
                  display: "flex",

                  justifyContent: "space-between",

                  fontSize: 13,

                  color: MUTED,

                  padding: "5px 0",
                }}
              >
                <span>{k}</span>
                <span
                  style={{
                    color:
                      v === "FREE"
                        ? "#4ade80"
                        : v.startsWith("−")
                          ? CORAL
                          : TEXT,

                    fontWeight: 600,
                  }}
                >
                  {v}
                </span>
              </div>
            ))}
            <div
              style={{
                display: "flex",

                justifyContent: "space-between",

                alignItems: "center",

                marginTop: 8,

                paddingTop: 10,

                borderTop: `1px solid ${BORDER}`,
              }}
            >
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 14,

                  fontWeight: 700,

                  color: TEXT,
                }}
              >
                Total
              </span>
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 19,

                  fontWeight: 700,

                  color: CORAL,
                }}
              >
                {money(total)}
              </span>
            </div>
          </div>
        </div>

        {/* Checkout bar */}
        <div
          className="flex items-center gap-3 px-4 py-3"
          style={{
            flexShrink: 0,

            background: SURFACE,

            borderTop: `1px solid ${BORDER}`,
          }}
        >
          <Checkbox checked={allChecked} onClick={toggleAll} />
          <span style={{ fontSize: 12, color: MUTED }}>All</span>
          <div style={{ flex: 1, textAlign: "right" }}>
            <div style={{ fontSize: 10.5, color: MUTED }}>
              Total ({checkedCount} item{checkedCount === 1 ? "" : "s"})
            </div>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",

                fontSize: 18,

                fontWeight: 700,

                color: CORAL,

                lineHeight: 1.2,
              }}
            >
              {money(total)}
            </div>
          </div>
          <button
            onClick={() => {
              if (checkedCount === 0) {
                setToast("Select at least one item")

                return
              }

              setView("checkout")
            }}
            style={{
              background: checkedCount > 0 ? CORAL : "var(--border-strong)",

              color: "#fff",

              fontFamily: "Space Grotesk, sans-serif",

              fontWeight: 700,

              fontSize: 14.5,

              padding: "12px 22px",

              borderRadius: 999,

              border: "none",

              cursor: checkedCount > 0 ? "pointer" : "default",
            }}
          >
            Checkout ({checkedCount})
          </button>
        </div>
      </div>
    )
  }

  /* ------------------------------ CHECKOUT ------------------------------ */

  const renderCheckout = () => {
    const lines = checkedLines

    return (
      <div className="flex flex-col h-full" style={{ background: BG }}>
        {pageHeader("Checkout", undefined, () => setView("cart"))}
        <div
          className="flex-1 overflow-y-auto"
          style={{ padding: "4px 12px 16px" }}
        >
          {/* Address */}
          <div
            style={{
              background: SURFACE,

              border: `1px solid ${BORDER}`,

              borderRadius: 14,

              padding: 14,

              display: "flex",

              alignItems: "center",

              gap: 12,

              marginBottom: 12,
            }}
          >
            <div
              style={{
                width: 36,

                height: 36,

                borderRadius: "50%",

                background: "rgba(124,92,255,0.16)",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                flexShrink: 0,
              }}
            >
              <MapPin size={17} color={VIOLET} />
            </div>
            <div style={{ flex: 1, minWidth: 0 }}>
              <div style={{ fontSize: 13.5, fontWeight: 600, color: TEXT }}>
                Alex Kim · +1 (555) 013-7788
              </div>
              <div
                style={{
                  fontSize: 12,

                  color: MUTED,

                  marginTop: 3,

                  lineHeight: 1.5,
                }}
              >
                221B Fan Street, Apt 404, Seattle, WA 98101
              </div>
            </div>
            <ChevronRight size={16} color={MUTED} />
          </div>

          {/* Items */}
          {shopGroups(lines).map(([shop, entries]) => (
            <div
              key={shop}
              style={{
                background: SURFACE,

                border: `1px solid ${BORDER}`,

                borderRadius: 14,

                overflow: "hidden",

                marginBottom: 12,
              }}
            >
              <div
                className="flex items-center gap-2.5"
                style={{
                  padding: "11px 14px",

                  borderBottom: `1px solid ${BORDER}`,
                }}
              >
                <Store size={14} color={VIOLET} />
                <span style={{ fontSize: 13, fontWeight: 600, color: TEXT }}>
                  {shop}
                </span>
              </div>
              {entries.map((l) => {
                const p = byId(l.id)

                return (
                  <div
                    key={`${l.id}-${l.variant}`}
                    className="flex items-center gap-3"
                    style={{
                      padding: 12,

                      borderBottom: `1px solid var(--surface-2)`,
                    }}
                  >
                    <img
                      src={u(p.images[0], 160, 160)}
                      alt={p.name}
                      style={{
                        width: 56,

                        height: 56,

                        borderRadius: 9,

                        objectFit: "cover",

                        flexShrink: 0,
                      }}
                    />
                    <div style={{ flex: 1, minWidth: 0 }}>
                      <p
                        style={{
                          fontSize: 12.5,

                          color: TEXT,

                          margin: 0,

                          lineHeight: 1.35,

                          display: "-webkit-box",

                          WebkitLineClamp: 1,

                          WebkitBoxOrient: "vertical",

                          overflow: "hidden",
                        }}
                      >
                        {p.name}
                      </p>
                      {l.variant && (
                        <div
                          style={{
                            fontSize: 10.5,

                            color: MUTED,

                            marginTop: 3,
                          }}
                        >
                          {l.variant}
                        </div>
                      )}
                    </div>
                    <div style={{ textAlign: "right" }}>
                      <div
                        style={{
                          fontFamily: "Space Grotesk, sans-serif",

                          fontSize: 14,

                          fontWeight: 700,

                          color: CORAL,
                        }}
                      >
                        {money(p.price)}
                      </div>
                      <div style={{ fontSize: 11, color: MUTED, marginTop: 2 }}>
                        ×{l.qty}
                      </div>
                    </div>
                  </div>
                )
              })}
            </div>
          ))}

          {/* Payment */}
          <div
            style={{
              background: SURFACE,

              border: `1px solid ${BORDER}`,

              borderRadius: 14,

              padding: "6px 14px 8px",

              marginBottom: 12,
            }}
          >
            <div
              className="flex items-center gap-2.5"
              style={{ padding: "10px 0 6px" }}
            >
              <CreditCard size={15} color={VIOLET} />
              <span style={{ fontSize: 13, fontWeight: 600, color: TEXT }}>
                Payment method
              </span>
            </div>
            {payments.map((m) => {
              const on = payment === m

              return (
                <button
                  key={m}
                  onClick={() => setPayment(m)}
                  className="flex items-center gap-3"
                  style={{
                    width: "100%",

                    background: "none",

                    border: "none",

                    borderTop: `1px solid var(--surface-2)`,

                    padding: "12px 0",

                    cursor: "pointer",
                  }}
                >
                  <span
                    style={{
                      width: 18,

                      height: 18,

                      borderRadius: "50%",

                      border: `2px solid ${on ? VIOLET : "var(--border-3)"}`,

                      display: "flex",

                      alignItems: "center",

                      justifyContent: "center",

                      flexShrink: 0,
                    }}
                  >
                    {on && (
                      <span
                        style={{
                          width: 9,

                          height: 9,

                          borderRadius: "50%",

                          background: VIOLET,
                        }}
                      />
                    )}
                  </span>
                  <span
                    style={{
                      flex: 1,

                      textAlign: "left",

                      fontSize: 13,

                      color: TEXT,
                    }}
                  >
                    {m}
                  </span>
                </button>
              )
            })}
          </div>

          {/* Bill */}
          <div
            style={{
              background: SURFACE,

              border: `1px solid ${BORDER}`,

              borderRadius: 14,

              padding: "12px 14px",
            }}
          >
            {[
              ["Subtotal", money(subtotal)],

              ["Shipping", shipping === 0 ? "FREE" : money(shipping)],

              ["Voucher", discount > 0 ? `−${money(discount)}` : "—"],

              ["Payment", payment],
            ].map(([k, v]) => (
              <div
                key={k}
                style={{
                  display: "flex",

                  justifyContent: "space-between",

                  fontSize: 13,

                  color: MUTED,

                  padding: "5px 0",
                }}
              >
                <span>{k}</span>
                <span
                  style={{
                    color:
                      v === "FREE"
                        ? "#4ade80"
                        : v.startsWith("−")
                          ? CORAL
                          : TEXT,

                    fontWeight: 600,
                  }}
                >
                  {v}
                </span>
              </div>
            ))}
            <div
              style={{
                display: "flex",

                justifyContent: "space-between",

                alignItems: "center",

                marginTop: 8,

                paddingTop: 10,

                borderTop: `1px solid ${BORDER}`,
              }}
            >
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 14,

                  fontWeight: 700,

                  color: TEXT,
                }}
              >
                Total
              </span>
              <span
                style={{
                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 19,

                  fontWeight: 700,

                  color: CORAL,
                }}
              >
                {money(total)}
              </span>
            </div>
          </div>

          <p
            style={{
              fontSize: 11.5,

              color: MUTED,

              textAlign: "center",

              lineHeight: 1.6,

              margin: "14px 8px 0",
            }}
          >
            Simulated checkout — no real payment will be charged.
          </p>
        </div>

        <div
          className="flex items-center gap-3 px-4 py-3"
          style={{
            flexShrink: 0,

            background: SURFACE,

            borderTop: `1px solid ${BORDER}`,
          }}
        >
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 10.5, color: MUTED }}>Total</div>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",

                fontSize: 19,

                fontWeight: 700,

                color: CORAL,

                lineHeight: 1.2,
              }}
            >
              {money(total)}
            </div>
          </div>
          <button
            onClick={() => {
              if (checkedLines.length === 0) {
                setToast("Select at least one item")

                return
              }

              setOrderId(newOrderId())

              setView("confirmed")
            }}
            style={{
              background:
                checkedLines.length > 0 ? CORAL : "var(--border-strong)",

              color: "#fff",

              fontFamily: "Space Grotesk, sans-serif",

              fontWeight: 700,

              fontSize: 15,

              padding: "13px 30px",

              borderRadius: 999,

              border: "none",

              cursor: "pointer",
            }}
          >
            Place order
          </button>
        </div>
      </div>
    )
  }

  /* ---------------------------- CONFIRMATION ---------------------------- */

  const renderConfirmed = () => {
    const eta = new Date(Date.now() + 3 * 86400000).toLocaleDateString(
      "en-US",

      {
        month: "short",

        day: "numeric",
      },
    )

    return (
      <div
        className="flex flex-col h-full overflow-y-auto"
        style={{ background: BG, position: "relative" }}
      >
        <button
          onClick={() => setView("home")}
          aria-label="Back"
          style={{
            position: "absolute",

            top: 52,

            left: 14,

            width: 34,

            height: 34,

            borderRadius: "50%",

            background: "rgba(10,10,12,0.55)",

            border: "none",

            color: "#fff",

            display: "flex",

            alignItems: "center",

            justifyContent: "center",

            cursor: "pointer",

            padding: 0,

            zIndex: 5,
          }}
        >
          <ChevronLeft size={19} />
        </button>
        <div
          className="flex flex-col items-center"
          style={{ padding: "88px 28px 32px", textAlign: "center" }}
        >
          <div
            style={{
              width: 84,

              height: 84,

              borderRadius: "50%",

              background: "rgba(74,222,128,0.14)",

              border: "1px solid rgba(74,222,128,0.4)",

              display: "flex",

              alignItems: "center",

              justifyContent: "center",

              marginBottom: 20,
            }}
          >
            <Check size={40} color="#4ade80" strokeWidth={3} />
          </div>
          <h2
            style={{
              fontFamily: "Space Grotesk, sans-serif",

              fontSize: 23,

              fontWeight: 700,

              color: TEXT,

              margin: "0 0 8px",
            }}
          >
            Order confirmed!
          </h2>
          <p
            style={{
              fontSize: 13.5,

              color: MUTED,

              lineHeight: 1.65,

              margin: 0,
            }}
          >
            Your merch is on the way to a parallel universe.
            <br />
            Arriving by{" "}
            <span style={{ color: TEXT, fontWeight: 600 }}>{eta}</span>
          </p>

          <div
            style={{
              width: "100%",

              background: SURFACE,

              border: `1px solid ${BORDER}`,

              borderRadius: 14,

              padding: "14px 16px",

              marginTop: 24,

              textAlign: "left",
            }}
          >
            {[
              [
                "Order number",

                orderId,
              ],

              ["Items", `${checkedCount || cartCount} item(s)`],

              ["Payment", payment],

              ["Total paid", money(total)],
            ].map(([k, v]) => (
              <div
                key={k}
                style={{
                  display: "flex",

                  justifyContent: "space-between",

                  fontSize: 13,

                  padding: "6px 0",

                  color: MUTED,
                }}
              >
                <span>{k}</span>
                <span
                  style={{
                    color: k === "Total paid" ? CORAL : TEXT,

                    fontWeight: 600,
                  }}
                >
                  {v}
                </span>
              </div>
            ))}
          </div>

          <button
            onClick={() => setToast("Tracking coming soon")}
            style={{
              width: "100%",

              marginTop: 18,

              background: "rgba(124,92,255,0.16)",

              border: `1px solid ${VIOLET}`,

              color: VIOLET,

              fontFamily: "Space Grotesk, sans-serif",

              fontWeight: 700,

              fontSize: 15,

              padding: "13px",

              borderRadius: 10,

              cursor: "pointer",

              display: "flex",

              alignItems: "center",

              justifyContent: "center",

              gap: 8,
            }}
          >
            <Truck size={17} /> Track my order
          </button>
          <button
            onClick={() => {
              setCart((c) => c.filter((l) => !l.checked))

              setCartVoucher(null)

              setEditCart(false)

              setView("home")
            }}
            style={{
              width: "100%",

              marginTop: 10,

              background: "none",

              border: `1px solid ${BORDER}`,

              color: TEXT,

              fontFamily: "Space Grotesk, sans-serif",

              fontWeight: 700,

              fontSize: 15,

              padding: "13px",

              borderRadius: 10,

              cursor: "pointer",
            }}
          >
            Continue shopping
          </button>
        </div>
      </div>
    )
  }

  /* -------------------------------- ROOT -------------------------------- */

  return (
    <div style={{ height: "100%", background: BG, position: "relative" }}>
      {view === "home" && renderHome()}
      {view === "detail" && renderDetail()}
      {view === "cart" && renderCart()}
      {view === "checkout" && renderCheckout()}
      {view === "confirmed" && renderConfirmed()}

      {toast && (
        <div
          style={{
            position: "absolute",

            left: "50%",

            bottom: 92,

            transform: "translateX(-50%)",

            background: "rgba(10,10,12,0.94)",

            border: `1px solid ${BORDER}`,

            color: TEXT,

            fontSize: 12.5,

            fontWeight: 600,

            padding: "10px 18px",

            borderRadius: 999,

            whiteSpace: "nowrap",

            zIndex: 40,

            boxShadow: "0 12px 30px rgba(0,0,0,0.5)",
          }}
        >
          {toast}
        </div>
      )}
    </div>
  )
}
