import UIKit

/// A small glass settings button that can be placed next to other tweak buttons (e.g. on profile).
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

/// Presents a simple settings panel for GlossyGlass
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

        let panel = GlassSettingsViewController()
        panel.modalPresentationStyle = .pageSheet

        if #available(iOS 15.0, *) {
            if let sheet = panel.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
            }
        }

        top.present(panel, animated: true)
    }
}

// MARK: - Settings View Controller

private class GlassSettingsViewController: UIViewController {

    private let prefs = GlassPreferences.shared
    private var stack: UIStackView!

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "GlossyGlass"

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(close)
        )

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -40),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        buildUI()
    }

    private func buildUI() {
        // Master
        stack.addArrangedSubview(makeSwitch(title: "Enable GlossyGlass", isOn: prefs.isEnabled) { [weak self] on in
            self?.prefs.isEnabled = on
        })

        // Intensity
        stack.addArrangedSubview(makeSlider(title: "Gloss Intensity", value: Float(prefs.glossIntensity)) { [weak self] v in
            self?.prefs.glossIntensity = CGFloat(v)
        })

        // Lightweight
        stack.addArrangedSubview(makeSwitch(title: "Lightweight Mode", isOn: prefs.lightweightMode) { [weak self] on in
            self?.prefs.lightweightMode = on
        })

        // Section: Elements
        let section = UILabel()
        section.text = "Elements"
        section.font = .systemFont(ofSize: 13, weight: .semibold)
        section.textColor = .secondaryLabel
        stack.addArrangedSubview(section)

        stack.addArrangedSubview(makeSwitch(title: "Navigation Bar", isOn: prefs.styleNavigationBar) { [weak self] on in
            self?.prefs.styleNavigationBar = on
        })
        stack.addArrangedSubview(makeSwitch(title: "Tab Bar", isOn: prefs.styleTabBar) { [weak self] on in
            self?.prefs.styleTabBar = on
        })
        stack.addArrangedSubview(makeSwitch(title: "Buttons", isOn: prefs.styleButtons) { [weak self] on in
            self?.prefs.styleButtons = on
        })
        stack.addArrangedSubview(makeSwitch(title: "Cards", isOn: prefs.styleCards) { [weak self] on in
            self?.prefs.styleCards = on
        })

        // Debug
        stack.addArrangedSubview(makeSwitch(title: "Debug Logging", isOn: prefs.debugLogging) { [weak self] on in
            self?.prefs.debugLogging = on
        })

        // Reset
        let reset = UIButton(type: .system)
        reset.setTitle("Reset to Defaults", for: .normal)
        reset.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        reset.addTarget(self, action: #selector(resetDefaults), for: .touchUpInside)
        stack.addArrangedSubview(reset)
    }

    private func makeSwitch(title: String, isOn: Bool, onChange: @escaping (Bool) -> Void) -> UIView {
        let row = UIStackView()
        row.axis = .horizontal
        row.alignment = .center

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)

        let sw = UISwitch()
        sw.isOn = isOn
        sw.addAction(UIAction { action in
            onChange((action.sender as! UISwitch).isOn)
        }, for: .valueChanged)

        row.addArrangedSubview(label)
        row.addArrangedSubview(UIView()) // spacer
        row.addArrangedSubview(sw)
        return row
    }

    private func makeSlider(title: String, value: Float, onChange: @escaping (Float) -> Void) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 6

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16)

        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = value
        slider.addAction(UIAction { action in
            onChange((action.sender as! UISlider).value)
        }, for: .valueChanged)

        container.addArrangedSubview(label)
        container.addArrangedSubview(slider)
        return container
    }

    @objc private func resetDefaults() {
        prefs.resetToDefaults()
        // Rebuild UI
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buildUI()
    }

    @objc private func close() {
        dismiss(animated: true)
    }
}
