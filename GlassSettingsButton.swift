import UIKit

/// Glass settings button that opens the polished settings panel
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
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        glossIntensity = 0.55
        addTarget(self, action: #selector(openSettings), for: .touchUpInside)
    }

    @objc private func openSettings() {
        GlassSettingsPresenter.present(from: self)
    }
}

@objc public class GlassSettingsPresenter: NSObject {

    @objc public static func present(from sourceView: UIView? = nil) {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else { return }

        var top = root
        while let presented = top.presentedViewController {
            top = presented
        }

        let nav = UINavigationController(rootViewController: GlassSettingsViewController())
        nav.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = nav.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }
        top.present(nav, animated: true)
    }
}

// MARK: - Settings View Controller (matches the clean design)

private class GlassSettingsViewController: UIViewController {

    private let prefs = GlassPreferences.shared
    private var stack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        title = ""

        // Custom title
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
            style: .plain,
            target: self,
            action: #selector(close)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Reset",
            style: .plain,
            target: self,
            action: #selector(resetDefaults)
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
        // MARK: Appearance Section
        stack.addArrangedSubview(makeSectionHeader(title: "Appearance", icon: "sparkles"))

        let appearanceCard = makeCard()
        appearanceCard.addArrangedSubview(makeDropdownRow(title: "Style", subtitle: "Choose the glass effect style", value: "Frosted"))
        appearanceCard.addArrangedSubview(makeDivider())
        appearanceCard.addArrangedSubview(makeSliderRow(title: "Intensity", subtitle: "Overall glass blur strength", value: Float(prefs.glossIntensity)) { [weak self] v in
            self?.prefs.glossIntensity = CGFloat(v)
        })
        appearanceCard.addArrangedSubview(makeDivider())
        appearanceCard.addArrangedSubview(makeSliderRow(title: "Opacity", subtitle: "Glass layer opacity", value: Float(prefs.opacity)) { [weak self] v in
            self?.prefs.opacity = CGFloat(v)
        })
        stack.addArrangedSubview(appearanceCard)

        // MARK: Effects Section
        stack.addArrangedSubview(makeSectionHeader(title: "Effects", icon: "water.waves"))

        let effectsCard = makeCard()
        effectsCard.addArrangedSubview(makeSwitchRow(title: "Blur", subtitle: "Enable background blur", isOn: prefs.blurEnabled) { [weak self] on in
            self?.prefs.blurEnabled = on
        })
        effectsCard.addArrangedSubview(makeDivider())
        effectsCard.addArrangedSubview(makeSwitchRow(title: "Vibrancy", subtitle: "Boost colors underneath glass", isOn: prefs.vibrancyEnabled) { [weak self] on in
            self?.prefs.vibrancyEnabled = on
        })
        effectsCard.addArrangedSubview(makeDivider())
        effectsCard.addArrangedSubview(makeSwitchRow(title: "Noise", subtitle: "Add subtle texture to glass", isOn: prefs.noiseEnabled) { [weak self] on in
            self?.prefs.noiseEnabled = on
        })
        effectsCard.addArrangedSubview(makeDivider())
        effectsCard.addArrangedSubview(makeSwitchRow(title: "Light Bloom", subtitle: "Soft glow around bright areas", isOn: prefs.lightBloomEnabled) { [weak self] on in
            self?.prefs.lightBloomEnabled = on
        })
        stack.addArrangedSubview(effectsCard)

        // MARK: Advanced Section
        stack.addArrangedSubview(makeSectionHeader(title: "Advanced", icon: "gearshape"))

        let advancedCard = makeCard()
        advancedCard.addArrangedSubview(makeDropdownRow(title: "Corner Radius", subtitle: "Roundness of glass corners", value: "Large"))
        advancedCard.addArrangedSubview(makeDivider())
        advancedCard.addArrangedSubview(makeSliderRow(title: "Saturation", subtitle: "Color saturation of glass", value: Float(prefs.saturation)) { [weak self] v in
            self?.prefs.saturation = CGFloat(v)
        })
        advancedCard.addArrangedSubview(makeDivider())
        advancedCard.addArrangedSubview(makeSliderRow(title: "Dimming", subtitle: "Darken content behind glass", value: Float(prefs.dimming)) { [weak self] v in
            self?.prefs.dimming = CGFloat(v)
        })
        stack.addArrangedSubview(advancedCard)


        // Extra v3 controls
        let extraCard = makeCard()
        extraCard.addArrangedSubview(makeSwitchRow(title: "Edge Highlight", subtitle: "Refraction-style rim", isOn: prefs.edgeHighlightEnabled) { [weak self] on in
            self?.prefs.edgeHighlightEnabled = on
        })
        extraCard.addArrangedSubview(makeDivider())
        extraCard.addArrangedSubview(makeSwitchRow(title: "Haptics", subtitle: "Touch feedback", isOn: prefs.hapticsEnabled) { [weak self] on in
            self?.prefs.hapticsEnabled = on
        })
        extraCard.addArrangedSubview(makeDivider())
        extraCard.addArrangedSubview(makeSwitchRow(title: "Safe Mode", subtitle: "Disable injection if unstable", isOn: prefs.safeMode) { [weak self] on in
            self?.prefs.safeMode = on
            if on { GlossyGlassAPI.shared.enterSafeMode() } else { GlossyGlassAPI.shared.exitSafeMode() }
        })
        stack.addArrangedSubview(extraCard)

