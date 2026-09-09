import UIKit

@objc public class GlassSettingsButton: GlassButton {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonSetup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonSetup()
    }

    private func commonSetup() {
        setTitle("Glass", for: .normal)
        titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
        // Avoid deprecated contentEdgeInsets when configuration exists — use config on iOS 15+
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.plain()
            config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 14, bottom: 7, trailing: 14)
            config.baseForegroundColor = .label
            config.title = "Glass"
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var out = incoming
                out.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
                return out
            }
            configuration = config
        } else {
            contentEdgeInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 14)
        }
        glossIntensity = 0.72
        layer.cornerRadius = 16
        layer.cornerCurve = .continuous
        clipsToBounds = true
        addTarget(self, action: #selector(openSettings), for: .touchUpInside)
        applyChrome()
        NotificationCenter.default.addObserver(
            self, selector: #selector(applyChrome),
            name: .glassPreferencesDidChange, object: nil
        )
    }

    @objc private func applyChrome() {
        let prefs = GlassPreferences.shared
        let isDark = traitCollection.userInterfaceStyle == .dark
        let intensity = prefs.isEnabled
            ? (isDark ? prefs.darkIntensity : prefs.lightIntensity) * prefs.intensity
            : 0.4

        backgroundColor = UIColor.white.withAlphaComponent(isDark ? 0.12 + intensity * 0.10 : 0.55 + intensity * 0.15)
        layer.borderWidth = 0.6
        layer.borderColor = UIColor.white.withAlphaComponent(isDark ? 0.22 : 0.45).cgColor

        // Soft highlight
        if layer.sublayers?.contains(where: { $0.name == "gg.gloss" }) != true {
            let gloss = CAGradientLayer()
            gloss.name = "gg.gloss"
            gloss.colors = [
                UIColor.white.withAlphaComponent(isDark ? 0.28 : 0.55).cgColor,
                UIColor.white.withAlphaComponent(0.0).cgColor
            ]
            gloss.locations = [0, 0.55]
            gloss.startPoint = CGPoint(x: 0.5, y: 0)
            gloss.endPoint = CGPoint(x: 0.5, y: 1)
            gloss.frame = bounds
            gloss.cornerRadius = layer.cornerRadius
            layer.insertSublayer(gloss, at: 0)
        }
        layer.sublayers?.first(where: { $0.name == "gg.gloss" })?.frame = bounds
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.sublayers?.first(where: { $0.name == "gg.gloss" })?.frame = bounds
        layer.sublayers?.first(where: { $0.name == "gg.gloss" })?.cornerRadius = layer.cornerRadius
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyChrome()
    }

    @objc private func openSettings() {
        if GlassPreferences.shared.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        GlassSettingsPresenter.present(from: self)
    }
}

@objc public class GlassSettingsPresenter: NSObject {

    @objc public static func present(from sourceView: UIView? = nil) {
        DispatchQueue.main.async {
            let vc = GlassSettingsViewController()
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .pageSheet
            if #available(iOS 15.0, *) {
                if let sheet = nav.sheetPresentationController {
                    sheet.detents = [.medium(), .large()]
                    sheet.prefersGrabberVisible = true
                }
            }
            // Always use robust presenter (host VC or overlay window)
            GlassAppSupport.presentModally(nav, animated: true)
            NSLog("[GlossyGlass] Settings panel presented")
        }
    }
}


private class GlassSettingsViewController: UIViewController {

    private let prefs = GlassPreferences.shared

