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
        while let presented = top.presentedViewController { top = presented }

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

private class GlassSettingsViewController: UIViewController {

    private let prefs = GlassPreferences.shared
    private var stack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "GlossyGlass"

        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(close))

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
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -40),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        buildUI()
    }

    private func buildUI() {
        // Master
        stack.addArrangedSubview(makeSwitch("Enable GlossyGlass", isOn: prefs.isEnabled) { [weak self] v in self?.prefs.isEnabled = v })

        // Presets
        stack.addArrangedSubview(sectionLabel("Presets"))
        let presetRow = UIStackView()
        presetRow.axis = .horizontal
        presetRow.spacing = 8
        presetRow.distribution = .fillEqually
        for name in ["Clean", "Default", "Heavy", "Performance"] {
            let b = UIButton(type: .system)
            b.setTitle(name, for: .normal)
            b.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
            b.backgroundColor = .secondarySystemBackground
            b.layer.cornerRadius = 8
            b.addAction(UIAction { [weak self] _ in
                self?.prefs.applyPreset(name)
                self?.reload()
            }, for: .touchUpInside)
            presetRow.addArrangedSubview(b)
        }
        stack.addArrangedSubview(presetRow)

        // Intensity
        stack.addArrangedSubview(makeSlider("Light Mode Intensity", value: Float(prefs.lightIntensity)) { [weak self] v in self?.prefs.lightIntensity = CGFloat(v) })
        stack.addArrangedSubview(makeSlider("Dark Mode Intensity", value: Float(prefs.darkIntensity)) { [weak self] v in self?.prefs.darkIntensity = CGFloat(v) })

        // Mode
        stack.addArrangedSubview(sectionLabel("Glass Mode"))
        let mode = UISegmentedControl(items: ["Frosted", "Clear", "Tinted"])
        mode.selectedSegmentIndex = prefs.glassMode
        mode.addAction(UIAction { [weak self] action in
            self?.prefs.glassMode = (action.sender as! UISegmentedControl).selectedSegmentIndex
        }, for: .valueChanged)
        stack.addArrangedSubview(mode)

        stack.addArrangedSubview(makeSwitch("Lightweight Mode", isOn: prefs.lightweightMode) { [weak self] v in self?.prefs.lightweightMode = v })
        stack.addArrangedSubview(makeSwitch("Chromatic Aberration", isOn: prefs.chromaticAberration) { [weak self] v in self?.prefs.chromaticAberration = v })

        // Elements
        stack.addArrangedSubview(sectionLabel("Elements"))
        stack.addArrangedSubview(makeSwitch("Navigation Bar", isOn: prefs.styleNavigationBar) { [weak self] v in self?.prefs.styleNavigationBar = v })
        stack.addArrangedSubview(makeSwitch("Tab Bar", isOn: prefs.styleTabBar) { [weak self] v in self?.prefs.styleTabBar = v })
        stack.addArrangedSubview(makeSwitch("Buttons", isOn: prefs.styleButtons) { [weak self] v in self?.prefs.styleButtons = v })
        stack.addArrangedSubview(makeSwitch("Cards", isOn: prefs.styleCards) { [weak self] v in self?.prefs.styleCards = v })
        stack.addArrangedSubview(makeSwitch("Show Glass Button", isOn: prefs.showGlassButton) { [weak self] v in self?.prefs.showGlassButton = v })

        // Debug
        stack.addArrangedSubview(sectionLabel("Debug"))
        stack.addArrangedSubview(makeSwitch("Debug Logging", isOn: prefs.debugLogging) { [weak self] v in self?.prefs.debugLogging = v })
        stack.addArrangedSubview(makeSwitch("Debug Overlay", isOn: prefs.debugOverlay) { [weak self] v in self?.prefs.debugOverlay = v })

        // Actions
        let resetStyles = UIButton(type: .system)
        resetStyles.setTitle("Reset Styles Only", for: .normal)
        resetStyles.addTarget(self, action: #selector(resetStylesOnly), for: .touchUpInside)
        stack.addArrangedSubview(resetStyles)

        let resetAll = UIButton(type: .system)
        resetAll.setTitle("Reset to Defaults", for: .normal)
        resetAll.addTarget(self, action: #selector(resetAll), for: .touchUpInside)
        stack.addArrangedSubview(resetAll)

        // Branding
        let spacer = UIView()
        spacer.heightAnchor.constraint(equalToConstant: 16).isActive = true
        stack.addArrangedSubview(spacer)

        let madeBy = UILabel()
        madeBy.text = "Made by Killswitch"
        madeBy.font = .systemFont(ofSize: 14, weight: .semibold)
        madeBy.textAlignment = .center
        stack.addArrangedSubview(madeBy)

        let discord = UIButton(type: .system)
        discord.setTitle("discord.gg/SxtnSjDvu", for: .normal)
        discord.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
        discord.addTarget(self, action: #selector(openDiscord), for: .touchUpInside)
        stack.addArrangedSubview(discord)

        let ver = UILabel()
        ver.text = "GlossyGlass v2.0"
        ver.font = .systemFont(ofSize: 12)
        ver.textColor = .tertiaryLabel
        ver.textAlignment = .center
        stack.addArrangedSubview(ver)
    }

    private func sectionLabel(_ text: String) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 13, weight: .semibold)
        l.textColor = .secondaryLabel
        return l
    }

    private func makeSwitch(_ title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)
        let sw = UISwitch()
        sw.isOn = isOn
        sw.addAction(UIAction { a in onChange((a.sender as! UISwitch).isOn) }, for: .valueChanged)
        row.addArrangedSubview(label)
        row.addArrangedSubview(UIView())
        row.addArrangedSubview(sw)
        return row
    }

    private func makeSlider(_ title: String, value: Float, onChange: @escaping (Float) -> Void) -> UIView {
        let c = UIStackView()
        c.axis = .vertical
        c.spacing = 4
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 15)
        let s = UISlider()
        s.minimumValue = 0
        s.maximumValue = 1
        s.value = value
        s.addAction(UIAction { a in onChange((a.sender as! UISlider).value) }, for: .valueChanged)
        c.addArrangedSubview(l)
        c.addArrangedSubview(s)
        return c
    }

    private func reload() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buildUI()
    }

    @objc private func resetStylesOnly() {
        prefs.resetStylesOnly()
        reload()
    }

    @objc private func resetAll() {
        prefs.resetToDefaults()
        reload()
    }

    @objc private func openDiscord() {
        if let url = URL(string: "https://discord.gg/SxtnSjDvu") {
            UIApplication.shared.open(url)
        }
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
