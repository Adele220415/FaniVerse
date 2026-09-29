import { useMemo, useState, type ReactNode, type CSSProperties } from "react"

import {
  Search,
  MapPin,
  Calendar,
  Users,
  Ticket,
  ChevronLeft,
  ChevronRight,
  Sparkles,
  Bookmark,
  Share2,
  Check,
  Clock,
  Building2,
  Megaphone,
  Zap,
  SlidersHorizontal,
  X,
  Download,
  ExternalLink,
  Navigation,
} from "lucide-react"

type Tag = "Anime" | "Comics" | "Gaming" | "K-Pop" | "Star Wars"

type ScheduleItem = {
  time: string

  title: string

  place: string
}

type TicketTier = {
  name: string

  price: number

  note: string

  left?: number
}

type EventItem = {
  id: number

  title: string

  tag: Tag

  city: string

  venue: string

  dateLabel: string

  dayBadge: string

  month: string

  start: string

  end: string

  tz: string

  lat: number

  lng: number

  doors: string

  img: string

  attending: number

  price: number

  featured?: boolean

  hot?: boolean

  about: string[]

  highlights: string[]

  schedule: ScheduleItem[]

  tickets: TicketTier[]

  organizer: {
    name: string

    events: string

    avatar: string
  }
}

const TAG_COLORS: Record<Tag, string> = {
  Anime: "#FF6B5C",

  Comics: "#F5A623",

  Gaming: "#7C5CFF",

  "K-Pop": "#FF5CA8",

  "Star Wars": "#4FC3F7",
}

const CITIES = [
  "All Cities",

  "New York",

  "Los Angeles",

  "Chicago",

  "London",

  "Tokyo",
]

const CATEGORIES: ("All" | Tag)[] = [
  "All",

  "Anime",

  "Comics",

  "Gaming",

  "K-Pop",

  "Star Wars",
]

const avatars = [
  "https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=64&h=64&fit=crop&auto=format",

  "https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=64&h=64&fit=crop&auto=format",

  "https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=64&h=64&fit=crop&auto=format",

  "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=64&h=64&fit=crop&auto=format",
]

const img = (id: string, w = 640, h = 420) =>
  `https://images.unsplash.com/${id}?w=${w}&h=${h}&fit=crop&auto=format`