        // MARK: Master + Elements
        let masterCard = makeCard()
        masterCard.addArrangedSubview(makeSwitchRow(title: "Enable GlossyGlass", subtitle: "Master switch", isOn: prefs.isEnabled) { [weak self] on in
            self?.prefs.isEnabled = on
        })
        masterCard.addArrangedSubview(makeDivider())
        masterCard.addArrangedSubview(makeSwitchRow(title: "Lightweight Mode", subtitle: "Better performance", isOn: prefs.lightweightMode) { [weak self] on in
            self?.prefs.lightweightMode = on
        })
        masterCard.addArrangedSubview(makeDivider())
        masterCard.addArrangedSubview(makeSwitchRow(title: "Hide Glass Button", subtitle: "Remove the profile Glass button", isOn: prefs.hideGlassButton) { [weak self] on in
            self?.prefs.hideGlassButton = on
            GlassInjector.attemptInjection()
        })
        masterCard.addArrangedSubview(makeDivider())
        masterCard.addArrangedSubview(makeSwitchRow(title: "Navigation Bar", subtitle: nil, isOn: prefs.styleNavigationBar) { [weak self] on in
            self?.prefs.styleNavigationBar = on
        })
        masterCard.addArrangedSubview(makeDivider())
        masterCard.addArrangedSubview(makeSwitchRow(title: "Tab Bar", subtitle: nil, isOn: prefs.styleTabBar) { [weak self] on in
            self?.prefs.styleTabBar = on
        })
        masterCard.addArrangedSubview(makeDivider())
        masterCard.addArrangedSubview(makeSwitchRow(title: "Buttons", subtitle: nil, isOn: prefs.styleButtons) { [weak self] on in
            self?.prefs.styleButtons = on
        })
        masterCard.addArrangedSubview(makeDivider())
        masterCard.addArrangedSubview(makeSwitchRow(title: "Cards", subtitle: nil, isOn: prefs.styleCards) { [weak self] on in
            self?.prefs.styleCards = on
        })
        stack.addArrangedSubview(masterCard)

        let diagBtn = UIButton(type: .system)
        diagBtn.setTitle("Open Diagnostics", for: .normal)
        diagBtn.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        diagBtn.addAction(UIAction { _ in GlassDiagnostics.shared.present(from: self) }, for: .touchUpInside)
        stack.addArrangedSubview(diagBtn)

        // Footer / Branding
        let footer = UILabel()
        footer.text = "GlossyGlass  ·  Made by Killswitch  ·  v3"
        footer.font = .systemFont(ofSize: 12, weight: .medium)
        footer.textColor = .tertiaryLabel
        footer.textAlignment = .center
        stack.addArrangedSubview(footer)

        let discord = UIButton(type: .system)
        discord.setTitle("discord.gg/Sxtn7SjDvu", for: .normal)
        discord.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        discord.addTarget(self, action: #selector(openDiscord), for: .touchUpInside)
        stack.addArrangedSubview(discord)
    }

    // MARK: - UI Helpers

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

    private func makeSliderRow(title: String, subtitle: String, value: Float, onChange: @escaping (Float) -> Void) -> UIView {
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
        valueLabel.text = "\(Int(value * 100))%"
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
            valueLabel.text = "\(Int(v * 100))%"
            onChange(v)
        }, for: .valueChanged)

        container.addArrangedSubview(top)
        container.addArrangedSubview(sub)
        container.addArrangedSubview(slider)
        return container
    }

    private func makeDropdownRow(title: String, subtitle: String, value: String) -> UIView {
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

        let sub = UILabel()
        sub.text = subtitle
        sub.font = .systemFont(ofSize: 12)
        sub.textColor = .secondaryLabel

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(sub)

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .systemFont(ofSize: 14, weight: .medium)
        valueLabel.textColor = .secondaryLabel

        let chevron = UIImageView(image: UIImage(systemName: "chevron.up.chevron.down"))
        chevron.tintColor = .tertiaryLabel
        chevron.contentMode = .scaleAspectFit
        chevron.widthAnchor.constraint(equalToConstant: 12).isActive = true

        container.addArrangedSubview(textStack)
        container.addArrangedSubview(UIView())
        container.addArrangedSubview(valueLabel)
        container.addArrangedSubview(chevron)
        return container
    }

    @objc private func resetDefaults() {
        prefs.resetToDefaults()
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buildUI()
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
