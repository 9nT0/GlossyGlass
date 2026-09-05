# GlossyGlass v2.0

Advanced liquid glass UI for **iOS 17 – 18.x**

Made by **Killswitch**  
Discord: [discord.gg/SxtnSjDvu](https://discord.gg/SxtnSjDvu)

---

### What’s New in v2

**Profile & Button System**
- Multiple detection strategies (stack + side-by-side buttons)
- Overcrowding protection
- Option to completely hide the Glass button
- Aggressive retry timing + orientation handling

**Glass Engine**
- Continuous corner curves (iOS 26 style)
- Edge highlights that simulate refraction
- Separate Light / Dark intensity
- Frosted / Clear / Tinted modes
- Optional chromatic aberration
- Better specular gloss

**Advanced Controls**
- Presets: Clean · Default · Heavy · Performance
- Dual intensity sliders (Light + Dark)
- Show / hide Glass button
- Debug overlay
- Reset Styles Only
- Settings export / import

**Technical**
- Public API (`GlossyGlassAPI`) for other tweaks
- First-launch welcome guide
- Stronger crash protection
- Improved injection reliability

**Navigation & Tab Bar**
- Improved material selection
- Continuous corner feel
- Soft floating shadows

---

### How to Use

1. Go to **Releases**
2. Download the latest `GlossyGlass.dylib`
3. Inject with **Ksign / Esign / Scarlet / Feather**

### Settings
Tap the **Glass** button on the profile page (or call the public API).

### Public API (for other tweaks)

```swift
GlossyGlassAPI.shared.setEnabled(true)
GlossyGlassAPI.shared.applyPreset("Heavy")
GlossyGlassAPI.shared.presentSettings()
GlossyGlassAPI.shared.exportSettings()
```

### Notes
- Fully compatible with iOS 17 and iOS 18.x
- v1 bugs addressed
- More improvements coming in future updates