const events: EventItem[] = [
  {
    id: 1,

    title: "Anime Expo Frontier 2026",

    tag: "Anime",

    city: "Los Angeles",

    venue: "Los Angeles Convention Center",

    dateLabel: "Oct 18–20, 2026",

    dayBadge: "OCT 18",

    month: "October 2026",

    start: "2026-10-18",

    end: "2026-10-20",

    tz: "America/Los_Angeles",

    lat: 34.0406,

    lng: -118.2679,

    doors: "10:00 AM – 8:00 PM",

    img: img("photo-1540575467063-178a50c2df87"),

    attending: 42800,

    price: 65,

    featured: true,

    hot: true,

    about: [
      "Three days of anime, manga and Japanese pop culture — the biggest gathering on the West Coast. Studios, voice actors and creators all under one roof.",

      "This year adds a night concert stage, a 500-seat dubbing workshop room, and an artist alley with 400+ independent creators.",
    ],

    highlights: [
      "World premieres from 6 major studios",

      "Voice actor meet-and-greets daily",

      "Cosplay masquerade with $10k prizes",

      "Artist alley with 400+ creators",
    ],

    schedule: [
      {
        time: "10:00",

        title: "Opening ceremony & trailer drops",

        place: "Main Stage",
      },

      {
        time: "13:00",

        title: "Voice actor panel: dubbing legends",

        place: "Hall B",
      },

      { time: "17:30", title: "Cosplay preliminary rounds", place: "Arena" },

      { time: "20:00", title: "Anisong night concert", place: "Outdoor Plaza" },
    ],

    tickets: [
      {
        name: "General Admission",

        price: 65,

        note: "All 3 days · standing halls",

        left: 320,
      },

      {
        name: "Fan Pass + Concert",

        price: 129,

        note: "Adds night concert seat",

        left: 64,
      },

      { name: "VIP Front Row", price: 249, note: "Priority entry · gift bag" },
    ],

    organizer: {
      name: "Frontier Events",

      events: "38 events hosted",

      avatar: avatars[0],
    },
  },

  {
    id: 2,

    title: "Comic-Con International NYC",

    tag: "Comics",

    city: "New York",

    venue: "Javits Center",

    dateLabel: "Nov 6–8, 2026",

    dayBadge: "NOV 06",

    month: "November 2026",

    start: "2026-11-06",

    end: "2026-11-08",

    tz: "America/New_York",

    lat: 40.757,

    lng: -74.0021,

    doors: "9:30 AM – 7:00 PM",

    img: img("photo-1612036782180-6f0b6cd846fe"),

    attending: 128000,

    price: 55,

    hot: true,

    about: [
      "The East Coast's flagship comics convention: publishers, indie artists, movie panels and the famous costume contest.",

      "Over 900 exhibitors across four halls, plus a dedicated retro comics archive you can browse and buy from.",
    ],

    highlights: [
      "900+ exhibitor booths",

      "Creator signings every hour",

      "Retro comics archive room",

      "Indie publisher showcase",
    ],

    schedule: [
      {
        time: "09:30",

        title: "Hall opens · exclusive merch drop",

        place: "Hall 1",
      },

      {
        time: "12:00",

        title: "Behind the ink: artist roundtable",

        place: "Room 210",
      },

      { time: "15:00", title: "Screen adaptations Q&A", place: "Main Stage" },

      { time: "18:00", title: "Costume contest finals", place: "Grand Arena" },
    ],

    tickets: [
      { name: "Day Pass", price: 55, note: "Pick any one day", left: 1200 },

      {
        name: "Full Weekend",

        price: 120,

        note: "All 3 days · re-entry",

        left: 180,
      },

      { name: "Pro Weekend", price: 210, note: "Early 8 AM entry" },
    ],

    organizer: {
      name: "NYC Pop Culture",

      events: "21 events hosted",

      avatar: avatars[1],
    },
  },

  {
    id: 3,

    title: "IndieCon Chicago",

    tag: "Gaming",

    city: "Chicago",

    venue: "McCormick Place",

    dateLabel: "Nov 20–22, 2026",

    dayBadge: "NOV 20",

    month: "November 2026",

    start: "2026-11-20",

    end: "2026-11-22",

    tz: "America/Chicago",

    lat: 41.8513,

    lng: -87.6175,

    doors: "11:00 AM – 9:00 PM",

    img: img("photo-1550745165-9bc0b252726f"),

    attending: 9600,

    price: 0,

    about: [
      "A free, developer-first games festival. Play 120 unreleased indie titles before anyone else and talk straight to the teams who built them.",

      "Includes speedrun showcases, a retro hardware repair corner and a job board for aspiring game devs.",
    ],

    highlights: [
      "120 unreleased indie demos",

      "Direct chats with developers",

      "Speedrun showcase stage",

      "Free retro repair clinic",
    ],

    schedule: [
      { time: "11:00", title: "Doors open · demo floor", place: "Hall A" },

      {
        time: "14:00",

        title: "Dev AMA: building in public",

        place: "Studio Room",
      },

      { time: "17:00", title: "Speedrun showcase", place: "Main Stage" },

      { time: "20:00", title: "Indie awards ceremony", place: "Main Stage" },
    ],

    tickets: [
      {
        name: "Free Entry",

        price: 0,

        note: "Register to reserve a slot",

        left: 800,
      },

      { name: "Workshop Pass", price: 30, note: "Adds 3 hands-on workshops" },
    ],

    organizer: {
      name: "Indie Collective",

      events: "14 events hosted",

      avatar: avatars[2],
    },
  },

  {
    id: 4,

    title: "Retro Game Market",

    tag: "Gaming",

    city: "New York",

    venue: "Brooklyn Expo Center",

    dateLabel: "Dec 5, 2026",

    dayBadge: "DEC 05",

    month: "December 2026",

    start: "2026-12-05",

    end: "2026-12-05",

    tz: "America/New_York",

    lat: 40.7305,

    lng: -73.957,

    doors: "10:00 AM – 6:00 PM",

    img: img("photo-1511512578047-dfb367046420"),

    attending: 5400,

    price: 15,

    about: [
      "Cartridges, CRTs and culture. Buy, sell and trade 40 years of gaming history with 120 vetted vendors.",

      "Free console free-play lounge all day — bring your own controller or borrow one of ours.",
    ],

    highlights: [
      "120 vetted retro vendors",

      "All-day free-play lounge",

      "Cartridge cleaning service",

      "Graded collectible auction",
    ],

    schedule: [
      { time: "10:00", title: "Vendor floor opens", place: "Main Hall" },

      { time: "13:00", title: "Cartridge restoration demo", place: "Workshop" },

      {
        time: "15:30",

        title: "Retro tournament bracket",

        place: "Free-play Zone",
      },
    ],

    tickets: [
      { name: "Entry", price: 15, note: "All day · re-entry", left: 400 },

      { name: "Early Bird 9 AM", price: 28, note: "First pick of the floor" },
    ],

    organizer: {
      name: "Pixel Society",

      events: "9 events hosted",

      avatar: avatars[3],
    },
  },

  {
    id: 5,

    title: "Star Wars Celebration Europe",

    tag: "Star Wars",

    city: "London",

    venue: "ExCeL London",

    dateLabel: "Jan 15–17, 2027",

    dayBadge: "JAN 15",

    month: "January 2027",

    start: "2027-01-15",

    end: "2027-01-17",

    tz: "Europe/London",

    lat: 51.508,

    lng: -0.029,

    doors: "9:00 AM – 8:00 PM",

    img: img("photo-1606041008023-472dfb5e530f"),

    attending: 72000,

    price: 89,

    hot: true,

    about: [
      "The galaxy's biggest official fan celebration returns to London for three days of announcements, props and community.",

      "Expect the first panel of the new film era, a full-scale ship build reveal, and the legendary 501st troop march.",
    ],

    highlights: [
      "First-look film panels",

      "Full-scale ship builds",

      "501st legion troop march",

      "Archive props gallery",
    ],

    schedule: [
      {
        time: "09:00",

        title: "Doors · ceremony opening",

        place: "Central Stage",
      },

      { time: "12:30", title: "Behind the new era panel", place: "Main Hall" },

      { time: "16:00", title: "Costume guild competition", place: "Stage 2" },

      {
        time: "19:00",

        title: "Symphonic night concert",

        place: "ICC Auditorium",
      },
    ],

    tickets: [
      { name: "Day Ticket", price: 89, note: "Any single day", left: 900 },

      {
        name: "3-Day Pass",

        price: 219,

        note: "All halls · re-entry",

        left: 240,
      },

      { name: "Jedi VIP", price: 399, note: "Reserved seating · lounge" },
    ],

    organizer: {
      name: "Galaxy Events UK",

      events: "17 events hosted",

      avatar: avatars[1],
    },
  },

  {
    id: 6,

    title: "KCON Tokyo 2027",

    tag: "K-Pop",

    city: "Tokyo",

    venue: "Makuhari Messe",

    dateLabel: "Jan 23–25, 2027",

    dayBadge: "JAN 23",

    month: "January 2027",

    start: "2027-01-23",

    end: "2027-01-25",

    tz: "Asia/Tokyo",

    lat: 35.6456,

    lng: 140.041,

    doors: "11:00 AM – 10:00 PM",

    img: img("photo-1571380401583-72ca84994796"),

    attending: 35000,

    price: 95,

    about: [
      "K-pop's touring convention lands in Tokyo: showcase stages, fan meetings, dance workshops and a full K-beauty market.",

      "Fan sign lotteries open two weeks early in-app — winners are notified before general sale.",
    ],

    highlights: [
      "Evening showcase concerts",

      "Official fan sign lottery",

      "Dance workshops with pros",

      "K-beauty & street food market",
    ],

    schedule: [
      {
        time: "11:00",

        title: "Market & experience zones open",

        place: "Hall 5",
      },

      {
        time: "14:00",

        title: "Dance workshop: title choreo",

        place: "Studio A",
      },

      { time: "18:00", title: "Artist fan meeting", place: "Showcase Stage" },

      { time: "21:00", title: "Night concert finale", place: "Main Arena" },
    ],

    tickets: [
      {
        name: "Day Pass",

        price: 95,

        note: "Concert standing · one day",

        left: 560,
      },

      {
        name: "Fan Meeting + Pass",

        price: 175,

        note: "Guaranteed fan sign entry",
      },

      { name: "Ultimate 3-Day", price: 320, note: "All shows · lounge access" },
    ],

    organizer: {
      name: "Hallyu Live",

      events: "26 events hosted",

      avatar: avatars[2],
    },
  },

  {
    id: 7,

    title: "Cosplay World Cup",

    tag: "Anime",

    city: "Chicago",

    venue: "Navy Pier Grand Hall",

    dateLabel: "Feb 13–14, 2027",

    dayBadge: "FEB 13",

    month: "February 2027",

    start: "2027-02-13",

    end: "2027-02-14",

    tz: "America/Chicago",

    lat: 41.8917,

    lng: -87.6086,

    doors: "10:00 AM – 8:00 PM",

    img: img("photo-1581833971358-2c8b550f87b3"),

    attending: 7800,

    price: 25,

    about: [
      "Crafters from 30 countries compete for the world crown — with a public gallery where you can inspect every costume up close.",

      "Beginner track included: 45-minute armor-building clinics run all weekend, no experience needed.",
    ],

    highlights: [
      "30 countries competing",

      "Up-close costume gallery",

      "Beginner armor clinics",

      "Craft & foam workshop row",
    ],

    schedule: [
      {
        time: "10:00",

        title: "Gallery opens · meet the crafters",

        place: "Grand Hall",
      },

      { time: "13:00", title: "Beginner armor clinic", place: "Workshop 1" },

      { time: "16:00", title: "International semifinals", place: "Main Stage" },

      { time: "19:00", title: "World final & crowning", place: "Main Stage" },
    ],

    tickets: [
      { name: "Spectator", price: 25, note: "Both days · gallery access" },

      {
        name: "Competitor",

        price: 60,

        note: "Includes backstage pass",

        left: 40,
      },
    ],

    organizer: {
      name: "Crafters League",

      events: "11 events hosted",

      avatar: avatars[0],
    },
  },

  {
    id: 8,

    title: "Manga Matsuri London",

    tag: "Comics",

    city: "London",

    venue: "Business Design Centre",

    dateLabel: "Feb 27, 2027",

    dayBadge: "FEB 27",

    month: "February 2027",

    start: "2027-02-27",

    end: "2027-02-27",

    tz: "Europe/London",

    lat: 51.535,

    lng: -0.103,

    doors: "10:00 AM – 7:00 PM",

    img: img("photo-1578632767115-351597cf2477"),

    attending: 4300,

    price: 0,

    about: [
      "A one-day celebration of manga, light novels and illustration — free to enter, easy to spend a whole afternoon at.",

      "Translators, editors and artists explain how a Japanese release actually makes it to your shelf in English.",
    ],

    highlights: [
      "Free entry all day",

      "Translator & editor talks",

      "Live illustration battles",

      "Light novel sample library",
    ],

    schedule: [
      {
        time: "10:00",

        title: "Doors · illustration wall opens",

        place: "Floor 1",
      },

      { time: "12:30", title: "How manga gets translated", place: "Talk Room" },

      {
        time: "15:00",

        title: "Draw-off: artists vs fans",

        place: "Main Stage",
      },
    ],

    tickets: [
      { name: "Free Entry", price: 0, note: "Reserve a timed slot" },

      {
        name: "Workshop Bundle",

        price: 18,

        note: "Adds 2 illustration workshops",
      },
    ],

    organizer: {
      name: "Page Turners",

      events: "7 events hosted",

      avatar: avatars[3],
    },
  },

  {
    id: 9,

    title: "EVO World Finals",

    tag: "Gaming",

    city: "Los Angeles",

    venue: "MGM Grand Garden",

    dateLabel: "Mar 5–7, 2027",

    dayBadge: "MAR 05",

    month: "March 2027",

    start: "2027-03-05",

    end: "2027-03-07",

    tz: "America/Los_Angeles",

    lat: 36.1023,

    lng: -115.1699,

    doors: "10:00 AM – 11:00 PM",

    img: img("photo-1542751371-adc38448a05e"),

    attending: 15600,

    price: 75,

    hot: true,

    about: [
      "The world championship of fighting games. 2,000 players qualify across the season, 8 remain on the final Sunday.",

      "Free open-play stations run 12 hours a day, so you can compete between the top-bracket matches.",
    ],

    highlights: [
      "2,000 qualified players",

      "Free 12h open-play zone",

      "Developer balance panels",

      "Final Sunday main arena",
    ],

    schedule: [
      { time: "10:00", title: "Open bracket pools begin", place: "Pool Halls" },

      {
        time: "14:00",

        title: "Dev panel: next season balance",

        place: "Stage B",
      },

      { time: "18:00", title: "Top 8 qualifier matches", place: "Main Arena" },

      {
        time: "20:00",

        title: "World finals · grand final",

        place: "Main Arena",
      },
    ],

    tickets: [
      {
        name: "Weekend Pass",

        price: 75,

        note: "All 3 days · open play",

        left: 700,
      },

      {
        name: "Arena Seating",

        price: 145,

        note: "Reserved final Sunday seat",

        left: 90,
      },
    ],

    organizer: {
      name: "Fight League",

      events: "19 events hosted",

      avatar: avatars[1],
    },
  },

  {
    id: 10,

    title: "Neon Stage: Fan Concert Night",

    tag: "K-Pop",

    city: "Los Angeles",

    venue: "The Forum",

    dateLabel: "Mar 20, 2027",

    dayBadge: "MAR 20",

    month: "March 2027",

    start: "2027-03-20",

    end: "2027-03-20",

    tz: "America/Los_Angeles",

    lat: 33.9583,

    lng: -118.341,

    doors: "6:00 PM – 11:00 PM",

    img: img("photo-1493225457124-a3eb161ffa5f"),

    attending: 18200,

    price: 59,

    about: [
      "A one-night fan concert with six acts, a full lightstick sync show and an after-party DJ set in the plaza.",

      "Merch pre-order pickup is available inside the venue — skip the line and collect on arrival.",
    ],

    highlights: [
      "Six acts, one night",

      "Synced lightstick show",

      "Merch pre-order pickup",

      "Plaza after-party",
    ],

    schedule: [
      { time: "18:00", title: "Doors & merch pickup", place: "Concourse" },

      { time: "19:30", title: "Opening acts", place: "Main Stage" },

      { time: "21:00", title: "Headline performance", place: "Main Stage" },

      { time: "23:00", title: "Plaza after-party", place: "Outdoor Plaza" },
    ],

    tickets: [
      { name: "Upper Bowl", price: 59, note: "Reserved seat" },

      {
        name: "Floor Standing",

        price: 99,

        note: "Closest to the stage",

        left: 210,
      },

      {
        name: "Soundcheck Pass",

        price: 169,

        note: "Afternoon soundcheck access",
      },
    ],

    organizer: {
      name: "Neon Stage",

      events: "31 events hosted",

      avatar: avatars[2],
    },
  },
]

const money = (p: number) => (p === 0 ? "Free" : `$${p}`)

const daysUntil = (iso: string) =>
  Math.ceil((new Date(`${iso}T00:00:00`).getTime() - Date.now()) / 86400000)

const pad2 = (n: number) => String(n).padStart(2, "0")

const compactDate = (iso: string) => iso.replace(/-/g, "")

