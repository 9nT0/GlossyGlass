# GlossyGlass

Clean glossy glass for **iOS 17 – 18.x**

### Features
- Automatic start on load (no manual call needed)
- Full Preferences system
- Runtime Settings Panel (“Glass” button)
- Smoother spring animations
- iOS 26-style long-press lift for messages
- Auto-places settings button next to other tweak buttons on profile
- Adaptive Light / Dark
- Lightweight mode + individual element toggles
- Fully compatible with iOS 17 and iOS 18.x

### Automatic Behaviour
When the dylib is injected it will:
1. Start automatically after launch
2. Try several times to find profile button stacks
3. Add the “Glass” settings button beside existing ones (aiming for 6 buttons total)

### Manual API (optional)
```swift
GlassInjector.start()                    // already called automatically
GlassSettingsPresenter.present()         // open settings
GlassLongPress.enable(on: someView)      // nice long-press effect
```

### Preferences
```swift
GlassPreferences.shared.isEnabled = true
GlassPreferences.shared.glossIntensity = 0.55
GlassPreferences.shared.lightweightMode = true
// etc.
```

### Building
Go in Actions then build

### Supported Sideloading apps
Ksign
Esign
Scarlet
Feather
And any major sideloading apps


v1 any bugs will be fixed in v2
