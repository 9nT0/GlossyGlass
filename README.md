# GlossyGlass

Advanced liquid glass UI for **iOS 17 – 18.x**

Made by **Killswitch**  
Discord: [discord.gg/SxtnSjDvu](https://discord.gg/SxtnSjDvu)

---

### Features
- Automatic start on load
- Runtime Settings Panel (“Glass” button)
- Continuous corner curves (modern iOS style)
- Separate Light & Dark intensity
- Frosted / Clear / Tinted glass modes
- Presets: Clean · Default · Heavy · Performance
- Smarter button detection with overcrowding protection
- Option to hide the Glass button
- Long-press lift effect for messages
- Adaptive Light / Dark Mode
- Public API for other tweaks
- Settings export / import
- Debug overlay
- Fully compatible with iOS 17 and iOS 18.x

### How to Use
1. Go to the [Releases](../../releases) page
2. Download the latest `GlossyGlass.dylib`
3. Inject it using your preferred sideloading app

### Supported Sideloading Apps
- Ksign
- Esign
- Scarlet
- Feather
- Any major sideloading app that supports dylib injection

### Settings
Tap the **Glass** button on the profile page to open the settings panel.

### Public API (optional)
```swift
GlossyGlassAPI.shared.setEnabled(true)
GlossyGlassAPI.shared.applyPreset("Heavy")
GlossyGlassAPI.shared.presentSettings()