const addDays = (iso: string, n: number) => {
  const d = new Date(`${iso}T00:00:00`)

  d.setDate(d.getDate() + n)

  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`
}

const parseDoors = (doors: string) => {
  const [a, b] = doors.split("–")

  const toMin = (s?: string) => {
    const m = s?.trim().match(/^(\d{1,2}):(\d{2})\s*([ap]m)$/i)

    if (!m) return null

    let h = Number(m[1]) % 12

    if (m[3].toLowerCase() === "pm") h += 12

    return h * 60 + Number(m[2])
  }

  return { open: toMin(a), close: toMin(b) }
}

const hhmm = (min: number) => `${pad2(Math.floor(min / 60))}${pad2(min % 60)}`

const icsFor = (e: EventItem) => {
  const { open, close } = parseDoors(e.doors)

  const startMin = open ?? 600

  const endMin = close ?? startMin + 480

  return [
    "BEGIN:VCALENDAR",

    "VERSION:2.0",

    "PRODID:-//Fandom Events//EN",

    "CALSCALE:GREGORIAN",

    "BEGIN:VEVENT",

    `UID:fandom-event-${e.id}@fandom-app`,

    `DTSTAMP:${compactDate(e.start)}T${hhmm(startMin)}00`,

    `DTSTART:${compactDate(e.start)}T${hhmm(startMin)}00`,

    `DTEND:${compactDate(e.end)}T${hhmm(endMin)}00`,

    `SUMMARY:${e.title}`,

    `LOCATION:${e.venue}\\, ${e.city}`,

    `DESCRIPTION:${e.about.join(" ").replace(/,/g, "\\,")}`,

    "END:VEVENT",

    "END:VCALENDAR",
  ].join("\r\n")
}

const downloadIcs = (e: EventItem) => {
  const blob = new Blob([icsFor(e)], {
    type: "text/calendar;charset=utf-8",
  })

  const url = URL.createObjectURL(blob)

  const a = document.createElement("a")

  a.href = url

  a.download = `${e.title.replace(/[^a-z0-9]+/gi, "-").toLowerCase()}.ics`

  document.body.appendChild(a)

  a.click()

  a.remove()

  URL.revokeObjectURL(url)
}

const googleCalendarUrl = (e: EventItem) => {
  const { open, close } = parseDoors(e.doors)

  const startMin = open ?? 600

  const endMin = close ?? startMin + 480

  const stamp = (iso: string, min: number) =>
    `${compactDate(iso)}T${hhmm(min)}00`

  const params = new URLSearchParams({
    action: "TEMPLATE",

    text: e.title,

    dates: `${stamp(e.start, startMin)}/${stamp(e.end, endMin)}`,

    ctz: e.tz,

    location: `${e.venue}, ${e.city}`,

    details: e.about.join("\n\n"),
  })

  return `https://calendar.google.com/calendar/render?${params.toString()}`
}

const mapEmbedUrl = (e: EventItem) => {
  const bbox = [
    e.lng - 0.008,

    e.lat - 0.005,

    e.lng + 0.008,

    e.lat + 0.005,
  ].join(",")

  return `https://www.openstreetmap.org/export/embed.html?bbox=${bbox}&layer=mapnik&marker=${e.lat},${e.lng}`
}

const directionsUrl = (e: EventItem) =>
  `https://www.google.com/maps/dir/?api=1&destination=${e.lat},${e.lng}`

const chip = (active: boolean) => ({
  flex: "0 0 auto",

  padding: "8px 14px",

  borderRadius: 999,

  fontSize: 13,

  fontFamily: "Inter, sans-serif",

  fontWeight: active ? 600 : 500,

  cursor: "pointer",

  whiteSpace: "nowrap" as const,

  border: `1px solid ${active ? "#7C5CFF" : "var(--border)"}`,

  background: active ? "#7C5CFF" : "var(--surface)",

  color: active ? "#fff" : "var(--muted-2)",
})

