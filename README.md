<p align="center">
  <img src="4Xstg.jpg" alt="GlossyGlass" width="100%"/>
</p>

<h1 align="center">GlossyGlass</h1>
<p align="center">
  <b>Advanced liquid glass UI for iOS 17 – 18.x</b><br>
  Made by <b>Killswitch</b> · <a href="https://discord.gg/Sxtn7SjDvu">discord.gg/Sxtn7SjDvu</a>
</p>

---

### Preview

<p align="center">
  <img src="ukFMS.jpg" alt="Settings Panel" width="45%"/>
  &nbsp;&nbsp;
  <img src="GPhWY.jpg" alt="Glass Tab Bar" width="45%"/>
</p>

---

### Features

- Automatic start on load  
- Runtime Settings Panel (“Glass” button)  
- Continuous corner curves (modern iOS style)  
- Separate Light & Dark intensity  
- Frosted / Clear / Tinted glass modes  
- Presets: **Clean · Default · Heavy · Performance**  
- Smarter button detection with overcrowding protection  
- Option to hide the Glass button  
- Long-press lift effect for messages  
- Adaptive Light / Dark Mode  
- Public API for other tweaks  
- Settings export / import  
- Debug overlay  
- Fully compatible with **iOS 17 & 18.x**

---

### How to Use

1. Go to the [Releases](../../releases) page  
2. Download the latest `GlossyGlass.dylib`  
3. Inject it using your preferred sideloading app  

**Supported:** Ksign · Esign · Scarlet · Feather · and any major sideloading app

---

### Settings

Tap the **Glass** button on the profile page to open the panel.

| Section       | Controls                                      |
|---------------|-----------------------------------------------|
| **Appearance**    | Style, Intensity, Opacity                     |
| **Effects**       | Blur, Vibrancy, Noise, Light Bloom            |
| **Advanced**      | Corner Radius, Saturation, Dimming            |
| **Master**        | Enable, Lightweight Mode, Hide Glass Button   |

---

### Public API (optional)

```swift
GlossyGlassAPI.shared.setEnabled(true)
GlossyGlassAPI.shared.applyPreset("Heavy")
GlossyGlassAPI.shared.presentSettings()
