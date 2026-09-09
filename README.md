
<p align="center">
  <img src="Cover.jpg" alt="GlossyGlass" width="100%"/>
</p>

<h1 align="center">GlossyGlass</h1>
<p align="center"><b>Advanced liquid glass engine for iOS 17 – 18.x</b></p>

<p align="center">
  <img src="https://img.shields.io/badge/version-4.0-blueviolet?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/API-v40-purple?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/iOS-17%20—%2018.x-black?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/Live%20Container-ready-green?style=for-the-badge"/>
</p>

<p align="center">
  Made by <b>Killswitch</b> · <a href="https://discord.gg/Sxtn7SjDvu">discord.gg/Sxtn7SjDvu</a>
</p>

---

## Overview

GlossyGlass injects a tunable liquid-glass material stack into host apps. It is optimized for Instagram (including Live Container guests), with multi-strategy injection, runtime settings, and a public API for other tweaks.

On **iOS 26+**, the engine prefers the system glass effect when available. On **17–18.x**, it uses a layered blur · tint · gloss · edge stack designed to feel close to that language.

## Features

- Automatic start on load  
- Runtime settings panel (**Glass** control)  
- Liquid / Midnight / Crystal / Smoke quick themes  
- Continuous corners · separate Light / Dark intensity  
- Frosted / Clear / Tinted styles  
- Nav bar · tab bar · buttons · cards chrome  
- Smarter host detection (avoids brand/logo stacks)  
- Messages / Direct **1s** hold → settings  
- Force Show + floating fallback when needed  
- Live Container ready-gate, health checks, locator, sync bus  
- GitHub update probe  
- Welcome loading sequence with status lines  
- Public API **v40**  
- Settings export / import · diagnostics · debug overlay  

## Install

1. Open **Releases** and download the latest `GlossyGlass.dylib`  
2. Inject with Ksign, Esign, Scarlet, Feather, or any major injector  

### Live Container

1. Place the dylib in the **app-specific** Tweaks folder for the guest app  
2. Optional: pair with **DylibLoader v1.1.0** as `0_DylibLoader.dylib`  
3. Enable TweakLoader for that app  
4. Open the guest fully; wait for the welcome sequence on first launch  
5. If the control is missing, enable **Force Show Glass Button**  

## Settings

Tap **Glass** (or hold Messages/Direct for 1 second) to open the panel.

| Area | Controls |
|------|----------|
| Themes | Liquid · Midnight · Crystal · Smoke |
| Material | Intensity, opacity, blur, vibrancy, noise, bloom, edge |
| Chrome | Navigation · Tab · Buttons · Cards |
| Placement | Hide button · Force Show |
| System | Lightweight · Safe mode · Export / Import |

## Public API

```swift
GlossyGlassAPI.shared.setEnabled(true)
GlossyGlassAPI.shared.applyLiquidGlassLook()
GlossyGlassAPI.shared.applyQuickTheme("Midnight")
GlossyGlassAPI.shared.presentSettings()
GlossyGlassAPI.shared.presentWelcome()
GlossyGlassAPI.shared.forceRedetect()
```

API version: **40** (`GlossyGlassAPI.apiVersion`).

## Architecture (v4)

| Module | Role |
|--------|------|
| GlassLocator | Host / messages discovery |
| GlassInjector | Multi-strategy attach + revalidate |
| GlassReadyGate | Wait for real UI before inject |
| GlassHealthChecker | Runtime integrity snapshot |
| GlassSyncBus | Debounced prefs ↔ chrome sync |
| GlassNativeBridge | System glass when present |
| GlassThemeEngine | Liquid recipes |
| GlassWelcome | First-run status sequence |
| GlassUpdateChecker | Latest GitHub release probe |

## Support

- **Primary:** iOS 17 – 18.x  
- **Also builds for:** iOS 16 (not recommended)  
- **Native glass path:** iOS 26+ when `UIGlassEffect` exists  

Discord: [discord.gg/Sxtn7SjDvu](https://discord.gg/Sxtn7SjDvu)

---

<p align="center"><b>Killswitch</b></p>
