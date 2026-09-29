import { useState } from "react"
import SplashScreen from "./screens/SplashScreen"
import OnboardingScreen from "./screens/OnboardingScreen"
import LoginScreen from "./screens/LoginScreen"
import RegisterScreen from "./screens/RegisterScreen"
import SelectInterestsScreen from "./screens/SelectInterestsScreen"
import AllFandomsScreen from "./screens/AllFandomsScreen"
import MainApp from "./screens/MainApp"
import WallpaperLayer from "./components/WallpaperLayer"

export type Screen = "splash" | "onboarding" | "login" | "register" | "select-interests" | "all-fandoms" | "app"

export default function App() {
  const [screen, setScreen] = useState<Screen>("splash")
  const [interestsFrom, setInterestsFrom] = useState<Screen>("login")

  const go = (s: Screen) => setScreen(s)

  return (
    <div
      className="flex items-center justify-center min-h-dvh"
      style={{ background: "var(--app-bg-deep)" }}
    >
      <div
        className="relative overflow-hidden flex flex-col isolate"
        style={{
          width: 390,
          height: 844,
          background: "var(--app-bg)",
          borderRadius: 44,
          boxShadow: "0 0 0 1px var(--border), 0 32px 80px rgba(0,0,0,0.8)",
        }}
      >
        <WallpaperLayer />
        {screen === "splash" && (
          <SplashScreen onDone={() => go("onboarding")} />
        )}
        {screen === "onboarding" && (
          <OnboardingScreen
            onDone={() => go("login")}
            onBack={() => go("splash")}
          />
        )}
        {screen === "login" && (
          <LoginScreen
            onLogin={() => {
              setInterestsFrom("login")
              go("select-interests")
            }}
            onRegister={() => go("register")}
            onBack={() => go("onboarding")}
          />
        )}
        {screen === "register" && (
          <RegisterScreen
            onDone={() => {
              setInterestsFrom("register")
              go("select-interests")
            }}
            onLogin={() => go("login")}
            onBack={() => go("login")}
          />
        )}
        {screen === "select-interests" && (
          <SelectInterestsScreen
            onDone={() => go("app")}
            onBack={() => go(interestsFrom)}
            onSeeAll={() => go("all-fandoms")}
          />
        )}
        {screen === "all-fandoms" && (
          <AllFandomsScreen
            onDone={() => go("app")}
            onBack={() => go("select-interests")}
          />
        )}
        {screen === "app" && <MainApp />}
      </div>
    </div>
  )
}
