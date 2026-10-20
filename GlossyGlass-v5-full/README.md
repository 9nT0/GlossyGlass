# GlossyGlass v5

**Real liquid-glass engine for Instagram**  
iOS 26 feel · Pill tab bar · DMs · Reels · Stories · Profiles · No overlays

<p align="center">
  <img src="https://img.shields.io/badge/version-5.1.0-blue" alt="Version">
  <img src="https://img.shields.io/badge/iOS-16%20–%2018.x-lightgrey" alt="iOS">
  <img src="https://img.shields.io/badge/target-Instagram-E1306C" alt="Target">
</p>

---

## What v5 does

- **Tab bar** → floating iOS 26 pill / capsule, buttons properly aligned  
- **Navigation bar** → continuous liquid glass  
- **DMs** → glass surfaces + circular call buttons  
- **Reels / Stories / Profiles** → chrome treated with the same liquid material  
- **Long-press / context menus** → softer glass feel  
- **Hover & press animations** → spring scale on interactive elements  
- **No floating overlays** — material is applied to the real views

---

## Glossy Mode

Main toggle in the settings panel:

- **ON** → full iOS 26 liquid look, stronger materials, remade icons, new panel  
- **OFF** → clean base liquid glass

---

## Access

Hold **Messages / Direct** for 1 second → settings

---

## Install

1. Actions → **Build iOS dylib** → download artifact  
2. Inject with Ksign / Esign / Scarlet / Feather / Live Container

---

## Architecture

```
Loader/          Bootstrap
Core/            Preferences · Material · Chrome · Ready · Animations
UI/              Settings panels · Icons
Instagram/       Locators · Hooks · DM / Reels / Profile chrome
Public/          API
```

---

## Public API

```swift
GlossyGlassAPI.shared.setGlossyMode(true)
GlossyGlassAPI.shared.setIntensity(0.92)
GlossyGlassAPI.shared.presentSettings()
```

Version **5.1.0** · API **51**
