import UIKit

@objc public final class GlassPanelGlossy: NSObject {
    @objc public static let shared = GlassPanelGlossy()
    private weak var current: UIViewController?

    @objc public func present() {
        guard let p = top() else { return }
        GlassPanel.shared.dismiss()
        let vc = GlossyPanel()
        vc.modalPresentationStyle = .pageSheet
        if let s = vc.sheetPresentationController {
            s.detents = [.medium(), .large()]
            s.prefersGrabberVisible = true
            s.preferredCornerRadius = 28
        }
        current = vc
        p.present(vc, animated: true)
    }

    @objc public func dismiss() { current?.dismiss(animated: true); current = nil }

    private func top() -> UIViewController? {
        guard let w = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow }) else { return nil }
        var t = w.rootViewController
        while let p = t?.presentedViewController { t = p }
        return t
    }
}

private final class GlossyPanel: UIViewController {
    private let prefs = GlassPreferences.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 22),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
        let title = UILabel()
        title.text = "Glossy Mode"
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.textColor = .white
        stack.addArrangedSubview(title)
        let sub = UILabel()
        sub.text = "v5.3 · Heavy liquid · pill tab · feed · DMs · reels · search · menus"
        sub.font = .systemFont(ofSize: 12)
        sub.textColor = UIColor.white.withAlphaComponent(0.6)
        sub.numberOfLines = 0
        stack.addArrangedSubview(sub)

        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        card.layer.cornerCurve = .continuous
        card.layer.cornerRadius = 16
        let cs = UIStackView()
        cs.axis = .vertical
        cs.spacing = 12
        cs.layoutMargins = UIEdgeInsets(top: 14, left: 12, bottom: 14, right: 12)
        cs.isLayoutMarginsRelativeArrangement = true
        cs.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(cs)
        NSLayoutConstraint.activate([
            cs.topAnchor.constraint(equalTo: card.topAnchor),
            cs.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            cs.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            cs.trailingAnchor.constraint(equalTo: card.trailingAnchor)
        ])
        let row = UIView()
        let lab = UILabel()
        lab.text = "Enable Glossy"
        lab.font = .systemFont(ofSize: 16, weight: .semibold)
        lab.textColor = .white
        lab.translatesAutoresizingMaskIntoConstraints = false
        let sw = UISwitch()
        sw.isOn = true
        sw.onTintColor = .systemBlue
        sw.translatesAutoresizingMaskIntoConstraints = false
        sw.addAction(UIAction { [weak self] _ in
            self?.prefs.glossyMode = sw.isOn
            if !sw.isOn { self?.dismiss(animated: true) }
        }, for: .valueChanged)
        row.addSubview(lab)
        row.addSubview(sw)
        NSLayoutConstraint.activate([
            lab.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            lab.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            sw.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            sw.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: 32)
        ])
        cs.addArrangedSubview(row)
        let strength = UILabel()
        strength.text = "Liquid Strength"
        strength.font = .systemFont(ofSize: 13, weight: .medium)
        strength.textColor = UIColor.white.withAlphaComponent(0.75)
        let slider = UISlider()
        slider.minimumValue = 0.5
        slider.maximumValue = 1.0
        slider.value = Float(prefs.intensity)
        slider.tintColor = .systemBlue
        slider.addAction(UIAction { [weak self] _ in
            self?.prefs.intensity = CGFloat(slider.value)
        }, for: .valueChanged)
        cs.addArrangedSubview(strength)
        cs.addArrangedSubview(slider)
        stack.addArrangedSubview(card)
        let note = UILabel()
        note.text = "Turn off for clean base iOS 26 liquid look."
        note.font = .systemFont(ofSize: 12)
        note.textColor = UIColor.white.withAlphaComponent(0.5)
        note.numberOfLines = 0
        stack.addArrangedSubview(note)
    }
}
