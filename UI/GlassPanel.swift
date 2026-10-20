//
//  GlassPanel.swift
//  GlossyGlass v5
//
//  Base settings panel. Stable. Used when Glossy Mode is OFF.
//

import UIKit

@objc public final class GlassPanel: NSObject {

    @objc public static let shared = GlassPanel()

    private weak var currentVC: UIViewController?

    @objc public func prepare() {
        // Nothing heavy — just ensure we can present later
    }

    @objc public func present() {
        guard let presenter = topViewController() else { return }

        // If Glossy panel is showing, dismiss it first
        GlassPanelGlossy.shared.dismiss()

        let vc = PanelViewController()
        vc.modalPresentationStyle = .pageSheet
        if let sheet = vc.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        currentVC = vc
        presenter.present(vc, animated: true)
    }

    @objc public func dismiss() {
        currentVC?.dismiss(animated: true)
        currentVC = nil
    }

    // MARK: - Helpers

    private func topViewController() -> UIViewController? {
        guard let window = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return nil }

        var top = window.rootViewController
        while let presented = top?.presentedViewController {
            top = presented
        }
        return top
    }
}

// MARK: - Panel UI

private final class PanelViewController: UIViewController {

    private let prefs = GlassPreferences.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "GlossyGlass"

        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)

        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -20),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -40)
        ])

        // Title
        let titleLabel = UILabel()
        titleLabel.text = "GlossyGlass v5"
        titleLabel.font = .systemFont(ofSize: 22, weight: .bold)
        stack.addArrangedSubview(titleLabel)

        // Glossy Mode — the main toggle the user asked for
        stack.addArrangedSubview(makeSwitchRow(
            title: "Enable Glossy",
            subtitle: "Full iOS 26 look + remade icons + new panel",
            isOn: prefs.glossyMode
        ) { [weak self] on in
            self?.prefs.glossyMode = on
            if on {
                // Panel will be replaced by Glossy panel
                self?.dismiss(animated: true)
            }
        })

        // Intensity
        stack.addArrangedSubview(makeSliderRow(
            title: "Intensity",
            value: Float(prefs.intensity)
        ) { [weak self] value in
            self?.prefs.intensity = CGFloat(value)
        })

        // Opacity
        stack.addArrangedSubview(makeSliderRow(
            title: "Opacity",
            value: Float(prefs.opacity)
        ) { [weak self] value in
            self?.prefs.opacity = CGFloat(value)
        })

        // Chrome toggles
        stack.addArrangedSubview(makeSwitchRow(title: "Style Tab Bar", subtitle: nil, isOn: prefs.styleTabBar) { [weak self] on in
            self?.prefs.styleTabBar = on
        })
        stack.addArrangedSubview(makeSwitchRow(title: "Style Navigation Bar", subtitle: nil, isOn: prefs.styleNavBar) { [weak self] on in
            self?.prefs.styleNavBar = on
        })
        stack.addArrangedSubview(makeSwitchRow(title: "Style Buttons", subtitle: nil, isOn: prefs.styleButtons) { [weak self] on in
            self?.prefs.styleButtons = on
        })

        // System
        stack.addArrangedSubview(makeSwitchRow(title: "Haptics", subtitle: nil, isOn: prefs.haptics) { [weak self] on in
            self?.prefs.haptics = on
        })
        stack.addArrangedSubview(makeSwitchRow(title: "Safe Mode", subtitle: "Disable all glass", isOn: prefs.safeMode) { [weak self] on in
            self?.prefs.safeMode = on
        })

        // Reset
        let reset = UIButton(type: .system)
        reset.setTitle("Reset to Defaults", for: .normal)
        reset.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
        stack.addArrangedSubview(reset)
    }

    @objc private func resetTapped() {
        prefs.resetToDefaults()
        dismiss(animated: true)
    }

    // MARK: - UI helpers

    private func makeSwitchRow(title: String, subtitle: String?, isOn: Bool, action: @escaping (Bool) -> Void) -> UIView {
        let container = UIView()
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false

        let sw = UISwitch()
        sw.isOn = isOn
        sw.translatesAutoresizingMaskIntoConstraints = false
        sw.addAction(UIAction { _ in action(sw.isOn) }, for: .valueChanged)

        container.addSubview(label)
        container.addSubview(sw)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            sw.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            sw.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 44)
        ])

        if let subtitle = subtitle {
            let sub = UILabel()
            sub.text = subtitle
            sub.font = .systemFont(ofSize: 12)
            sub.textColor = .secondaryLabel
            sub.numberOfLines = 0
            sub.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(sub)
            NSLayoutConstraint.activate([
                sub.leadingAnchor.constraint(equalTo: label.leadingAnchor),
                sub.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 2),
                sub.trailingAnchor.constraint(equalTo: sw.leadingAnchor, constant: -8),
                container.heightAnchor.constraint(equalToConstant: 60)
            ])
        }

        return container
    }

    private func makeSliderRow(title: String, value: Float, action: @escaping (Float) -> Void) -> UIView {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 4

        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 16, weight: .medium)

        let slider = UISlider()
        slider.minimumValue = 0.3
        slider.maximumValue = 1.0
        slider.value = value
        slider.addAction(UIAction { _ in action(slider.value) }, for: .valueChanged)

        container.addArrangedSubview(label)
        container.addArrangedSubview(slider)
        return container
    }
}
