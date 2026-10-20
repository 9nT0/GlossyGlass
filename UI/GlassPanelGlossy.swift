//
//  GlassPanelGlossy.swift
//  GlossyGlass v5
//
//  The new settings surface that appears when Glossy Mode is enabled.
//  Replaces the normal panel completely.
//

import UIKit

@objc public final class GlassPanelGlossy: NSObject {

    @objc public static let shared = GlassPanelGlossy()

    private weak var currentVC: UIViewController?

    @objc public func present() {
        guard let presenter = topViewController() else { return }

        // Remove the normal panel first
        GlassPanel.shared.dismiss()

        let vc = GlossyPanelViewController()
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

// MARK: - Glossy Panel UI (cleaner, more iOS-26 style)

private final class GlossyPanelViewController: UIViewController {

    private let prefs = GlassPreferences.shared

    override func viewDidLoad() {
        super.viewDidLoad()

        // Soft glass background feel
        view.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.92)

        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blur, at: 0)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24)
        ])

        let title = UILabel()
        title.text = "Glossy Mode"
        title.font = .systemFont(ofSize: 28, weight: .bold)
        stack.addArrangedSubview(title)

        let subtitle = UILabel()
        subtitle.text = "iOS 26 liquid glass · remade icons · full chrome"
        subtitle.font = .systemFont(ofSize: 14)
        subtitle.textColor = .secondaryLabel
        subtitle.numberOfLines = 0
        stack.addArrangedSubview(subtitle)

        // Big toggle to turn Glossy Mode off
        let row = UIView()
        let label = UILabel()
        label.text = "Enable Glossy"
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false

        let sw = UISwitch()
        sw.isOn = true
        sw.onTintColor = .systemBlue
        sw.translatesAutoresizingMaskIntoConstraints = false
        sw.addAction(UIAction { [weak self] _ in
            self?.prefs.glossyMode = sw.isOn
            if !sw.isOn {
                self?.dismiss(animated: true)
            }
        }, for: .valueChanged)

        row.addSubview(label)
        row.addSubview(sw)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            sw.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            sw.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: 44)
        ])
        stack.addArrangedSubview(row)

        // Quick intensity
        let intensityLabel = UILabel()
        intensityLabel.text = "Liquid Strength"
        intensityLabel.font = .systemFont(ofSize: 15, weight: .medium)

        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 1.0
        slider.value = Float(prefs.intensity)
        slider.addAction(UIAction { [weak self] _ in
            self?.prefs.intensity = CGFloat(slider.value)
        }, for: .valueChanged)

        stack.addArrangedSubview(intensityLabel)
        stack.addArrangedSubview(slider)

        let note = UILabel()
        note.text = "Icons and chrome are now using the remade glossy set.\nTurn off to return to the clean base look."
        note.font = .systemFont(ofSize: 13)
        note.textColor = .secondaryLabel
        note.numberOfLines = 0
        stack.addArrangedSubview(note)
    }
}
