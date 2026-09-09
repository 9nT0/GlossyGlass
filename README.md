<p align="center">
  <img src="Cover.jpg" alt="GlossyGlass" width="100%"/>
</p>

<h1 align="center">GlossyGlass</h1>

<p align="center">
  <b>Liquid glass. Your rules.</b><br>
  Glass UI engine for modern iOS
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-3.6.1-blueviolet?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/iOS-17%20—%2018.x%20recommended-black?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/iOS%2016-supported-lightgrey?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/API-v361-purple?style=for-the-badge"/>
</p>

<p align="center">
  Made by <b>Killswitch</b> · <a href="https://discord.gg/Sxtn7SjDvu">discord.gg/Sxtn7SjDvu</a>
</p>

---

<p align="center">
  <img src="4Xstg.jpg" width="100%" alt="Hero"/>
</p>

## Overview

GlossyGlass is a **dylib glass engine** for sideloaded apps. Optimized for **Instagram**, including when Instagram runs inside **Live Container** / other app containers, with a generic fallback for other UIKit hosts.

| Primary | Secondary |
|---------|-----------|
| Instagram (fast path, richer detection) | Other apps (generic injection + warning if unsupported) |
| **iOS 17 – 18.x** (recommended) | iOS 16 (supported, not recommended) |

---

## Gallery

<p align="center">
  <img src="ukFMS.jpg" width="46%" alt="Settings"/>
  &nbsp;
  <img src="GPhWY.jpg" width="46%" alt="Tab Bar"/>
</p>

---

## Features

### Visual
- Full layer stack: blur · vibrancy · dimming · tint · noise · gloss · bloom · edge highlight · border  
- Frosted / Clear / Tinted · Quick Themes · Focus Mode · Live Tint  
- Continuous corners · Light/Dark intensity · master opacity  
- Smoother springs (v3.6) · Reduce Motion / Reduce Transparency  

### Access
- **Glass** button when injection succeeds  
- **Hold Messages 3 seconds** → settings (not global, not profile)
- **Force Show Glass Button** + floating fallback if UI reloads
- Remembers last button position
- Active Nav / Tab / Buttons / Cards styling
- Optional auto screen profiles  
- Diagnostics · Re-detect · Safe Mode  

### Reliability
- Instagram-first scan + generic fallback  
- Last-good-host memory for faster reattach  
- Soft retries (no permanent give-up)  
- Unsupported-app warning when generic mode fails  

### Developers
- **Public API v36** — configuration, themes, focus, live tint, diagnostics JSON, host summary, injection reset  

---

## Install

1. Open [Releases](../../releases)  
2. Download `GlossyGlass.dylib`  
3. Inject with Ksign, Esign, Scarlet, Feather, or any compatible dylib injector  

---

## Public API (v36)

```swift
let api = GlossyGlassAPI.shared

api.setEnabled(true)
api.applyPreset("Heavy")
api.applyQuickTheme("Midnight")
api.setFocusMode(true)
api.setLiveTint(.systemBlue)

api.presentSettings()
api.forceRedetect()
api.resetInjectionState()

api.isInstagramHost()
api.hostAppSummary()
print(api.diagnosticsJSON())

api.exportSettingsJSON()
api.importSettingsJSON(json)
```

---


---

## Live Container

1. Import `GlossyGlass.dylib` into the **app-specific** tweak folder for Instagram (Private app if needed)
2. Assign that folder to the Instagram guest
3. Enable **TweakLoader** / Ellekit injection for that app
4. Open Instagram fully and wait **15–30 seconds** on first launch
5. If the Glass button is missing → enable **Force Show Glass Button** (auto-enabled after failed attaches in containers)
6. Diagnostics → **Copy** and paste into Discord if you need support

Container mode uses a UI ready-gate, denser retries, and stronger Instagram guest detection.

## Version

**3.6.1** (container compatibility)  
Recommended: **iOS 17 – 18.x** · Also runs on **iOS 16**

---

<p align="center">
  <b>Made by Killswitch</b><br>
  <a href="https://discord.gg/Sxtn7SjDvu">discord.gg/Sxtn7SjDvu</a>
</p>