export default function EventsTab() {
  const [city, setCity] = useState("All Cities")

  const [category, setCategory] = useState<"All" | Tag>("All")

  const [query, setQuery] = useState("")

  const [selected, setSelected] = useState<EventItem | null>(null)

  const [tierIndex, setTierIndex] = useState(0)

  const [saved, setSaved] = useState<number[]>([])

  const [calOpen, setCalOpen] = useState(false)

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase()

    return events.filter((e) => {
      const cityOk = city === "All Cities" || e.city === city

      const catOk = category === "All" || e.tag === category

      const qOk =
        !q ||
        e.title.toLowerCase().includes(q) ||
        e.venue.toLowerCase().includes(q) ||
        e.city.toLowerCase().includes(q) ||
        e.tag.toLowerCase().includes(q)

      return cityOk && catOk && qOk
    })
  }, [city, category, query])

  const hero = filtered.find((e) => e.featured) ?? filtered[0]

  const rest = filtered.filter((e) => e.id !== hero?.id)

  const groups = useMemo(() => {
    const map = new Map<string, EventItem[]>()

    rest.forEach((e) => {
      const list = map.get(e.month) ?? []

      list.push(e)

      map.set(e.month, list)
    })

    return [...map.entries()]
  }, [rest])

  const stats = useMemo(() => {
    const free = filtered.filter((e) => e.price === 0).length

    const hot = filtered.filter((e) => e.hot).length

    return { total: filtered.length, free, hot }
  }, [filtered])

  const clearFilters = () => {
    setCity("All Cities")

    setCategory("All")

    setQuery("")
  }

  const open = (e: EventItem) => {
    setSelected(e)

    setTierIndex(0)
  }

  const toggleSave = (id: number) =>
    setSaved((s) => (s.includes(id) ? s.filter((x) => x !== id) : [...s, id]))

  if (selected) {
    return (
      <EventDetail
        event={selected}
        saved={saved.includes(selected.id)}
        onToggleSave={() => toggleSave(selected.id)}
        onBack={() => setSelected(null)}
        onOpen={(e) => open(e)}
        tierIndex={tierIndex}
        setTierIndex={setTierIndex}
      />
    )
  }

  return (
    <div
      className="flex flex-col h-full"
      style={{
        background: "var(--app-bg)",

        position: "relative",

        overflow: "hidden",
      }}
    >
      <div className="flex-1 overflow-y-auto">
        <div style={{ padding: "44px 20px 0" }}>
          <div
            style={{
              display: "flex",

              alignItems: "flex-start",

              justifyContent: "space-between",
            }}
          >
            <div>
              <h2
                style={{
                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 26,

                  fontWeight: 700,

                  color: "var(--text)",

                  margin: 0,

                  lineHeight: 1.15,
                }}
              >
                Events
              </h2>
              <p
                style={{
                  fontFamily: "Inter, sans-serif",

                  fontSize: 13,

                  color: "var(--muted)",

                  margin: "5px 0 0",
                }}
              >
                Conventions, drops & meetups for your fandom
              </p>
            </div>
            <div style={{ display: "flex", gap: 8 }}>
              <span
                style={{
                  width: 36,

                  height: 36,

                  borderRadius: 10,

                  background: "var(--surface)",

                  border: "1px solid var(--border)",

                  display: "flex",

                  alignItems: "center",

                  justifyContent: "center",

                  color: saved.length ? "#7C5CFF" : "var(--muted)",
                }}
              >
                <Bookmark size={16} fill={saved.length ? "#7C5CFF" : "none"} />
              </span>
              <span
                style={{
                  width: 36,

                  height: 36,

                  borderRadius: 10,

                  background: "var(--surface)",

                  border: "1px solid var(--border)",

                  display: "flex",

                  alignItems: "center",

                  justifyContent: "center",

                  color: "var(--muted)",
                }}
              >
                <SlidersHorizontal size={16} />
              </span>
            </div>
          </div>

          <div
            style={{
              position: "relative",

              marginTop: 16,

              marginBottom: 14,
            }}
          >
            <Search
              size={16}
              color="var(--muted)"
              style={{
                position: "absolute",

                left: 13,

                top: "50%",

                transform: "translateY(-50%)",
              }}
            />
            <input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search events, venues, cities…"
              style={{
                width: "100%",

                background: "var(--surface)",

                border: "1px solid var(--border)",

                borderRadius: 12,

                padding: "11px 14px 11px 38px",

                color: "var(--text)",

                fontSize: 14,

                fontFamily: "Inter, sans-serif",

                outline: "none",
              }}
            />
          </div>

          <div
            style={{
              display: "flex",

              gap: 8,

              overflowX: "auto",

              paddingBottom: 2,

              margin: "0 -20px",

              padding: "0 20px 2px",
            }}
          >
            {CITIES.map((c) => (
              <button
                key={c}
                onClick={() => setCity(c)}
                style={chip(city === c)}
              >
                {c}
              </button>
            ))}
          </div>

          <div
            style={{
              display: "flex",

              gap: 8,

              overflowX: "auto",

              margin: "10px -20px 0",

              padding: "0 20px 2px",
            }}
          >
            {CATEGORIES.map((c) => (
              <button
                key={c}
                onClick={() => setCategory(c)}
                style={chip(category === c)}
              >
                {c}
              </button>
            ))}
          </div>

          <div
            style={{
              display: "flex",

              gap: 8,

              marginTop: 14,

              fontFamily: "Inter, sans-serif",

              fontSize: 12,
            }}
          >
            <span
              style={{
                background: "var(--surface)",

                border: "1px solid var(--border)",

                color: "var(--muted-2)",

                borderRadius: 8,

                padding: "6px 10px",
              }}
            >
              {stats.total} event{stats.total === 1 ? "" : "s"}
            </span>
            <span
              style={{
                background: "rgba(124,92,255,0.12)",

                border: "1px solid rgba(124,92,255,0.35)",

                color: "#b3a1ff",

                borderRadius: 8,

                padding: "6px 10px",
              }}
            >
              {stats.hot} selling fast
            </span>
            <span
              style={{
                background: "rgba(80,220,160,0.1)",

                border: "1px solid rgba(80,220,160,0.3)",

                color: "#6fe0b0",

                borderRadius: 8,

                padding: "6px 10px",
              }}
            >
              {stats.free} free entry
            </span>
          </div>

          <div
            style={{
              marginTop: 14,

              background:
                "linear-gradient(100deg, rgba(124,92,255,0.16), rgba(255,92,168,0.1))",

              border: "1px solid rgba(124,92,255,0.3)",

              borderRadius: 12,

              padding: "11px 13px",

              display: "flex",

              gap: 10,

              alignItems: "flex-start",
            }}
          >
            <Sparkles size={16} color="#7C5CFF" style={{ marginTop: 1 }} />
            <div
              style={{
                fontFamily: "Inter, sans-serif",

                fontSize: 12,

                lineHeight: 1.5,

                color: "var(--text-2)",
              }}
            >
              <b style={{ color: "var(--text)" }}>First time?</b> Open any event
              for the full schedule, ticket tiers and who's going — then tap the
              bookmark to save it for later.
            </div>
          </div>
        </div>

        {filtered.length === 0 ? (
          <div
            style={{
              margin: "32px 20px",

              padding: "32px 20px",

              background: "var(--surface)",

              border: "1px dashed var(--border)",

              borderRadius: 16,

              textAlign: "center",
            }}
          >
            <div
              style={{
                width: 52,

                height: 52,

                borderRadius: "50%",

                background: "rgba(124,92,255,0.12)",

                display: "flex",

                alignItems: "center",

                justifyContent: "center",

                margin: "0 auto 14px",

                color: "#7C5CFF",
              }}
            >
              <Calendar size={22} />
            </div>
            <div
              style={{
                fontFamily: "Space Grotesk, sans-serif",

                fontSize: 16,

                fontWeight: 600,

                color: "var(--text)",

                marginBottom: 6,
              }}
            >
              No events match that yet
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",

                fontSize: 13,

                color: "var(--muted)",

                lineHeight: 1.6,

                marginBottom: 16,
              }}
            >
              Try another city or category — new events land every week.
            </div>
            <button
              onClick={clearFilters}
              style={{
                background: "#7C5CFF",

                border: "none",

                borderRadius: 10,

                padding: "11px 20px",

                color: "#fff",

                fontSize: 14,

                fontFamily: "Inter, sans-serif",

                fontWeight: 600,

                cursor: "pointer",
              }}
            >
              Clear filters
            </button>
          </div>
        ) : (
          <>
            {hero && (
              <div style={{ padding: "18px 20px 0" }}>
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

                      fontWeight: 600,

                      color: "var(--text)",
                    }}
                  >
                    Featured
                  </span>
                  <span
                    style={{
                      fontFamily: "Inter, sans-serif",

                      fontSize: 12,

                      color: "var(--muted)",
                    }}
                  >
                    Hand-picked for you
                  </span>
                </div>

                <div
                  onClick={() => open(hero)}
                  style={{
                    position: "relative",

                    borderRadius: 18,

                    overflow: "hidden",

                    border: "1px solid var(--border)",

                    cursor: "pointer",
                  }}
                >
                  <img
                    src={hero.img}
                    alt={hero.title}
                    style={{
                      width: "100%",

                      height: 190,

                      objectFit: "cover",

                      display: "block",
                    }}
                  />
                  <div
                    style={{
                      position: "absolute",

                      inset: 0,

                      background:
                        "linear-gradient(to bottom, rgba(0,0,0,0.35) 0%, rgba(0,0,0,0.1) 35%, rgba(10,10,12,0.95) 100%)",
                    }}
                  />
                  <span
                    style={{
                      position: "absolute",

                      top: 12,

                      left: 12,

                      fontSize: 10,

                      fontWeight: 700,

                      letterSpacing: 1,

                      color: "#fff",

                      background: TAG_COLORS[hero.tag],

                      padding: "4px 9px",

                      borderRadius: 6,

                      fontFamily: "Inter, sans-serif",
                    }}
                  >
                    {hero.tag.toUpperCase()}
                  </span>
                  <button
                    onClick={(e) => {
                      e.stopPropagation()

                      toggleSave(hero.id)
                    }}
                    style={{
                      position: "absolute",

                      top: 10,

                      right: 10,

                      width: 32,

                      height: 32,

                      borderRadius: 10,

                      background: "rgba(18,18,20,0.7)",

                      border: "1px solid rgba(255,255,255,0.14)",

                      display: "flex",

                      alignItems: "center",

                      justifyContent: "center",

                      cursor: "pointer",

                      color: saved.includes(hero.id) ? "#7C5CFF" : "#fff",
                    }}
                  >
                    <Bookmark
                      size={15}
                      fill={saved.includes(hero.id) ? "#7C5CFF" : "none"}
                    />
                  </button>

                  <div
                    style={{
                      position: "absolute",

                      left: 14,

                      right: 14,

                      bottom: 14,
                    }}
                  >
                    <div
                      style={{
                        display: "flex",

                        alignItems: "center",

                        gap: 6,

                        fontFamily: "Inter, sans-serif",

                        fontSize: 11,

                        color: "#b3a1ff",

                        fontWeight: 600,

                        marginBottom: 5,
                      }}
                    >
                      <Zap size={12} fill="#b3a1ff" /> Featured event
                    </div>
                    <div
                      style={{
                        fontFamily: "Space Grotesk, sans-serif",

                        fontSize: 19,

                        fontWeight: 700,

                        color: "#fff",

                        lineHeight: 1.2,

                        marginBottom: 6,
                      }}
                    >
                      {hero.title}
                    </div>
                    <div
                      style={{
                        display: "flex",

                        alignItems: "center",

                        gap: 6,

                        fontFamily: "Inter, sans-serif",

                        fontSize: 12,

                        color: "var(--text-2)",

                        marginBottom: 10,
                      }}
                    >
                      <Calendar size={13} color="var(--muted)" />{" "}
                      {hero.dateLabel}
                      <span style={{ color: "var(--border-3)" }}>·</span>
                      <MapPin size={13} color="var(--muted)" /> {hero.city}
                    </div>
                    <div
                      style={{
                        display: "flex",

                        alignItems: "center",

                        justifyContent: "space-between",
                      }}
                    >
                      <span
                        style={{
                          background: "rgba(255,255,255,0.1)",

                          border: "1px solid rgba(255,255,255,0.16)",

                          color: "#fff",

                          fontSize: 11,

                          fontFamily: "Inter, sans-serif",

                          fontWeight: 600,

                          padding: "5px 9px",

                          borderRadius: 7,
                        }}
                      >
                        {daysUntil(hero.start) > 0
                          ? `Starts in ${daysUntil(hero.start)} days`
                          : "Happening now"}
                      </span>
                      <span
                        style={{
                          display: "flex",

                          alignItems: "center",

                          gap: 6,

                          color: "#fff",

                          fontFamily: "Space Grotesk, sans-serif",

                          fontSize: 15,

                          fontWeight: 700,
                        }}
                      >
                        {money(hero.price)}
                        <span
                          style={{
                            width: 26,

                            height: 26,

                            borderRadius: "50%",

                            background: "#7C5CFF",

                            display: "flex",

                            alignItems: "center",

                            justifyContent: "center",
                          }}
                        >
                          <ChevronRight size={15} color="#fff" />
                        </span>
                      </span>
                    </div>
                  </div>
                </div>
              </div>
            )}

            {groups.map(([month, list]) => (
              <div key={month} style={{ padding: "20px 20px 0" }}>
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

                      fontWeight: 600,

                      color: "var(--text)",
                    }}
                  >
                    {month}
                  </span>
                  <span
                    style={{
                      fontFamily: "Inter, sans-serif",

                      fontSize: 12,

                      color: "var(--muted)",
                    }}
                  >
                    {list.length} event{list.length === 1 ? "" : "s"}
                  </span>
                </div>

                <div
                  style={{ display: "flex", flexDirection: "column", gap: 10 }}
                >
                  {list.map((e) => {
                    const left = daysUntil(e.start)

                    const scarce = e.tickets.find((t) => t.left !== undefined)

                    return (
                      <div
                        key={e.id}
                        onClick={() => open(e)}
                        style={{
                          background: "var(--surface)",

                          border: "1px solid var(--border)",

                          borderRadius: 14,

                          padding: 10,

                          display: "flex",

                          gap: 12,

                          cursor: "pointer",
                        }}
                      >
                        <div
                          style={{
                            position: "relative",

                            width: 92,

                            height: 92,

                            flex: "0 0 92px",

                            borderRadius: 11,

                            overflow: "hidden",

                            background: "var(--surface-2)",
                          }}
                        >
                          <img
                            src={e.img}
                            alt={e.title}
                            style={{
                              width: "100%",

                              height: "100%",

                              objectFit: "cover",
                            }}
                          />
                          <span
                            style={{
                              position: "absolute",

                              left: 5,

                              bottom: 5,

                              background: "rgba(10,10,12,0.82)",

                              border: "1px solid rgba(255,255,255,0.14)",

                              borderRadius: 6,

                              padding: "2px 6px",

                              fontSize: 9,

                              fontWeight: 700,

                              letterSpacing: 0.6,

                              color: "#fff",

                              fontFamily: "Inter, sans-serif",
                            }}
                          >
                            {e.dayBadge}
                          </span>
                        </div>

                        <div
                          style={{
                            flex: 1,

                            minWidth: 0,

                            display: "flex",

                            flexDirection: "column",
                          }}
                        >
                          <div
                            style={{
                              display: "flex",

                              alignItems: "center",

                              gap: 6,

                              marginBottom: 4,
                            }}
                          >
                            <span
                              style={{
                                fontSize: 9,

                                fontWeight: 700,

                                letterSpacing: 0.5,

                                color: TAG_COLORS[e.tag],

                                background: `${TAG_COLORS[e.tag]}1f`,

                                border: `1px solid ${TAG_COLORS[e.tag]}44`,

                                borderRadius: 5,

                                padding: "2px 6px",

                                fontFamily: "Inter, sans-serif",
                              }}
                            >
                              {e.tag.toUpperCase()}
                            </span>
                            {e.hot && (
                              <span
                                style={{
                                  fontSize: 9,

                                  fontWeight: 700,

                                  color: "#FF6B5C",

                                  background: "rgba(255,107,92,0.12)",

                                  borderRadius: 5,

                                  padding: "2px 6px",

                                  fontFamily: "Inter, sans-serif",
                                }}
                              >
                                SELLING FAST
                              </span>
                            )}
                          </div>

                          <div
                            style={{
                              fontFamily: "Space Grotesk, sans-serif",

                              fontSize: 14.5,

                              fontWeight: 600,

                              color: "var(--text)",

                              lineHeight: 1.25,

                              marginBottom: 4,
                            }}
                          >
                            {e.title}
                          </div>

                          <div
                            style={{
                              display: "flex",

                              alignItems: "center",

                              gap: 5,

                              fontFamily: "Inter, sans-serif",

                              fontSize: 11.5,

                              color: "var(--muted)",

                              marginBottom: 3,
                            }}
                          >
                            <MapPin size={12} color="#7C5CFF" />
                            <span
                              style={{
                                overflow: "hidden",

                                textOverflow: "ellipsis",

                                whiteSpace: "nowrap",
                              }}
                            >
                              {e.venue}, {e.city}
                            </span>
                          </div>

                          <div
                            style={{
                              display: "flex",

                              alignItems: "center",

                              justifyContent: "space-between",

                              marginTop: "auto",

                              paddingTop: 6,
                            }}
                          >
                            <div
                              style={{
                                display: "flex",

                                alignItems: "center",

                                gap: 5,
                              }}
                            >
                              <div style={{ display: "flex" }}>
                                {avatars.slice(0, 3).map((a, i) => (
                                  <img
                                    key={a}
                                    src={a}
                                    alt=""
                                    style={{
                                      width: 17,

                                      height: 17,

                                      borderRadius: "50%",

                                      objectFit: "cover",

                                      border: "1.5px solid var(--surface)",

                                      marginLeft: i === 0 ? 0 : -6,
                                    }}
                                  />
                                ))}
                              </div>
                              <span
                                style={{
                                  fontFamily: "Inter, sans-serif",

                                  fontSize: 10.5,

                                  color: "var(--muted)",
                                }}
                              >
                                {e.attending.toLocaleString()} going
                              </span>
                            </div>
                            <div
                              style={{
                                display: "flex",

                                alignItems: "center",

                                gap: 4,

                                fontFamily: "Space Grotesk, sans-serif",

                                fontSize: 14,

                                fontWeight: 700,

                                color:
                                  e.price === 0 ? "#6fe0b0" : "var(--text)",
                              }}
                            >
                              {money(e.price)}
                              <ChevronRight size={14} color="var(--muted)" />
                            </div>
                          </div>

                          {(left <= 21 || scarce?.left !== undefined) && (
                            <div
                              style={{
                                marginTop: 7,

                                fontFamily: "Inter, sans-serif",

                                fontSize: 10,

                                color: left <= 21 ? "#FF6B5C" : "var(--muted)",

                                display: "flex",

                                alignItems: "center",

                                gap: 5,
                              }}
                            >
                              <Clock size={11} />
                              {left <= 21
                                ? left > 0
                                  ? `Starts in ${left} days`
                                  : "Happening now"
                                : `${scarce?.left?.toLocaleString()} tickets left`}
                            </div>
                          )}
                        </div>
                      </div>
                    )
                  })}
                </div>
              </div>
            ))}
          </>
        )}

        <div
          style={{
            padding: "24px 20px 28px",

            textAlign: "center",

            fontFamily: "Inter, sans-serif",

            fontSize: 12,

            color: "var(--muted-3)",
          }}
        >
          More events are added every week ·{" "}
          <button
            type="button"
            onClick={() => setCalOpen(true)}
            style={{
              background: "transparent",

              border: "none",

              padding: 0,

              fontFamily: "Inter, sans-serif",

              fontSize: 12,

              fontWeight: 600,

              color: "#7C5CFF",

              cursor: "pointer",

              textDecoration: "underline",

              textUnderlineOffset: 3,
            }}
          >
            See the full calendar
          </button>
        </div>
      </div>

      {calOpen && (
        <FullCalendarSheet
          events={events}
          onClose={() => setCalOpen(false)}
          onSelect={(e) => {
            setCalOpen(false)

            open(e)
          }}
        />
      )}
    </div>
  )
}

