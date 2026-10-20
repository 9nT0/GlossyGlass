import UIKit

@objc public final class GlassPanel: NSObject {
    @objc public static let shared = GlassPanel()
    private weak var current: UIViewController?

    @objc public func present() {
        guard let p = top() else { return }
        GlassPanelGlossy.shared.dismiss()
        let vc = BasePanel()
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
        if let t = GlassAppSupport.topViewController() { return t }
        // Retry next runloop once
        return nil
    }

    @objc public func presentWithRetry() {
        if GlassAppSupport.topViewController() != nil {
            present()
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.present()
        }
    }
}

private final class BasePanel: UIViewController {
    private let prefs = GlassPreferences.shared
    private let stack = UIStackView()
    private var cardStack: UIStackView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(blur, at: 0)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.topAnchor.constraint(equalTo: scroll.topAnchor, constant: 18),
            stack.bottomAnchor.constraint(equalTo: scroll.bottomAnchor, constant: -28),
            stack.leadingAnchor.constraint(equalTo: scroll.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: scroll.trailingAnchor, constant: -16),
            stack.widthAnchor.constraint(equalTo: scroll.widthAnchor, constant: -32)
        ])
        build()
    }

    private func build() {
        let title = UILabel()
        title.text = "GlossyGlass"
        title.font = .systemFont(ofSize: 24, weight: .bold)
        stack.addArrangedSubview(title)
        let ver = UILabel()
        ver.text = "v5.3.0 · Full coverage · Pill · Feed · DMs · Reels · Search"
        ver.font = .systemFont(ofSize: 11, weight: .medium)
        ver.textColor = .secondaryLabel
        stack.addArrangedSubview(ver)

        section("Appearance")
        card {
            sw("Enable Glossy", "Heavy liquid · rim · gloss · bloom", prefs.glossyMode) { [weak self] on in
                self?.prefs.glossyMode = on
                if on { self?.dismiss(animated: true) }
            }
        }
        section("Material")
        card {
            slider("Intensity", Float(prefs.intensity)) { [weak self] v in self?.prefs.intensity = CGFloat(v) }
            slider("Opacity", Float(prefs.opacity)) { [weak self] v in self?.prefs.opacity = CGFloat(v) }
        }
        section("Chrome")
        card {
            sw("Tab Bar (pill)", nil, prefs.styleTabBar) { [weak self] on in self?.prefs.styleTabBar = on }
            sw("Navigation Bar", nil, prefs.styleNavBar) { [weak self] on in self?.prefs.styleNavBar = on }
            sw("Buttons & Icons", nil, prefs.styleButtons) { [weak self] on in self?.prefs.styleButtons = on }
            sw("Feed", nil, prefs.styleFeed) { [weak self] on in self?.prefs.styleFeed = on }
            sw("Direct Messages", nil, prefs.styleDMs) { [weak self] on in self?.prefs.styleDMs = on }
            sw("Reels & Stories", nil, prefs.styleReels) { [weak self] on in self?.prefs.styleReels = on }
            sw("Profiles", nil, prefs.styleProfiles) { [weak self] on in self?.prefs.styleProfiles = on }
            sw("Search & Notifications", nil, prefs.styleSearch) { [weak self] on in self?.prefs.styleSearch = on }
            sw("Context Menus", nil, prefs.styleContext) { [weak self] on in self?.prefs.styleContext = on }
        }
        section("Motion")
        card {
            sw("Press Animations", nil, prefs.animations) { [weak self] on in self?.prefs.animations = on }
            sw("Haptics", nil, prefs.haptics) { [weak self] on in self?.prefs.haptics = on }
            sw("Safe Mode", "Disable all glass", prefs.safeMode) { [weak self] on in self?.prefs.safeMode = on }
        }
        let reset = UIButton(type: .system)
        reset.setTitle("Reset to Defaults", for: .normal)
        reset.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)
        reset.addAction(UIAction { [weak self] _ in
            self?.prefs.resetToDefaults()
            self?.dismiss(animated: true)
        }, for: .touchUpInside)
        stack.addArrangedSubview(reset)
    }

    private func section(_ t: String) {
        let l = UILabel()
        l.text = t.uppercased()
        l.font = .systemFont(ofSize: 11, weight: .semibold)
        l.textColor = .secondaryLabel
        stack.addArrangedSubview(l)
    }
    private func card(_ build: () -> Void) {
        let box = UIView()
        box.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        box.layer.cornerCurve = .continuous
        box.layer.cornerRadius = 14
        let inner = UIStackView()
        inner.axis = .vertical
        inner.spacing = 11
        inner.translatesAutoresizingMaskIntoConstraints = false
        box.addSubview(inner)
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: box.topAnchor, constant: 12),
            inner.bottomAnchor.constraint(equalTo: box.bottomAnchor, constant: -12),
            inner.leadingAnchor.constraint(equalTo: box.leadingAnchor, constant: 12),
            inner.trailingAnchor.constraint(equalTo: box.trailingAnchor, constant: -12)
        ])
        cardStack = inner
        build()
        cardStack = nil
        stack.addArrangedSubview(box)
    }
    private func sw(_ title: String, _ sub: String?, _ on: Bool, _ action: @escaping (Bool) -> Void) {
        let row = UIView()
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 15, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        let s = UISwitch()
        s.isOn = on
        s.onTintColor = .systemBlue
        s.translatesAutoresizingMaskIntoConstraints = false
        s.addAction(UIAction { _ in action(s.isOn) }, for: .valueChanged)
        row.addSubview(label)
        row.addSubview(s)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: row.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            s.trailingAnchor.constraint(equalTo: row.trailingAnchor),
            s.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            row.heightAnchor.constraint(equalToConstant: sub == nil ? 32 : 46)
        ])
        if let sub {
            let l = UILabel()
            l.text = sub
            l.font = .systemFont(ofSize: 11)
            l.textColor = .secondaryLabel
            l.numberOfLines = 0
            l.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(l)
            NSLayoutConstraint.activate([
                l.leadingAnchor.constraint(equalTo: label.leadingAnchor),
                l.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 1),
                l.trailingAnchor.constraint(equalTo: s.leadingAnchor, constant: -6)
            ])
        }
        (cardStack ?? stack).addArrangedSubview(row)
    }
    private func slider(_ title: String, _ value: Float, _ action: @escaping (Float) -> Void) {
        let box = UIStackView()
        box.axis = .vertical
        box.spacing = 4
        let l = UILabel()
        l.text = title
        l.font = .systemFont(ofSize: 14, weight: .medium)
        let s = UISlider()
        s.minimumValue = 0.35
        s.maximumValue = 1.0
        s.value = value
        s.addAction(UIAction { _ in action(s.value) }, for: .valueChanged)
        box.addArrangedSubview(l)
        box.addArrangedSubview(s)
        (cardStack ?? stack).addArrangedSubview(box)
    }
}
