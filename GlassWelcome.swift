import UIKit

@objc public class GlassWelcome: NSObject {
    private static let shownKey = "GG_WelcomeShown_v4"
    private static var presenting = false

    @objc public static func presentIfNeeded() {
        let defs = UserDefaults(suiteName: "com.glossyglass.preferences") ?? .standard
        if defs.bool(forKey: shownKey) { return }
        present(force: true)
    }

    @objc public static func present(force: Bool) {
        DispatchQueue.main.async {
            if presenting { return }
            guard let host = GlassAppSupport.topViewController()?.view
                    ?? GlassAppSupport.allWindows().first else { return }
            presenting = true
            let overlay = GlassWelcomeView(frame: host.bounds)
            overlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            overlay.alpha = 0
            host.addSubview(overlay)
            UIView.animate(withDuration: 0.3) { overlay.alpha = 1 }
            overlay.runSequence {
                UIView.animate(withDuration: 0.45, animations: {
                    overlay.alpha = 0
                }, completion: { _ in
                    overlay.removeFromSuperview()
                    presenting = false
                    let defs = UserDefaults(suiteName: "com.glossyglass.preferences") ?? .standard
                    defs.set(true, forKey: shownKey)
                })
            }
        }
    }
}

private final class GlassWelcomeView: UIView {
    private let card = UIView()
    private let title = UILabel()
    private let statusStack = UIStackView()
    private let bar = UIView()
    private let barFill = UIView()
    private var barW: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.black.withAlphaComponent(0.5)

        card.translatesAutoresizingMaskIntoConstraints = false
        card.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.94)
        card.layer.cornerRadius = 28
        card.layer.cornerCurve = .continuous
        card.layer.borderWidth = 0.6
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
        addSubview(card)

        title.text = "GlossyGlass v4"
        title.font = .systemFont(ofSize: 24, weight: .bold)
        title.textAlignment = .center
        title.translatesAutoresizingMaskIntoConstraints = false

        statusStack.axis = .vertical
        statusStack.spacing = 6
        statusStack.alignment = .leading
        statusStack.translatesAutoresizingMaskIntoConstraints = false

        bar.backgroundColor = UIColor.tertiarySystemFill
        bar.layer.cornerRadius = 3
        bar.clipsToBounds = true
        bar.translatesAutoresizingMaskIntoConstraints = false
        barFill.backgroundColor = UIColor.systemGreen
        barFill.translatesAutoresizingMaskIntoConstraints = false
        bar.addSubview(barFill)
        barW = barFill.widthAnchor.constraint(equalToConstant: 4)

        let col = UIStackView(arrangedSubviews: [title, statusStack, bar])
        col.axis = .vertical
        col.spacing = 16
        col.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(col)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: centerXAnchor),
            card.centerYAnchor.constraint(equalTo: centerYAnchor),
            card.widthAnchor.constraint(equalToConstant: 300),
            col.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            col.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 22),
            col.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -22),
            col.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24),
            bar.heightAnchor.constraint(equalToConstant: 6),
            barFill.leadingAnchor.constraint(equalTo: bar.leadingAnchor),
            barFill.topAnchor.constraint(equalTo: bar.topAnchor),
            barFill.bottomAnchor.constraint(equalTo: bar.bottomAnchor),
            barW!
        ])
    }

    required init?(coder: NSCoder) { fatalError() }

    func runSequence(done: @escaping () -> Void) {
        let steps: [(String, () -> Void)] = [
            ("Glass Core", {}),
            ("Preferences", { _ = GlassPreferences.shared.isEnabled }),
            ("Locator", { _ = GlassLocator.shared.findBestButtonHost() }),
            ("Health checks", { _ = GlassHealthChecker.shared.runAll() }),
            ("Glass buttons", { GlassStyleApplicator.applyAll() }),
            ("Injection", { GlassInjector.start() }),
            ("Native glass bridge", { _ = GlassNativeBridge.isNativeGlassAvailable }),
            ("Update check", { GlassUpdateChecker.shared.checkAsync(completion: nil) })
        ]

        var i = 0
        func next() {
            if i >= steps.count {
                let ok = UILabel()
                ok.text = "● Ready — latest engine"
                ok.font = .systemFont(ofSize: 13, weight: .semibold)
                ok.textColor = .systemGreen
                statusStack.addArrangedSubview(ok)
                barW?.constant = 256
                UIView.animate(withDuration: 0.25, animations: { self.layoutIfNeeded() })
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.55, execute: done)
                return
            }
            let (name, work) = steps[i]
            i += 1
            work()
            let line = UILabel()
            line.text = "● \(name)"
            line.font = .monospacedSystemFont(ofSize: 12, weight: .medium)
            line.textColor = .systemGreen
            line.alpha = 0
            statusStack.addArrangedSubview(line)
            UIView.animate(withDuration: 0.2) { line.alpha = 1 }
            let progress = CGFloat(i) / CGFloat(steps.count)
            barW?.constant = 4 + progress * 252
            UIView.animate(withDuration: 0.2) { self.layoutIfNeeded() }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) { next() }
        }
        next()
    }
}
