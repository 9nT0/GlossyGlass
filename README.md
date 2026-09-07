<p align="center">
  <img src="Cover.png" alt="GlossyGlass Cover" width="100%"/>
</p>

<h1 align="center">GlossyGlass</h1>

<p align="center">
  <b>Liquid glass. Your rules.</b><br>
  Advanced glass UI engine for <b>iOS 17 – 18.x</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-3.1-blueviolet?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/iOS-17%20—%2018.x-black?style=for-the-badge"/>
  <img src="https://img.shields.io/badge/API-v31-purple?style=for-the-badge"/>
</p>

<p align="center">
  Made by <b>Killswitch</b> · <a href="https://discord.gg/Sxtn7SjDvu">discord.gg/Sxtn7SjDvu</a>
</p>

---

<p align="center">
  <img src="4Xstg.jpg" width="100%" alt="Hero"/>
</p>

---

## Why GlossyGlass?

Not another blur overlay. A **full glass engine** — material, specular, noise, bloom, edge light — with a settings panel that actually drives every layer.

| | |
|---|---|
| **Looks** | Frosted · Clear · Tinted · Quick Themes |
| **Feels** | Spring animations · long-press lift · haptics |
| **Controls** | Live intensity · opacity · per-effect toggles |
| **Survives** | Multi-strategy injection · 3s hold backup · Safe Mode |

---

## Gallery

<p align="center">
  <img src="ukFMS.jpg" width="46%" alt="Settings"/>
  &nbsp;
  <img src="GPhWY.jpg" width="46%" alt="Tab Bar"/>
</p>

---

## Features

### Visual engine
- Layer stack: blur → vibrancy → dimming → tint → noise → gloss → bloom → edge highlight → border  
- Continuous corner curves  
- Separate Light / Dark intensity  
- Opacity as master multiplier  
- Reduce Transparency & Reduce Motion aware  

### Control
- Runtime **Glass** button on profile  
- **Hold 3 seconds** anywhere → open settings  
- Presets: Clean · Default · Heavy · Performance  
- **Quick Themes:** Midnight · Crystal · Smoke · Minimal  
- **Focus Mode** for reading  
- Device auto-profile on first launch  

### Reliability
- Multi-strategy injection (stack + button-row + class hints)  
- Soft retries — never permanently gives up  
- Host re-validation  
- Safe Mode · Diagnostics · Re-detect UI  

### For developers
- **Public API v31** — presets, themes, live tint, focus, config snapshot, import/export  
- `GlassAPIStateDidChange` notification  

---

## Install

1. Open [Releases](../../releases)  
2. Download `GlossyGlass.dylib`  
3. Inject with your sideloading app  

**Works with:** Ksign · Esign · Scarlet · Feather · and most dylib injectors  

---

## Settings map

| Section | What you get |
|---------|----------------|
| **Quick Themes** | Midnight · Crystal · Smoke · Minimal |
| **Presets** | Clean · Default · Heavy · Performance |
| **Appearance** | Style · Intensity · Light/Dark · Opacity |
| **Effects** | Blur · Vibrancy · Noise · Bloom · Edge |
| **Advanced** | Radius · Saturation · Dimming · Springs |
| **System** | Enable · Lightweight · Focus · Haptics · Safe Mode · Hide button |

---

## Public API (v31)

```swift
let api = GlossyGlassAPI.shared

api.setEnabled(true)
api.applyPreset("Heavy")
api.applyQuickTheme("Midnight")
api.setFocusMode(true)
api.setLiveTint(.systemBlue)
api.clearLiveTint()

api.setStyle("Clear")
api.setIntensity(0.8)
api.setOpacity(0.9)

api.presentSettings()
api.presentDiagnostics()
api.forceRedetect()

let json = api.exportSettingsJSON()
api.importSettingsJSON(json ?? "{}")

api.applyScreenProfile(.messages)
```

---

## Notes

- Version **3.1** (hotfix)  
- No build required — grab the dylib from Releases  
- First launch applies a device-based preset; change anything after  

---

<p align="center">
  <b>Made by Killswitch</b><br>
  <a href="https://discord.gg/Sxtn7SjDvu">Join the Discord</a>
</p>
