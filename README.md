# GlossyGlass

Clean glossy glass UI for **iOS 17 – 18.x**

Made by **Killswitch**  
Discord: [discord.gg/SxtnSjDvu](https://discord.gg/SxtnSjDvu)

---

### Features
- Automatic start on load (no manual call needed)
- Full Preferences system
- Runtime Settings Panel (“Glass” button)
- Smoother spring animations
- iOS 26-style long-press lift for messages
- Auto-places settings button next to other tweak buttons on profile
- Adaptive Light / Dark Mode
- Lightweight mode + individual element toggles
- Fully compatible with iOS 17 and iOS 18.x

### Automatic Behaviour
When the dylib is injected it will:
1. Start automatically after launch
2. Try several times to find profile button stacks
3. Add the “Glass” settings button beside existing ones (aiming for 6 buttons total)

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

### Manual API (Optional)
```swift
GlassInjector.start()                    // already called automatically
GlassSettingsPresenter.present()         // open settings
GlassLongPress.enable(on: someView)      // nice long-press effect
