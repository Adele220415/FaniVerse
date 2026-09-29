import { useTheme } from "../theme"
import { useWallpaper, wallpaperScrim } from "../wallpaper"

export default function WallpaperLayer() {
  const wallpaper = useWallpaper()
  const theme = useTheme()

  if (!wallpaper) return null

  return (
    <div
      aria-hidden
      style={{
        position: "absolute",
        inset: 0,
        zIndex: -1,
        backgroundImage: `${wallpaperScrim(wallpaper, theme)}, url("${wallpaper.src}")`,
        backgroundSize: "cover",
        backgroundPosition: "center",
        backgroundRepeat: "no-repeat",
      }}
    />
  )
}