    @objc private func themeTapped(_ sender: UIButton) {
        let themes = ["Liquid", "Midnight", "Crystal", "Smoke"]
        let idx = sender.tag - 900
        guard idx >= 0, idx < themes.count else { return }
        let name = themes[idx]
        if GlassPreferences.shared.hapticsEnabled {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        if name == "Liquid" {
            GlassThemeEngine.shared.applyLiquidDefault()
        } else {
            GlossyGlassAPI.shared.applyQuickTheme(name)
        }
        GlassSyncBus.shared.requestSync(reason: "theme-\(name)")
        let alert = UIAlertController(title: "Theme", message: "\(name) applied", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private var stack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)

        let titleLabel = UILabel()
        titleLabel.text = "Glass Tweak"
        titleLabel.font = .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textAlignment = .center

        let subtitle = UILabel()
        subtitle.text = "Customize your glass experience"
        subtitle.font = .systemFont(ofSize: 12, weight: .regular)
        subtitle.textColor = .secondaryLabel
        subtitle.textAlignment = .center

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitle])
        titleStack.axis = .vertical
        titleStack.spacing = 2
        navigationItem.titleView = titleStack

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain, target: self, action: #selector(close)
        )
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset", style: .plain, target: self, action: #selector(resetDefaults)
        )

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -30),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])

        buildUI()
    }

    private func buildUI() {
        // MARK: Presets
        stack.addArrangedSubview(makeSectionHeader(title: "Presets", icon: "square.grid.2x2"))
        let presetCard = makeCard()
        let presetRow = UIStackView()
        presetRow.axis = .horizontal
        presetRow.spacing = 8
        presetRow.distribution = .fillEqually
        presetRow.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        presetRow.isLayoutMarginsRelativeArrangement = true
        for name in ["Clean", "Default", "Heavy", "Perf"] {
            let full = name == "Perf" ? "Performance" : name
            let b = UIButton(type: .system)
            b.setTitle(name, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 13, weight: .semibold)
            b.backgroundColor = prefs.preset == full ? UIColor.systemPurple.withAlphaComponent(0.25) : UIColor.tertiarySystemFill
            b.layer.cornerRadius = 8
            b.addAction(UIAction { [weak self] _ in
                self?.prefs.applyPreset(full)
                self?.reloadUI()
            }, for: .touchUpInside)
            presetRow.addArrangedSubview(b)
        }
        presetCard.addArrangedSubview(presetRow)
        stack.addArrangedSubview(presetCard)

        // MARK: Appearance
        // MARK: Quick Themes (new feature)
        stack.addArrangedSubview(makeSectionHeader(title: "Quick Themes", icon: "paintpalette"))
        let themeCard = makeCard()
        let themeRow = UIStackView()
        themeRow.axis = .horizontal
        themeRow.spacing = 8
        themeRow.distribution = .fillEqually
        themeRow.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        themeRow.isLayoutMarginsRelativeArrangement = true
        let themes = ["Liquid", "Midnight", "Crystal", "Smoke"]
        for (idx, name) in themes.enumerated() {
            let b = UIButton(type: .system)
            b.setTitle(name, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 12, weight: .semibold)
            b.backgroundColor = UIColor.tertiarySystemFill
            b.layer.cornerRadius = 10
            b.tag = 900 + idx
            b.isUserInteractionEnabled = true
            b.addTarget(self, action: #selector(themeTapped(_:)), for: .touchUpInside)
            themeRow.addArrangedSubview(b)
        }
        themeRow.isUserInteractionEnabled = true
        themeCard.isUserInteractionEnabled = true
        themeCard.addArrangedSubview(themeRow)
        stack.addArrangedSubview(themeCard)

        stack.addArrangedSubview(makeSectionHeader(title: "Appearance", icon: "sparkles"))
        let appearanceCard = makeCard()

        // Style dropdown menu
        appearanceCard.addArrangedSubview(makeLabelRow("Style", "Frosted / Clear / Tinted"))
        let styleBtn = UIButton(type: .system)
        styleBtn.setTitle("  \(prefs.style)  ▼", for: .normal)
        styleBtn.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        styleBtn.contentHorizontalAlignment = .left
        styleBtn.backgroundColor = UIColor.tertiarySystemFill
        styleBtn.layer.cornerRadius = 8
        styleBtn.heightAnchor.constraint(equalToConstant: 36).isActive = true
        if #available(iOS 14.0, *) {
            let items = ["Frosted", "Clear", "Tinted"].map { name -> UIAction in
                UIAction(title: name, state: prefs.style == name ? .on : .off) { [weak self, weak styleBtn] _ in
                    self?.prefs.style = name
                    styleBtn?.setTitle("  \(name)  ▼", for: .normal)
                }
            }
            styleBtn.menu = UIMenu(title: "Glass Style", children: items)
            styleBtn.showsMenuAsPrimaryAction = true
        }
        let styleWrap = UIStackView(arrangedSubviews: [styleBtn])
        styleWrap.layoutMargins = UIEdgeInsets(top: 4, left: 0, bottom: 10, right: 0)
        styleWrap.isLayoutMarginsRelativeArrangement = true
        appearanceCard.addArrangedSubview(styleWrap)
        appearanceCard.addArrangedSubview(makeDivider())

        appearanceCard.addArrangedSubview(makeSliderRow(title: "Intensity", subtitle: "Master multiplier", value: Float(prefs.intensity)) { [weak self] v in
            self?.prefs.intensity = CGFloat(v)
        })
        appearanceCard.addArrangedSubview(makeDivider())
        appearanceCard.addArrangedSubview(makeSliderRow(title: "Light Intensity", subtitle: "Used in Light Mode", value: Float(prefs.lightIntensity)) { [weak self] v in
            self?.prefs.lightIntensity = CGFloat(v)
        })
        appearanceCard.addArrangedSubview(makeDivider())
        appearanceCard.addArrangedSubview(makeSliderRow(title: "Dark Intensity", subtitle: "Used in Dark Mode", value: Float(prefs.darkIntensity)) { [weak self] v in
            self?.prefs.darkIntensity = CGFloat(v)
        })
        appearanceCard.addArrangedSubview(makeDivider())
        appearanceCard.addArrangedSubview(makeSliderRow(title: "Opacity", subtitle: "Master opacity", value: Float(prefs.opacity)) { [weak self] v in
            self?.prefs.opacity = CGFloat(v)
        })
        stack.addArrangedSubview(appearanceCard)

        // MARK: Effects
        stack.addArrangedSubview(makeSectionHeader(title: "Effects", icon: "water.waves"))
        let effectsCard = makeCard()
        effectsCard.addArrangedSubview(makeSwitchRow(title: "Blur", subtitle: "Background blur", isOn: prefs.blurEnabled) { [weak self] on in
            self?.prefs.blurEnabled = on
        })
        effectsCard.addArrangedSubview(makeDivider())
        effectsCard.addArrangedSubview(makeSwitchRow(title: "Vibrancy", subtitle: "Boost colors under glass", isOn: prefs.vibrancyEnabled) { [weak self] on in
            self?.prefs.vibrancyEnabled = on
        })
        effectsCard.addArrangedSubview(makeDivider())
        effectsCard.addArrangedSubview(makeSwitchRow(title: "Noise", subtitle: "Subtle grain texture", isOn: prefs.noiseEnabled) { [weak self] on in
            self?.prefs.noiseEnabled = on
        })
        effectsCard.addArrangedSubview(makeDivider())
        effectsCard.addArrangedSubview(makeSwitchRow(title: "Light Bloom", subtitle: "Soft top glow", isOn: prefs.lightBloomEnabled) { [weak self] on in
            self?.prefs.lightBloomEnabled = on
        })
        effectsCard.addArrangedSubview(makeDivider())
        effectsCard.addArrangedSubview(makeSwitchRow(title: "Edge Highlight", subtitle: "Refraction-style rim", isOn: prefs.edgeHighlightEnabled) { [weak self] on in
            self?.prefs.edgeHighlightEnabled = on
        })
        stack.addArrangedSubview(effectsCard)

        // MARK: Advanced
        stack.addArrangedSubview(makeSectionHeader(title: "Advanced", icon: "gearshape"))
        let advancedCard = makeCard()
        advancedCard.addArrangedSubview(makeSliderRow(title: "Corner Radius", subtitle: "0 – 40 pt", value: Float(prefs.cornerRadius / 40.0), displayAsPoints: 40) { [weak self] v in
            self?.prefs.cornerRadius = CGFloat(v) * 40.0
        })
        advancedCard.addArrangedSubview(makeDivider())
        advancedCard.addArrangedSubview(makeSliderRow(title: "Saturation", subtitle: "Tint richness", value: Float(prefs.saturation)) { [weak self] v in
            self?.prefs.saturation = CGFloat(v)
        })
        advancedCard.addArrangedSubview(makeDivider())
        advancedCard.addArrangedSubview(makeSliderRow(title: "Dimming", subtitle: "Darken behind glass", value: Float(prefs.dimming)) { [weak self] v in
            self?.prefs.dimming = CGFloat(v)
        })
        advancedCard.addArrangedSubview(makeDivider())
        advancedCard.addArrangedSubview(makeSliderRow(title: "Spring Response", subtitle: "Animation speed", value: Float(prefs.springResponse)) { [weak self] v in
            self?.prefs.springResponse = CGFloat(v)
        })
        advancedCard.addArrangedSubview(makeDivider())
        advancedCard.addArrangedSubview(makeSliderRow(title: "Spring Damping", subtitle: "Animation bounce", value: Float(prefs.springDamping)) { [weak self] v in
            self?.prefs.springDamping = CGFloat(v)
        })
        stack.addArrangedSubview(advancedCard)

        // MARK: System
        stack.addArrangedSubview(makeSectionHeader(title: "System", icon: "switch.2"))
        let systemCard = makeCard()
        systemCard.addArrangedSubview(makeSwitchRow(title: "Enable GlossyGlass", subtitle: "Master switch", isOn: prefs.isEnabled) { [weak self] on in
            self?.prefs.isEnabled = on
            if on { self?.prefs.safeMode = false }
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Lightweight Mode", subtitle: "Better performance", isOn: prefs.lightweightMode) { [weak self] on in
            self?.prefs.lightweightMode = on
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Haptics", subtitle: "Touch feedback", isOn: prefs.hapticsEnabled) { [weak self] on in
            self?.prefs.hapticsEnabled = on
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Focus Mode", subtitle: "Extra dim for reading", isOn: GlassLiveState.shared.focusMode) { on in
            GlossyGlassAPI.shared.setFocusMode(on)
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Hide Glass Button", subtitle: "Remove injected button", isOn: prefs.hideGlassButton) { [weak self] on in
            self?.prefs.hideGlassButton = on
            GlassInjector.forceRedetect()
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Force Show Glass Button", subtitle: "Ignore detection — always show", isOn: prefs.forceShowGlassButton) { [weak self] on in
            self?.prefs.forceShowGlassButton = on
            GlassInjector.forceRedetect()
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Auto Screen Profiles", subtitle: "Apply presets per screen", isOn: prefs.autoApplyScreenProfiles) { [weak self] on in
            self?.prefs.autoApplyScreenProfiles = on
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Safe Mode", subtitle: "Disable injection only", isOn: prefs.safeMode) { [weak self] on in
            // Safe mode only blocks injection — does NOT force isEnabled off
            self?.prefs.safeMode = on
            GlassInjector.forceRedetect()
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Navigation Bar", subtitle: nil, isOn: prefs.styleNavigationBar) { [weak self] on in
            self?.prefs.styleNavigationBar = on
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Tab Bar", subtitle: nil, isOn: prefs.styleTabBar) { [weak self] on in
            self?.prefs.styleTabBar = on
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Buttons", subtitle: nil, isOn: prefs.styleButtons) { [weak self] on in
            self?.prefs.styleButtons = on
        })
        systemCard.addArrangedSubview(makeDivider())
        systemCard.addArrangedSubview(makeSwitchRow(title: "Cards", subtitle: nil, isOn: prefs.styleCards) { [weak self] on in
            self?.prefs.styleCards = on
        })
        stack.addArrangedSubview(systemCard)

        // Actions
        let diagBtn = UIButton(type: .system)
        let changeBtn = UIButton(type: .system)
        changeBtn.setTitle("Changelog", for: .normal)
        changeBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        changeBtn.addAction(UIAction { [weak self] _ in
            let alert = UIAlertController(title: "GlossyGlass 4.0.2", message: """
• Messages 1s hold → settings
• Force Show Glass button
• Floating fallback if injection drops
• Stronger Performance preset
• Auto screen profiles (optional)
• Nav / Tab / Buttons / Cards applicator
• Smoother animations · stronger Reduce Motion
• API v36 · iOS 16+ (17–18 recommended)
""", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }, for: .touchUpInside)
        stack.addArrangedSubview(changeBtn)

        diagBtn.setTitle("Open Diagnostics", for: .normal)
        diagBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        diagBtn.addAction(UIAction { [weak self] _ in GlassDiagnostics.shared.present(from: self) }, for: .touchUpInside)
        stack.addArrangedSubview(diagBtn)

        let redetectBtn = UIButton(type: .system)
        redetectBtn.setTitle("Re-detect UI", for: .normal)
        redetectBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        redetectBtn.addAction(UIAction { _ in GlassInjector.forceRedetect() }, for: .touchUpInside)
        stack.addArrangedSubview(redetectBtn)

        let footer = UILabel()
        footer.text = "Hold Messages 1s to open settings\nGlossyGlass · Killswitch · v4.0.2"
        footer.font = .systemFont(ofSize: 11, weight: .medium)
        footer.numberOfLines = 2
        footer.textColor = .tertiaryLabel
        footer.textAlignment = .center
        stack.addArrangedSubview(footer)

        let discord = UIButton(type: .system)
        discord.setTitle("discord.gg/Sxtn7SjDvu", for: .normal)
        discord.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        discord.addTarget(self, action: #selector(openDiscord), for: .touchUpInside)
        stack.addArrangedSubview(discord)
    }

    private func reloadUI() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buildUI()
    }

    // MARK: - Helpers

    private func makeSectionHeader(title: String, icon: String) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.alignment = .center
        let image = UIImageView(image: UIImage(systemName: icon))
        image.tintColor = .systemPurple
        image.contentMode = .scaleAspectFit
        image.widthAnchor.constraint(equalToConstant: 18).isActive = true
        image.heightAnchor.constraint(equalToConstant: 18).isActive = true
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15, weight: .semibold)
        row.addArrangedSubview(image)
        row.addArrangedSubview(label)
        row.addArrangedSubview(UIView())
        return row
    }

    private func makeCard() -> UIStackView {
        let card = UIStackView()
        card.axis = .vertical
        card.spacing = 0
        card.layoutMargins = UIEdgeInsets(top: 4, left: 14, bottom: 4, right: 14)
        card.isLayoutMarginsRelativeArrangement = true
        card.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.85)
        card.layer.cornerRadius = 14
        card.clipsToBounds = true
        return card
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.separator.withAlphaComponent(0.4)
        v.heightAnchor.constraint(equalToConstant: 1 / UIScreen.main.scale).isActive = true
        return v
    }

    private func makeLabelRow(_ title: String, _ subtitle: String) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 2
        container.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 4, right: 0)
        container.isLayoutMarginsRelativeArrangement = true
        let t = UILabel()
        t.text = title
        t.font = .systemFont(ofSize: 15, weight: .medium)
        let s = UILabel()
        s.text = subtitle
        s.font = .systemFont(ofSize: 12)
        s.textColor = .secondaryLabel
        container.addArrangedSubview(t)
        container.addArrangedSubview(s)
        return container
    }

    private func makeSwitchRow(title: String, subtitle: String?, isOn: Bool, onChange: @escaping (Bool) -> Void) -> UIView {
        let container = UIStackView()
        container.axis = .horizontal
        container.alignment = .center
        container.spacing = 12
        container.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        container.isLayoutMarginsRelativeArrangement = true

        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        textStack.addArrangedSubview(titleLabel)
        if let subtitle = subtitle {
            let sub = UILabel()
            sub.text = subtitle
            sub.font = .systemFont(ofSize: 12)
            sub.textColor = .secondaryLabel
            textStack.addArrangedSubview(sub)
        }
        let sw = UISwitch()
        sw.isOn = isOn
        sw.onTintColor = .systemPurple
        sw.addAction(UIAction { action in
            onChange((action.sender as! UISwitch).isOn)
        }, for: .valueChanged)
        container.addArrangedSubview(textStack)
        container.addArrangedSubview(UIView())
        container.addArrangedSubview(sw)
        return container
    }

    private func makeSliderRow(title: String, subtitle: String, value: Float, displayAsPoints: Float? = nil, onChange: @escaping (Float) -> Void) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 6
        container.layoutMargins = UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
        container.isLayoutMarginsRelativeArrangement = true

        let top = UIStackView()
        top.axis = .horizontal
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 15, weight: .medium)
        let valueLabel = UILabel()
        if let pts = displayAsPoints {
            valueLabel.text = "\(Int(value * pts))pt"
        } else {
            valueLabel.text = "\(Int(value * 100))%"
        }
        valueLabel.font = .systemFont(ofSize: 13, weight: .medium)
        valueLabel.textColor = .secondaryLabel
        top.addArrangedSubview(titleLabel)
        top.addArrangedSubview(UIView())
        top.addArrangedSubview(valueLabel)

        let sub = UILabel()
        sub.text = subtitle
        sub.font = .systemFont(ofSize: 12)
        sub.textColor = .secondaryLabel

        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = value
        slider.tintColor = .systemPurple
        slider.addAction(UIAction { action in
            let v = (action.sender as! UISlider).value
            if let pts = displayAsPoints {
                valueLabel.text = "\(Int(v * pts))pt"
            } else {
                valueLabel.text = "\(Int(v * 100))%"
            }
            onChange(v)
        }, for: .valueChanged)

        container.addArrangedSubview(top)
        container.addArrangedSubview(sub)
        container.addArrangedSubview(slider)
        return container
    }

    @objc private func resetDefaults() {
        prefs.resetToDefaults()
        reloadUI()
    }

    @objc private func openDiscord() {
        if let url = URL(string: "https://discord.gg/Sxtn7SjDvu") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
