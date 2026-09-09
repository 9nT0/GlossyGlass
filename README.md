<p align="center">
  <img src="Cover.jpg" alt="GlossyGlass" width="100%"/>
</p>

<h1 align="center">GlossyGlass</h1>
<p align="center"><b>Liquid glass engine for modern iOS</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/version-4.0.1-blueviolet?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/API-v40-purple?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/iOS-17%20—%2018.x-black?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Live%20Container-ready-green?style=for-the-badge"/>
</p>

<p align="center">
  Made by <b>Killswitch</b> · <a href="https://discord.gg/Sxtn7SjDvu">discord.gg/Sxtn7SjDvu</a>
</p>

---

## Overview

GlossyGlass is a **dylib glass engine** for sideloaded apps. Optimized for **Instagram**, including when Instagram runs inside **Live Container** / other app containers, with a generic fallback for other UIKit hosts.

| Primary | Secondary |
|---------|-----------|
| Instagram (fast path, richer detection) | Other apps (generic injection + warning if unsupported) |
| **iOS 17 – 18.x** (recommended) | iOS 16 (supported, not recommended) |
| Native glass path on **iOS 26+** when `UIGlassEffect` exists | Layered blur · tint · gloss · edge stack on 17–18.x |

---

## Features

### Visual
- Full layer stack: blur · vibrancy · dimming · tint · noise · gloss · bloom · edge highlight · border
- Frosted / Clear / Tinted · Quick Themes (Liquid · Midnight · Crystal · Smoke)
- Focus Mode · Live Tint · continuous corners
- Separate Light / Dark intensity · master opacity
- Reduce Motion / Reduce Transparency aware

### Access
- **Glass** button when injection succeeds
- **Hold Messages / Direct 1 second** → settings
- **Force Show Glass Button** + floating fallback if UI reloads
- Remembers last button position

### Chrome
- Navigation bar · Tab bar · Buttons · Cards (each toggle is wired)

### Systems (v4)
- **GlassReadyGate** — wait for real UI before inject
- **GlassLocator** — multi-strategy host + messages finder
- **GlassHealthChecker** — prefs / UI / attach / container checks
- **GlassSyncBus** — debounced prefs ↔ chrome sync
- **GlassNativeBridge** — system glass on iOS 26+ when present
- **GlassThemeEngine** — Liquid / Heavy recipes
- **GlassWelcome** — first-run status sequence
- **GlassUpdateChecker** — GitHub latest release probe
- **GlassLoader.m** — ObjC constructor + `+load` entry (required for many injectors)

### Developers
- **Public API v40** — configuration, themes, focus, live tint, diagnostics JSON, host summary, injection reset

---

## Install

1. Open **Releases** → download `GlossyGlass.dylib`
2. Inject with Ksign, Esign, Scarlet, Feather, or any compatible dylib injector

### Live Container

1. Put `GlossyGlass.dylib` in the **guest app’s** Tweaks folder
2. **Recommended:** also install [DylibLoader](https://github.com/9nT0/Dylib-Loader) as `0_DylibLoader.dylib` in the same folder
3. Enable TweakLoader for that guest
4. Open the guest fully; wait for the welcome sequence on first launch (often 15–30s)
5. If the control is missing, enable **Force Show Glass Button**

> Outside Live Container, inject **only** GlossyGlass. Do not inject DylibLoader on normal sideload installs.

---

## Settings

Tap **Glass** (or hold Messages/Direct for 1 second).

| Area | Controls |
|------|----------|
| Themes | Liquid · Midnight · Crystal · Smoke |
| Material | Style, intensity, opacity, blur, vibrancy, noise, bloom, edge |
| Advanced | Corner radius, saturation, dimming, spring response/damping |
| Chrome | Navigation · Tab · Buttons · Cards |
| Placement | Hide button · Force Show |
| System | Lightweight · Haptics · Focus · Safe mode · Export / Import · Diagnostics |

Every toggle drives the glass or chrome path — no dead controls.

---

## Public API (v40)

```swift
let api = GlossyGlassAPI.shared

api.setEnabled(true)
api.applyPreset("Heavy")
api.applyQuickTheme("Midnight")
api.applyLiquidGlassLook()
api.setFocusMode(true)
api.setLiveTint(.systemBlue)

api.presentSettings()
api.presentWelcome()
api.forceRedetect()
api.resetInjectionState()
```

`GlossyGlassAPI.apiVersion` → **40** · `apiVersionString` → **4.0.1**

---

## Architecture

| Module | Role |
|--------|------|
| GlassLoader (+ `.m`) | Bootstrap, constructors, DylibLoader entry symbols |
| GlassReadyGate | Multi-waiter UI readiness (LC-critical) |
| GlassInjector | Scored attach, Messages hold, floating fallback |
| GlassLocator | Host / messages discovery |
| GlassView | Material layer stack |
| GlassStyleApplicator | Nav / tab / button / card chrome |
| GlassPreferences | Persistent settings + migration |
| GlassPublicAPI | External control surface |
| GlassDiagnostics | Copy-paste support dump |

---

## Support

- Discord: [discord.gg/Sxtn7SjDvu](https://discord.gg/Sxtn7SjDvu)
- Diagnostics → **Copy** in-app if you need help

---

<p align="center"><b>Killswitch</b></p>