function EventDetail({
  event,

  saved,

  onToggleSave,

  onBack,

  onOpen,

  tierIndex,

  setTierIndex,
}: {
  event: EventItem

  saved: boolean

  onToggleSave: () => void

  onBack: () => void

  onOpen: (e: EventItem) => void

  tierIndex: number

  setTierIndex: (i: number) => void
}) {
  const left = daysUntil(event.start)

  const similar = events

    .filter((e) => e.id !== event.id)

    .sort((a) => (a.tag === event.tag ? -1 : 1))

    .slice(0, 4)

  const tier = event.tickets[tierIndex] ?? event.tickets[0]

  const [sheet, setSheet] = useState<null | "calendar" | "map">(null)

  return (
    <div
      className="flex flex-col h-full"
      style={{
        background: "var(--app-bg)",

        position: "relative",

        overflow: "hidden",
      }}
    >
      <div className="flex-1 overflow-y-auto">
        <div style={{ position: "relative", height: 210 }}>
          <img
            src={event.img}
            alt={event.title}
            style={{ width: "100%", height: "100%", objectFit: "cover" }}
          />
          <div
            style={{
              position: "absolute",

              inset: 0,

              background:
                "linear-gradient(to bottom, rgba(0,0,0,0.55) 0%, rgba(0,0,0,0.1) 40%, var(--app-bg) 100%)",
            }}
          />
          <button
            onClick={onBack}
            style={{
              position: "absolute",

              top: 44,

              left: 16,

              background: "rgba(18,18,20,0.75)",

              border: "1px solid rgba(255,255,255,0.14)",

              borderRadius: 11,

              padding: 8,

              cursor: "pointer",

              color: "#fff",

              display: "flex",
            }}
          >
            <ChevronLeft size={18} />
          </button>
          <div
            style={{
              position: "absolute",

              top: 44,

              right: 16,

              display: "flex",

              gap: 8,
            }}
          >
            <button
              style={{
                background: "rgba(18,18,20,0.75)",

                border: "1px solid rgba(255,255,255,0.14)",

                borderRadius: 11,

                padding: 8,

                cursor: "pointer",

                color: saved ? "#7C5CFF" : "#fff",

                display: "flex",
              }}
            >
              <Bookmark size={17} fill={saved ? "#7C5CFF" : "none"} />
            </button>
            <button
              style={{
                background: "rgba(18,18,20,0.75)",

                border: "1px solid rgba(255,255,255,0.14)",

                borderRadius: 11,

                padding: 8,

                cursor: "pointer",

                color: "#fff",

                display: "flex",
              }}
            >
              <Share2 size={17} />
            </button>
          </div>

          <div
            style={{ position: "absolute", left: 20, bottom: 14, right: 20 }}
          >
            <span
              style={{
                fontSize: 10,

                fontWeight: 700,

                letterSpacing: 0.8,

                color: "#fff",

                background: TAG_COLORS[event.tag],

                padding: "4px 9px",

                borderRadius: 6,

                fontFamily: "Inter, sans-serif",
              }}
            >
              {event.tag.toUpperCase()}
            </span>
          </div>
        </div>

        <div className="px-5 pb-6" style={{ marginTop: -4 }}>
          <h2
            style={{
              fontFamily: "Space Grotesk, sans-serif",

              fontSize: 23,

              fontWeight: 700,

              color: "var(--text)",

              margin: "0 0 8px",

              lineHeight: 1.2,
            }}
          >
            {event.title}
          </h2>

          <div
            style={{
              display: "flex",

              alignItems: "center",

              gap: 7,

              fontFamily: "Inter, sans-serif",

              fontSize: 12.5,

              color: "var(--muted)",

              marginBottom: 16,
            }}
          >
            <Users size={14} color="#7C5CFF" />
            {event.attending.toLocaleString()} going
            <span style={{ color: "var(--border-3)" }}>·</span>
            {event.dateLabel}
          </div>

          <div
            style={{
              display: "grid",

              gridTemplateColumns: "repeat(3, 1fr)",

              gap: 8,

              marginBottom: 16,
            }}
          >
            {[
              {
                label: left > 0 ? "Days to go" : "Status",

                value: left > 0 ? `${left}` : "Live",

                sub: left > 0 ? "until doors" : "in progress",
              },

              {
                label: "Doors open",

                value: event.doors.split(" – ")[0],

                sub: event.doors.split(" – ")[1] ?? "",
              },

              {
                label: "Tickets from",

                value: money(event.price),

                sub: event.price === 0 ? "free entry" : "per person",
              },
            ].map((b) => (
              <div
                key={b.label}
                style={{
                  background: "var(--surface)",

                  border: "1px solid var(--border)",

                  borderRadius: 12,

                  padding: "11px 10px",

                  textAlign: "center",
                }}
              >
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",

                    fontSize: 9.5,

                    letterSpacing: 0.5,

                    color: "var(--muted)",

                    textTransform: "uppercase",

                    marginBottom: 4,
                  }}
                >
                  {b.label}
                </div>
                <div
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",

                    fontSize: 17,

                    fontWeight: 700,

                    color:
                      b.label === "Tickets from" && event.price === 0
                        ? "#6fe0b0"
                        : "var(--text)",
                  }}
                >
                  {b.value}
                </div>
                <div
                  style={{
                    fontFamily: "Inter, sans-serif",

                    fontSize: 9.5,

                    color: "var(--muted-3)",
                  }}
                >
                  {b.sub}
                </div>
              </div>
            ))}
          </div>

          <div
            style={{
              display: "flex",

              flexDirection: "column",

              gap: 9,

              marginBottom: 18,
            }}
          >
            {[
              {
                icon: <Calendar size={15} />,

                text: `${event.dateLabel} · ${event.doors}`,

                hint: "Calendar",

                onClick: () => setSheet("calendar"),
              },

              {
                icon: <MapPin size={15} />,

                text: `${event.venue}, ${event.city}`,

                hint: "View map",

                onClick: () => setSheet("map"),
              },

              {
                icon: <Building2 size={15} />,

                text: `Hosted by ${event.organizer.name}`,

                hint: "",

                onClick: null,
              },
            ].map((r, i) => (
              <button
                key={i}
                type="button"
                onClick={r.onClick ?? undefined}
                style={{
                  display: "flex",

                  alignItems: "center",

                  gap: 11,

                  fontFamily: "Inter, sans-serif",

                  fontSize: 13.5,

                  color: "var(--muted-2)",

                  background: "transparent",

                  border: "none",

                  borderRadius: 10,

                  padding: "3px 6px",

                  margin: "-3px -6px",

                  width: "calc(100% + 12px)",

                  textAlign: "left",

                  cursor: r.onClick ? "pointer" : "default",
                }}
              >
                <span
                  style={{
                    width: 30,

                    height: 30,

                    borderRadius: 9,

                    background: "rgba(124,92,255,0.12)",

                    color: "#7C5CFF",

                    display: "flex",

                    alignItems: "center",

                    justifyContent: "center",

                    flex: "0 0 30px",
                  }}
                >
                  {r.icon}
                </span>
                <span style={{ flex: 1, minWidth: 0 }}>{r.text}</span>
                {r.onClick && (
                  <span
                    style={{
                      display: "flex",

                      alignItems: "center",

                      gap: 2,

                      fontSize: 11.5,

                      fontWeight: 600,

                      color: "#7C5CFF",

                      whiteSpace: "nowrap",
                    }}
                  >
                    {r.hint}
                    <ChevronRight size={14} />
                  </span>
                )}
              </button>
            ))}
          </div>

          <Section title="About this event" />
          {event.about.map((p, i) => (
            <p
              key={i}
              style={{
                fontFamily: "Inter, sans-serif",

                fontSize: 14,

                color: "var(--muted-2)",

                lineHeight: 1.7,

                margin: "0 0 12px",
              }}
            >
              {p}
            </p>
          ))}

          <Section title="What you'll get" />
          <div
            style={{
              display: "grid",

              gridTemplateColumns: "1fr 1fr",

              gap: 8,

              marginBottom: 20,
            }}
          >
            {event.highlights.map((h) => (
              <div
                key={h}
                style={{
                  background: "var(--surface)",

                  border: "1px solid var(--border)",

                  borderRadius: 12,

                  padding: "11px 10px",

                  display: "flex",

                  gap: 8,

                  alignItems: "flex-start",
                }}
              >
                <span
                  style={{
                    width: 18,

                    height: 18,

                    borderRadius: "50%",

                    background: "rgba(111,224,176,0.14)",

                    color: "#6fe0b0",

                    display: "flex",

                    alignItems: "center",

                    justifyContent: "center",

                    flex: "0 0 18px",

                    marginTop: 1,
                  }}
                >
                  <Check size={11} strokeWidth={3} />
                </span>
                <span
                  style={{
                    fontFamily: "Inter, sans-serif",

                    fontSize: 12,

                    color: "var(--text-2)",

                    lineHeight: 1.45,
                  }}
                >
                  {h}
                </span>
              </div>
            ))}
          </div>

          <Section title="Schedule" />
          <div
            style={{
              background: "var(--surface)",

              border: "1px solid var(--border)",

              borderRadius: 14,

              padding: "6px 14px",

              marginBottom: 20,
            }}
          >
            {event.schedule.map((s, i) => (
              <div
                key={s.time}
                style={{
                  display: "flex",

                  gap: 12,

                  padding: "12px 0",

                  borderTop: i === 0 ? "none" : "1px solid var(--border)",
                }}
              >
                <span
                  style={{
                    fontFamily: "Space Grotesk, sans-serif",

                    fontSize: 13,

                    fontWeight: 600,

                    color: "#7C5CFF",

                    width: 42,

                    flex: "0 0 42px",

                    paddingTop: 1,
                  }}
                >
                  {s.time}
                </span>
                <div style={{ minWidth: 0 }}>
                  <div
                    style={{
                      fontFamily: "Inter, sans-serif",

                      fontSize: 13.5,

                      fontWeight: 500,

                      color: "var(--text)",

                      lineHeight: 1.35,

                      marginBottom: 3,
                    }}
                  >
                    {s.title}
                  </div>
                  <div
                    style={{
                      fontFamily: "Inter, sans-serif",

                      fontSize: 11.5,

                      color: "var(--muted)",
                    }}
                  >
                    {s.place}
                  </div>
                </div>
              </div>
            ))}
          </div>

          <Section title="Tickets" />
          <div
            style={{
              display: "flex",

              flexDirection: "column",

              gap: 9,

              marginBottom: 20,
            }}
          >
            {event.tickets.map((t, i) => {
              const active = i === tierIndex

              return (
                <button
                  key={t.name}
                  onClick={() => setTierIndex(i)}
                  style={{
                    textAlign: "left",

                    background: active
                      ? "rgba(124,92,255,0.1)"
                      : "var(--surface)",

                    border: `1.5px solid ${
                      active ? "#7C5CFF" : "var(--border)"
                    }`,

                    borderRadius: 13,

                    padding: "13px 14px",

                    cursor: "pointer",

                    display: "flex",

                    alignItems: "center",

                    gap: 12,
                  }}
                >
                  <span
                    style={{
                      width: 18,

                      height: 18,

                      borderRadius: "50%",

                      border: `2px solid ${
                        active ? "#7C5CFF" : "var(--border-strong)"
                      }`,

                      display: "flex",

                      alignItems: "center",

                      justifyContent: "center",

                      flex: "0 0 18px",
                    }}
                  >
                    {active && (
                      <span
                        style={{
                          width: 8,

                          height: 8,

                          borderRadius: "50%",

                          background: "#7C5CFF",
                        }}
                      />
                    )}
                  </span>
                  <span style={{ flex: 1, minWidth: 0 }}>
                    <span
                      style={{
                        display: "block",

                        fontFamily: "Space Grotesk, sans-serif",

                        fontSize: 14,

                        fontWeight: 600,

                        color: "var(--text)",

                        marginBottom: 3,
                      }}
                    >
                      {t.name}
                    </span>
                    <span
                      style={{
                        display: "block",

                        fontFamily: "Inter, sans-serif",

                        fontSize: 11.5,

                        color: t.left ? "#FF6B5C" : "var(--muted)",
                      }}
                    >
                      {t.left ? `${t.left.toLocaleString()} left · ` : ""}
                      {t.note}
                    </span>
                  </span>
                  <span
                    style={{
                      fontFamily: "Space Grotesk, sans-serif",

                      fontSize: 16,

                      fontWeight: 700,

                      color: t.price === 0 ? "#6fe0b0" : "var(--text)",
                    }}
                  >
                    {money(t.price)}
                  </span>
                </button>
              )
            })}
          </div>

          <Section title="Organizer" />
          <div
            style={{
              background: "var(--surface)",

              border: "1px solid var(--border)",

              borderRadius: 14,

              padding: 14,

              display: "flex",

              alignItems: "center",

              gap: 12,

              marginBottom: 20,
            }}
          >
            <img
              src={event.organizer.avatar}
              alt={event.organizer.name}
              style={{
                width: 44,

                height: 44,

                borderRadius: "50%",

                objectFit: "cover",
              }}
            />
            <div style={{ flex: 1, minWidth: 0 }}>
              <div
                style={{
                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 14.5,

                  fontWeight: 600,

                  color: "var(--text)",

                  marginBottom: 3,
                }}
              >
                {event.organizer.name}
              </div>
              <div
                style={{
                  fontFamily: "Inter, sans-serif",

                  fontSize: 11.5,

                  color: "var(--muted)",

                  display: "flex",

                  alignItems: "center",

                  gap: 5,
                }}
              >
                <Megaphone size={12} /> {event.organizer.events}
              </div>
            </div>
            <button
              style={{
                background: "transparent",

                border: "1.5px solid #7C5CFF",

                color: "#7C5CFF",

                borderRadius: 9,

                padding: "8px 16px",

                fontFamily: "Inter, sans-serif",

                fontSize: 12.5,

                fontWeight: 600,

                cursor: "pointer",
              }}
            >
              Follow
            </button>
          </div>

          <Section title="More like this" />
          <div
            style={{
              display: "flex",

              gap: 10,

              overflowX: "auto",

              margin: "0 -20px",

              padding: "0 20px 4px",
            }}
          >
            {similar.map((e) => (
              <div
                key={e.id}
                onClick={() => onOpen(e)}
                style={{
                  flex: "0 0 158px",

                  background: "var(--surface)",

                  border: "1px solid var(--border)",

                  borderRadius: 13,

                  overflow: "hidden",

                  cursor: "pointer",
                }}
              >
                <img
                  src={e.img}
                  alt={e.title}
                  style={{
                    width: "100%",

                    height: 84,

                    objectFit: "cover",

                    display: "block",
                  }}
                />
                <div style={{ padding: "9px 10px 11px" }}>
                  <div
                    style={{
                      fontFamily: "Space Grotesk, sans-serif",

                      fontSize: 12.5,

                      fontWeight: 600,

                      color: "var(--text)",

                      lineHeight: 1.3,

                      marginBottom: 4,

                      display: "-webkit-box",

                      WebkitLineClamp: 2,

                      WebkitBoxOrient: "vertical",

                      overflow: "hidden",
                    }}
                  >
                    {e.title}
                  </div>
                  <div
                    style={{
                      fontFamily: "Inter, sans-serif",

                      fontSize: 10.5,

                      color: "var(--muted)",

                      display: "flex",

                      justifyContent: "space-between",
                    }}
                  >
                    <span>{e.city}</span>
                    <span style={{ color: "#7C5CFF", fontWeight: 600 }}>
                      {money(e.price)}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      <div
        style={{
          background: "rgba(18,18,20,0.96)",

          backdropFilter: "blur(10px)",

          borderTop: "1px solid var(--border)",

          padding: "13px 20px 16px",

          display: "flex",

          alignItems: "center",

          gap: 12,

          flex: "0 0 auto",
        }}
      >
        <div style={{ flex: 1, minWidth: 0 }}>
          <div
            style={{
              fontFamily: "Inter, sans-serif",

              fontSize: 10.5,

              color: "var(--muted)",

              marginBottom: 2,
            }}
          >
            {tier.name}
          </div>
          <div
            style={{
              fontFamily: "Space Grotesk, sans-serif",

              fontSize: 19,

              fontWeight: 700,

              color: tier.price === 0 ? "#6fe0b0" : "var(--text)",

              lineHeight: 1.1,
            }}
          >
            {money(tier.price)}
            {tier.price > 0 && (
              <span
                style={{
                  fontSize: 11,

                  fontWeight: 400,

                  color: "var(--muted)",

                  fontFamily: "Inter, sans-serif",
                }}
              >
                {" "}
                + fees
              </span>
            )}
          </div>
        </div>
        <button
          style={{
            background: "linear-gradient(135deg, #8F72FF 0%, #7C5CFF 100%)",

            border: "none",

            borderRadius: 12,

            padding: "14px 22px",

            color: "#fff",

            fontSize: 15,

            fontFamily: "Space Grotesk, sans-serif",

            fontWeight: 600,

            cursor: "pointer",

            display: "flex",

            alignItems: "center",

            gap: 8,

            boxShadow: "0 8px 22px rgba(124,92,255,0.35)",
          }}
        >
          <Ticket size={17} />
          {tier.price === 0 ? "Reserve spot" : "Get tickets"}
        </button>
      </div>

      {sheet === "calendar" && (
        <CalendarSheet
          title={event.title}
          subtitle={`${event.dateLabel} · ${event.doors}`}
          anchor={event.start}
          range={[event.start, event.end]}
          event={event}
          onClose={() => setSheet(null)}
        />
      )}
      {sheet === "map" && (
        <MapSheet event={event} onClose={() => setSheet(null)} />
      )}
    </div>
  )
}

const MONTH_NAMES = [
  "January",

  "February",

  "March",

  "April",

  "May",

  "June",

  "July",

  "August",

  "September",

  "October",

  "November",

  "December",
]

const DOW = ["S", "M", "T", "W", "T", "F", "S"]

const daysInMonth = (y: number, m: number) => new Date(y, m, 0).getDate()

const isoOf = (d: Date) =>
  `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`

const navBtn = {
  width: 32,

  height: 32,

  borderRadius: 9,

  background: "var(--surface-2)",

  border: "1px solid var(--border)",

  color: "var(--text-2)",

  display: "flex",

  alignItems: "center",

  justifyContent: "center",

  cursor: "pointer",

  padding: 0,
}

const primaryBtn: CSSProperties = {
  background: "linear-gradient(135deg, #8F72FF 0%, #7C5CFF 100%)",

  border: "none",

  borderRadius: 12,

  padding: "13px 16px",

  color: "#fff",

  fontSize: 14,

  fontFamily: "Space Grotesk, sans-serif",

  fontWeight: 600,

  cursor: "pointer",

  display: "flex",

  alignItems: "center",

  justifyContent: "center",

  gap: 8,

  width: "100%",
}

const ghostBtn: CSSProperties = {
  background: "var(--surface)",

  border: "1px solid var(--border)",

  borderRadius: 12,

  padding: "13px 16px",

  color: "var(--text)",

  fontSize: 14,

  fontFamily: "Space Grotesk, sans-serif",

  fontWeight: 600,

  cursor: "pointer",

  display: "flex",

  alignItems: "center",

  justifyContent: "center",

  gap: 8,

  width: "100%",

  textDecoration: "none",
}

function SheetShell({
  title,

  subtitle,

  onClose,

  children,
}: {
  title: string

  subtitle?: string

  onClose: () => void

  children: ReactNode
}) {
  return (
    <div
      className="sheet-in"
      style={{
        position: "absolute",

        inset: 0,

        zIndex: 56,

        background: "var(--app-bg)",

        display: "flex",

        flexDirection: "column",
      }}
    >
      <div
        style={{
          display: "flex",

          alignItems: "center",

          gap: 10,

          padding: "44px 16px 12px",

          borderBottom: "1px solid var(--border)",

          flex: "0 0 auto",
        }}
      >
        <button type="button" onClick={onClose} style={navBtn}>
          <ChevronLeft size={18} />
        </button>
        <div style={{ flex: 1, minWidth: 0 }}>
          <div
            style={{
              fontFamily: "Space Grotesk, sans-serif",

              fontSize: 16,

              fontWeight: 600,

              color: "var(--text)",

              lineHeight: 1.2,
            }}
          >
            {title}
          </div>
          {subtitle && (
            <div
              style={{
                fontFamily: "Inter, sans-serif",

                fontSize: 11.5,

                color: "var(--muted)",

                marginTop: 3,

                overflow: "hidden",

                textOverflow: "ellipsis",

                whiteSpace: "nowrap",
              }}
            >
              {subtitle}
            </div>
          )}
        </div>
        <button type="button" onClick={onClose} style={navBtn}>
          <X size={17} />
        </button>
      </div>
      <div
        className="flex-1 overflow-y-auto"
        style={{ padding: "16px 16px 24px" }}
      >
        {children}
      </div>
    </div>
  )
}

function MonthCalendar({
  year,

  month,

  range,

  marks,

  selected,

  onDayClick,

  onPrev,

  onNext,
}: {
  year: number

  month: number

  range?: [string, string]

  marks?: Record<string, number>

  selected?: string

  onDayClick?: (iso: string) => void

  onPrev: () => void

  onNext: () => void
}) {
  const firstDow = new Date(year, month - 1, 1).getDay()

  const total = daysInMonth(year, month)

  const cells: (number | null)[] = []

  for (let i = 0; i < firstDow; i++) cells.push(null)

  for (let d = 1; d <= total; d++) cells.push(d)

  while (cells.length % 7 !== 0) cells.push(null)

  const todayIso = isoOf(new Date())

  return (
    <div
      style={{
        background: "var(--surface)",

        border: "1px solid var(--border)",

        borderRadius: 16,

        padding: "12px 8px 14px",
      }}
    >
      <div
        style={{
          display: "flex",

          alignItems: "center",

          justifyContent: "space-between",

          padding: "0 6px 10px",
        }}
      >
        <button
          type="button"
          onClick={onPrev}
          style={navBtn}
          aria-label="Previous month"
        >
          <ChevronLeft size={17} />
        </button>
        <div
          style={{
            fontFamily: "Space Grotesk, sans-serif",

            fontSize: 15,

            fontWeight: 600,

            color: "var(--text)",
          }}
        >
          {MONTH_NAMES[month - 1]} {year}
        </div>
        <button
          type="button"
          onClick={onNext}
          style={navBtn}
          aria-label="Next month"
        >
          <ChevronRight size={17} />
        </button>
      </div>

      <div
        style={{
          display: "grid",

          gridTemplateColumns: "repeat(7, 1fr)",

          marginBottom: 4,
        }}
      >
        {DOW.map((d, i) => (
          <div
            key={i}
            style={{
              textAlign: "center",

              fontSize: 10.5,

              fontWeight: 600,

              color: "var(--muted-3)",

              padding: "4px 0",
            }}
          >
            {d}
          </div>
        ))}
      </div>

      <div
        style={{
          display: "grid",

          gridTemplateColumns: "repeat(7, 1fr)",

          gap: 2,
        }}
      >
        {cells.map((d, i) => {
          if (d === null) return <span key={i} />

          const iso = `${year}-${pad2(month)}-${pad2(d)}`

          const isEdge = iso === range?.[0] || iso === range?.[1]

          const inRange = !!range && iso >= range[0] && iso <= range[1]

          const isToday = iso === todayIso

          const isSelected = iso === selected

          const count = marks?.[iso] ?? 0

          const filled = isEdge || isSelected

          return (
            <button
              key={i}
              type="button"
              onClick={onDayClick ? () => onDayClick(iso) : undefined}
              style={{
                position: "relative",

                height: 40,

                padding: 0,

                borderRadius: 10,

                border: isToday
                  ? filled
                    ? "1.5px solid #fff2"
                    : "1.5px solid #7C5CFF"
                  : "1.5px solid transparent",

                background: filled
                  ? "#7C5CFF"
                  : inRange
                    ? "rgba(124,92,255,0.18)"
                    : "transparent",

                color: filled ? "#fff" : "var(--text)",

                fontFamily: "Inter, sans-serif",

                fontSize: 13,

                fontWeight: inRange ? 600 : 500,

                cursor: onDayClick ? "pointer" : "default",

                display: "flex",

                flexDirection: "column",

                alignItems: "center",

                justifyContent: "center",

                gap: 2,
              }}
            >
              {d}
              {count > 0 && (
                <span
                  style={{
                    width: 4,

                    height: 4,

                    borderRadius: "50%",

                    background: filled ? "#fff" : "#7C5CFF",
                  }}
                />
              )}
            </button>
          )
        })}
      </div>
    </div>
  )
}

function CalendarSheet({
  title,

  subtitle,

  anchor,

  range,

  event,

  onClose,
}: {
  title: string

  subtitle: string

  anchor: string

  range: [string, string]

  event: EventItem

  onClose: () => void
}) {
  const [y, setY] = useState(Number(anchor.slice(0, 4)))

  const [m, setM] = useState(Number(anchor.slice(5, 7)))

  const shift = (n: number) => {
    const d = new Date(y, m - 1 + n, 1)

    setY(d.getFullYear())

    setM(d.getMonth() + 1)
  }

  return (
    <SheetShell title="Add to calendar" subtitle={title} onClose={onClose}>
      <MonthCalendar
        year={y}
        month={m}
        range={range}
        onPrev={() => shift(-1)}
        onNext={() => shift(1)}
      />

      <div
        style={{
          marginTop: 14,

          background: "var(--surface)",

          border: "1px solid var(--border)",

          borderRadius: 14,

          padding: 14,
        }}
      >
        <div
          style={{
            display: "flex",

            alignItems: "center",

            gap: 10,

            marginBottom: 10,
          }}
        >
          <span
            style={{
              width: 32,

              height: 32,

              borderRadius: 9,

              background: "rgba(124,92,255,0.12)",

              color: "#7C5CFF",

              display: "flex",

              alignItems: "center",

              justifyContent: "center",

              flex: "0 0 32px",
            }}
          >
            <Calendar size={16} />
          </span>
          <div style={{ minWidth: 0 }}>
            <div
              style={{
                fontFamily: "Inter, sans-serif",

                fontSize: 13.5,

                fontWeight: 600,

                color: "var(--text)",
              }}
            >
              {event.dateLabel}
            </div>
            <div
              style={{
                fontFamily: "Inter, sans-serif",

                fontSize: 12,

                color: "var(--muted)",
              }}
            >
              {subtitle}
            </div>
          </div>
        </div>
        <div
          style={{
            display: "flex",

            alignItems: "center",

            gap: 7,

            fontFamily: "Inter, sans-serif",

            fontSize: 12,

            color: "var(--muted-2)",
          }}
        >
          <MapPin size={13} color="#7C5CFF" />
          {event.venue}, {event.city}
        </div>
      </div>

      <div
        style={{
          display: "flex",

          flexDirection: "column",

          gap: 9,

          marginTop: 14,
        }}
      >
        <button
          type="button"
          style={primaryBtn}
          onClick={() => downloadIcs(event)}
        >
          <Download size={16} />
          Download .ics file
        </button>
        <a
          href={googleCalendarUrl(event)}
          target="_blank"
          rel="noreferrer"
          style={ghostBtn}
        >
          <Calendar size={16} color="#7C5CFF" />
          Add to Google Calendar
        </a>
      </div>

      <p
        style={{
          fontFamily: "Inter, sans-serif",

          fontSize: 11.5,

          color: "var(--muted-3)",

          lineHeight: 1.6,

          margin: "12px 2px 0",
        }}
      >
        The .ics file opens in Apple Calendar, Outlook and any calendar app.
        Times are stored as venue-local and repeat reminders stay on your
        device.
      </p>
    </SheetShell>
  )
}

function MapSheet({
  event,

  onClose,
}: {
  event: EventItem

  onClose: () => void
}) {
  const [copied, setCopied] = useState(false)

  const address = `${event.venue}, ${event.city}`

  const copy = async () => {
    try {
      await navigator.clipboard.writeText(address)

      setCopied(true)

      setTimeout(() => setCopied(false), 1600)
    } catch {
      setCopied(false)
    }
  }

  return (
    <SheetShell title="Location" subtitle={address} onClose={onClose}>
      <div
        style={{
          position: "relative",

          height: 300,

          borderRadius: 16,

          overflow: "hidden",

          border: "1px solid var(--border)",

          background: "var(--surface-2)",
        }}
      >
        <iframe
          title={`Map of ${event.venue}`}
          src={mapEmbedUrl(event)}
          style={{
            width: "100%",

            height: "100%",

            border: 0,

            filter: "grayscale(0.15)",
          }}
          loading="lazy"
        />
        <div
          style={{
            position: "absolute",

            left: 10,

            bottom: 10,

            background: "rgba(18,18,20,0.85)",

            border: "1px solid rgba(255,255,255,0.14)",

            borderRadius: 9,

            padding: "6px 10px",

            fontFamily: "Inter, sans-serif",

            fontSize: 11,

            color: "#fff",

            display: "flex",

            alignItems: "center",

            gap: 6,

            pointerEvents: "none",
          }}
        >
          <MapPin size={12} color="#7C5CFF" />
          {event.city}
        </div>
      </div>

      <div
        style={{
          marginTop: 14,

          background: "var(--surface)",

          border: "1px solid var(--border)",

          borderRadius: 14,

          padding: 14,
        }}
      >
        <div
          style={{
            fontFamily: "Space Grotesk, sans-serif",

            fontSize: 15,

            fontWeight: 600,

            color: "var(--text)",

            marginBottom: 5,
          }}
        >
          {event.venue}
        </div>
        <div
          style={{
            fontFamily: "Inter, sans-serif",

            fontSize: 13,

            color: "var(--muted-2)",

            marginBottom: 8,
          }}
        >
          {event.city}
        </div>
        <div
          style={{
            fontFamily: "Inter, sans-serif",

            fontSize: 11.5,

            color: "var(--muted-3)",
          }}
        >
          {event.lat.toFixed(4)}, {event.lng.toFixed(4)} · {event.tz}
        </div>
      </div>

      <div
        style={{
          display: "flex",

          flexDirection: "column",

          gap: 9,

          marginTop: 14,
        }}
      >
        <a
          href={directionsUrl(event)}
          target="_blank"
          rel="noreferrer"
          style={primaryBtn}
        >
          <Navigation size={16} />
          Get directions
        </a>
        <a
          href={`https://www.google.com/maps/search/?api=1&query=${event.lat},${event.lng}`}
          target="_blank"
          rel="noreferrer"
          style={ghostBtn}
        >
          <ExternalLink size={16} color="#7C5CFF" />
          Open in Google Maps
        </a>
        <button type="button" style={ghostBtn} onClick={copy}>
          <MapPin size={16} color="#7C5CFF" />
          {copied ? "Address copied" : "Copy address"}
        </button>
      </div>
    </SheetShell>
  )
}

function FullCalendarSheet({
  events,

  onSelect,

  onClose,
}: {
  events: EventItem[]

  onSelect: (e: EventItem) => void

  onClose: () => void
}) {
  const now = new Date()

  const [y, setY] = useState(now.getFullYear())

  const [m, setM] = useState(now.getMonth() + 1)

  const [selected, setSelected] = useState<string | null>(null)

  const shift = (n: number) => {
    const d = new Date(y, m - 1 + n, 1)

    setY(d.getFullYear())

    setM(d.getMonth() + 1)

    setSelected(null)
  }

  const marks = useMemo(() => {
    const map: Record<string, number> = {}

    events.forEach((e) => {
      let d = e.start

      while (d <= e.end) {
        map[d] = (map[d] ?? 0) + 1

        d = addDays(d, 1)
      }
    })

    return map
  }, [events])

  const monthStart = `${y}-${pad2(m)}-01`

  const monthEnd = `${y}-${pad2(m)}-${pad2(daysInMonth(y, m))}`

  const list = (
    selected
      ? events.filter((e) => e.start <= selected && e.end >= selected)
      : events.filter((e) => e.start <= monthEnd && e.end >= monthStart)
  )

    .sort((a, b) => (a.start < b.start ? -1 : 1))

  const goToday = () => {
    setY(now.getFullYear())

    setM(now.getMonth() + 1)

    setSelected(null)
  }

  return (
    <SheetShell
      title="Calendar"
      subtitle={
        selected
          ? `Events on ${selected}`
          : `${MONTH_NAMES[m - 1]} ${y} · ${events.length} upcoming`
      }
      onClose={onClose}
    >
      <MonthCalendar
        year={y}
        month={m}
        marks={marks}
        selected={selected ?? undefined}
        onDayClick={(iso) => setSelected((s) => (s === iso ? null : iso))}
        onPrev={() => shift(-1)}
        onNext={() => shift(1)}
      />

      <div
        style={{
          display: "flex",

          alignItems: "center",

          justifyContent: "space-between",

          margin: "12px 2px 10px",
        }}
      >
        <span
          style={{
            fontFamily: "Space Grotesk, sans-serif",

            fontSize: 14,

            fontWeight: 600,

            color: "var(--text)",
          }}
        >
          {selected
            ? list.length
              ? "On this day"
              : "Nothing scheduled"
            : "This month"}
        </span>
        <div style={{ display: "flex", gap: 8 }}>
          {selected && (
            <button
              type="button"
              onClick={() => setSelected(null)}
              style={{
                ...navBtn,

                width: "auto",

                padding: "0 11px",

                fontSize: 11.5,

                fontFamily: "Inter, sans-serif",

                fontWeight: 600,
              }}
            >
              Clear day
            </button>
          )}
          <button
            type="button"
            onClick={goToday}
            style={{
              ...navBtn,

              width: "auto",

              padding: "0 11px",

              fontSize: 11.5,

              fontFamily: "Inter, sans-serif",

              fontWeight: 600,

              color: "#7C5CFF",
            }}
          >
            Today
          </button>
        </div>
      </div>

      <div style={{ display: "flex", flexDirection: "column", gap: 9 }}>
        {list.length === 0 && (
          <div
            style={{
              background: "var(--surface)",

              border: "1px dashed var(--border)",

              borderRadius: 14,

              padding: "24px 16px",

              textAlign: "center",

              fontFamily: "Inter, sans-serif",

              fontSize: 13,

              color: "var(--muted)",
            }}
          >
            No events {selected ? "on this day" : "this month"} — swipe to
            another month.
          </div>
        )}
        {list.map((e) => (
          <button
            key={e.id}
            type="button"
            onClick={() => onSelect(e)}
            style={{
              display: "flex",

              alignItems: "center",

              gap: 11,

              background: "var(--surface)",

              border: "1px solid var(--border)",

              borderRadius: 13,

              padding: 10,

              cursor: "pointer",

              textAlign: "left",

              width: "100%",
            }}
          >
            <span
              style={{
                width: 46,

                flex: "0 0 46px",

                background: "rgba(124,92,255,0.12)",

                border: "1px solid rgba(124,92,255,0.3)",

                borderRadius: 10,

                padding: "6px 0",

                textAlign: "center",

                fontFamily: "Space Grotesk, sans-serif",
              }}
            >
              <span
                style={{
                  display: "block",

                  fontSize: 9.5,

                  fontWeight: 600,

                  letterSpacing: 0.6,

                  color: "#b3a1ff",
                }}
              >
                {MONTH_NAMES[Number(e.start.slice(5, 7)) - 1]

                  .slice(0, 3)

                  .toUpperCase()}
              </span>
              <span
                style={{
                  display: "block",

                  fontSize: 16,

                  fontWeight: 700,

                  color: "var(--text)",

                  lineHeight: 1.1,
                }}
              >
                {Number(e.start.slice(8, 10))}
              </span>
            </span>
            <span style={{ flex: 1, minWidth: 0 }}>
              <span
                style={{
                  display: "block",

                  fontFamily: "Space Grotesk, sans-serif",

                  fontSize: 13.5,

                  fontWeight: 600,

                  color: "var(--text)",

                  lineHeight: 1.3,

                  marginBottom: 3,
                }}
              >
                {e.title}
              </span>
              <span
                style={{
                  display: "block",

                  fontFamily: "Inter, sans-serif",

                  fontSize: 11.5,

                  color: "var(--muted)",

                  overflow: "hidden",

                  textOverflow: "ellipsis",

                  whiteSpace: "nowrap",
                }}
              >
                {e.dateLabel} · {e.city}
              </span>
            </span>
            <ChevronRight size={16} color="var(--muted)" />
          </button>
        ))}
      </div>
    </SheetShell>
  )
}

function Section({ title }: { title: string }) {
  return (
    <div
      style={{
        display: "flex",

        alignItems: "center",

        gap: 8,

        margin: "0 0 11px",
      }}
    >
      <span
        style={{
          fontFamily: "Space Grotesk, sans-serif",

          fontSize: 15,

          fontWeight: 600,

          color: "var(--text)",
        }}
      >
        {title}
      </span>
      <span
        style={{
          flex: 1,

          height: 1,

          background: "linear-gradient(to right, var(--border), transparent)",
        }}
      />
    </div>
  )
}
