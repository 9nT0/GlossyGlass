# GlossyGlass v5

**Clean liquid-glass engine for Instagram (and UIKit hosts)**  
Made for older phones · No overlays · True chrome ownership · iOS 26 feel

---

## What changed from v4

- Completely rewritten from zero — none of the old files are used
- **No overlay stacking** — paints the real tab bar / nav bar / buttons in place
- Stable settings panel (no more crashes)
- **Glossy Mode** toggle:
  - ON  → full iOS-26-inspired look + remade icons + new settings surface
  - OFF → clean base liquid-glass (still better than v4)
- Far fewer systems, single apply path, debounced
- Designed to feel native on iOS 16–18.x

---

## Folder structure

```
GlossyGlass-v5/
├── Loader/
│   ├── GlassLoader.m
│   └── GlassBootstrap.swift
├── Core/
│   ├── GlassPreferences.swift
│   ├── GlassMaterial.swift
│   ├── GlassChrome.swift
│   └── GlassReady.swift
├── UI/
│   ├── GlassPanel.swift
│   ├── GlassPanelGlossy.swift
│   └── GlassIcons.swift
├── Instagram/
│   ├── IGLocator.swift
│   └── IGHooks.swift
├── Public/
│   └── GlossyGlassAPI.swift
├── Package.swift
└── README.md
```

---

## How to use

1. Delete every old file from the previous repo.
2. Upload this entire `GlossyGlass-v5` folder content (or the folders themselves) to a new or cleaned GitHub repo.
3. Build the dynamic library with Xcode / the workflow of your choice.
4. Inject the resulting `.dylib` with Ksign, Esign, Scarlet, Feather, or Live Container.

### Live Container
- Place the dylib in the guest app’s Tweaks folder.
- Open Instagram fully and wait a few seconds for the readiness gate.

---

## Settings access

- Tap the Glass button (when attached)
- Or hold the Messages / Direct icon for ~1 second

---

## Glossy Mode

In the panel there is a single **Enable Glossy** switch.

- When turned **on**:
  - Stronger liquid-glass recipe
  - Icons are swapped to the remade set
  - The old settings UI is removed and a new clean panel is presented
- When turned **off**:
  - Returns to the base improved liquid-glass look
  - Normal panel is restored

---

## Architecture (v5)

| Module              | Role                                      |
|---------------------|-------------------------------------------|
| GlassLoader         | +load / constructor entry                 |
| GlassBootstrap      | Starts everything safely                  |
| GlassPreferences    | Single source of truth for all settings   |
| GlassMaterial       | Real material engine (no overlay mess)    |
| GlassChrome         | Owns tab / nav / button styling in-place  |
| GlassReady          | Simple readiness gate                     |
| GlassPanel          | Base settings panel                       |
| GlassPanelGlossy    | The new panel shown in Glossy Mode        |
| GlassIcons          | Remade icon set                           |
| IGLocator           | Finds real Instagram chrome               |
| IGHooks             | Minimal hooks                             |
| GlossyGlassAPI      | Public API for other tweaks               |

---

## Building

This is a Swift Package that produces a dynamic library.  
You still need to compile it against the iOS SDK and sign/inject it.

---

**Killswitch / community**  
Discord: discord.gg/Sxtn7SjDvu (original project)

v5 is a clean-room redesign focused on stability and real feel.
