import UIKit

/// Compact iOS 26–style floating liquid-glass tab capsule.
/// Hides the stock bar’s solid fill and draws a smaller frosted pill above the home indicator.
@objc public final class GlassLiquidTabBar: NSObject {

    @objc public static let shared = GlassLiquidTabBar()

    private weak var hostWindow: UIWindow?
    private weak var stockTabBar: UITabBar?
    private var capsule: LiquidCapsuleView?
    private var observer: NSObjectProtocol?
    private var timer: Timer?
    private var lastApply: TimeInterval = 0

    private override init() {
        super.init()
    }

    @objc public func start() {
        DispatchQueue.main.async {
            if self.observer == nil {
                self.observer = NotificationCenter.default.addObserver(
                    forName: .glassPreferencesDidChange,
                    object: nil,
                    queue: .main
                ) { [weak self] _ in self?.refresh() }
            }
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
                self?.refresh()
            }
            for d in [0.4, 1.0, 2.0, 4.0, 8.0] as [TimeInterval] {
                DispatchQueue.main.asyncAfter(deadline: .now() + d) { self.refresh() }
            }
            self.refresh()
        }
    }

    @objc public func refresh() {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, prefs.styleTabBar, !prefs.safeMode else {
            tearDown()
            return
        }

        let now = CFAbsoluteTimeGetCurrent()
        if now - lastApply < 0.25 { return }
        lastApply = now

        guard let window = GlassAppSupport.keyWindow()
                ?? GlassAppSupport.allWindows().first else { return }
        hostWindow = window

        // Find stock UITabBar if any
        let bar = findTabBar(in: window)
        stockTabBar = bar
        if let bar = bar {
            softenStockBar(bar)
        }

        installCapsule(in: window, above: bar)
        styleBottomChrome(in: window)
    }

    private func tearDown() {
        capsule?.removeFromSuperview()
        capsule = nil
        if let bar = stockTabBar {
            bar.isHidden = false
            bar.alpha = 1
        }
    }


    /// Instagram often uses a custom bottom bar, not UITabBar. Style that container as a liquid capsule.
    private func styleBottomChrome(in window: UIWindow) {
        let prefs = GlassPreferences.shared
        guard prefs.styleTabBar else { return }
        let screenH = window.bounds.height
        let candidates = collectBottomBars(in: window, screenH: screenH, depth: 0)
        guard let target = candidates.sorted(by: { $0.bounds.width > $1.bounds.width }).first else { return }

        let isDark = target.traitCollection.userInterfaceStyle == .dark
        let blurTag = 0x4747_5442 // GGTB
        if target.viewWithTag(blurTag) == nil, prefs.blurEnabled,
           !UIAccessibility.isReduceTransparencyEnabled {
            let style: UIBlurEffect.Style = isDark ? .systemThinMaterialDark : .systemThinMaterialLight
            let blur = UIVisualEffectView(effect: UIBlurEffect(style: style))
            blur.tag = blurTag
            blur.isUserInteractionEnabled = false
            blur.translatesAutoresizingMaskIntoConstraints = false
            target.insertSubview(blur, at: 0)
            NSLayoutConstraint.activate([
                blur.topAnchor.constraint(equalTo: target.topAnchor),
                blur.leadingAnchor.constraint(equalTo: target.leadingAnchor),
                blur.trailingAnchor.constraint(equalTo: target.trailingAnchor),
                blur.bottomAnchor.constraint(equalTo: target.bottomAnchor)
            ])
        }

        // Capsule shape — inset from screen edges (smaller like iOS 26)
        target.backgroundColor = .clear
        let h = target.bounds.height
        if h > 40 && h < 100 {
            target.layer.cornerRadius = min(28, h * 0.42)
            target.layer.cornerCurve = .continuous
            target.layer.maskedCorners = [
                .layerMinXMinYCorner, .layerMaxXMinYCorner,
                .layerMinXMaxYCorner, .layerMaxXMaxYCorner
            ]
            target.clipsToBounds = true
            if prefs.edgeHighlightEnabled {
                target.layer.borderWidth = 0.5
                target.layer.borderColor = UIColor.white
                    .withAlphaComponent(isDark ? 0.18 : 0.32).cgColor
            }
            // Soft horizontal inset feel via transform scale — avoid breaking layout
            // (real inset needs constraint surgery; visual radius is the main cue)
        }
    }

    private func collectBottomBars(in view: UIView, screenH: CGFloat, depth: Int) -> [UIView] {
        var out: [UIView] = []
        guard depth < 14 else { return out }
        let frame = view.convert(view.bounds, to: nil)
        let nearBottom = frame.maxY > screenH - 100 && frame.minY > screenH - 140
        let barLike = frame.height > 40 && frame.height < 96 && frame.width > (view.window?.bounds.width ?? 320) * 0.55
        let name = NSStringFromClass(type(of: view)).lowercased()
        let nameHit = name.contains("tab") || name.contains("tabbar") || name.contains("igtab")
            || name.contains("bottombar") || name.contains("dock")
        if (nearBottom && barLike) || (nameHit && barLike) {
            if !(view is UIButton) && !(view is UILabel) {
                out.append(view)
            }
        }
        for s in view.subviews {
            out.append(contentsOf: collectBottomBars(in: s, screenH: screenH, depth: depth + 1))
        }
        return out
    }

    private func findTabBar(in root: UIView) -> UITabBar? {
        if let t = root as? UITabBar { return t }
        for s in root.subviews {
            if let f = findTabBar(in: s) { return f }
        }
        return nil
    }

    /// Kill solid black fill on system tab bar so content can show through under our capsule.
    private func softenStockBar(_ bar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = nil
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.backgroundColor = .clear
        bar.barTintColor = .clear
        bar.isTranslucent = true
        bar.layer.shadowOpacity = 0
        bar.layer.borderWidth = 0
        // Keep items tappable; visually mute the chrome
        // Keep full alpha so icons stay visible; only chrome is cleared
    }

    private func installCapsule(in window: UIWindow, above bar: UITabBar?) {
        let capsule: LiquidCapsuleView
        if let existing = self.capsule, existing.superview === window {
            capsule = existing
        } else {
            self.capsule?.removeFromSuperview()
            capsule = LiquidCapsuleView()
            capsule.translatesAutoresizingMaskIntoConstraints = false
            window.addSubview(capsule)
            self.capsule = capsule
        }

        // Size: smaller than full width — iOS 26 island proportion
        let widthRatio: CGFloat = 0.72
        let height: CGFloat = 54
        let bottomPad: CGFloat = 10

        capsule.removeConstraints(capsule.constraints.filter { $0.firstItem === capsule })
        // Clear old constraints on capsule from window
        for c in window.constraints where c.firstItem === capsule || c.secondItem === capsule {
            window.removeConstraint(c)
        }

        NSLayoutConstraint.activate([
            capsule.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            capsule.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -bottomPad),
            capsule.widthAnchor.constraint(equalTo: window.widthAnchor, multiplier: widthRatio),
            capsule.heightAnchor.constraint(equalToConstant: height)
        ])

        capsule.applyMaterial()
        window.bringSubviewToFront(capsule)

        // Capsule is visual; keep stock bar interactive underneath (almost invisible)
        capsule.isUserInteractionEnabled = false
    }
}

// MARK: - Capsule view

private final class LiquidCapsuleView: UIView {
    private let blur = UIVisualEffectView(effect: nil)
    private let tintLayer = UIView()
    private let gloss = CAGradientLayer()
    private let rim = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        layer.cornerCurve = .continuous
        clipsToBounds = false

        blur.translatesAutoresizingMaskIntoConstraints = false
        blur.clipsToBounds = true
        blur.layer.cornerCurve = .continuous
        addSubview(blur)

        tintLayer.translatesAutoresizingMaskIntoConstraints = false
        tintLayer.isUserInteractionEnabled = false
        addSubview(tintLayer)

        gloss.name = "gg.liquid.gloss"
        gloss.colors = [
            UIColor.white.withAlphaComponent(0.35).cgColor,
            UIColor.white.withAlphaComponent(0.05).cgColor,
            UIColor.clear.cgColor
        ]
        gloss.locations = [0, 0.35, 1]
        gloss.startPoint = CGPoint(x: 0.5, y: 0)
        gloss.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(gloss)

        rim.name = "gg.liquid.rim"
        rim.colors = [
            UIColor.white.withAlphaComponent(0.45).cgColor,
            UIColor.white.withAlphaComponent(0.08).cgColor,
            UIColor.white.withAlphaComponent(0.25).cgColor
        ]
        rim.startPoint = CGPoint(x: 0, y: 0)
        rim.endPoint = CGPoint(x: 1, y: 1)
        rim.opacity = 0.9
        layer.addSublayer(rim)

        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: topAnchor),
            blur.leadingAnchor.constraint(equalTo: leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: bottomAnchor),
            tintLayer.topAnchor.constraint(equalTo: topAnchor),
            tintLayer.leadingAnchor.constraint(equalTo: leadingAnchor),
            tintLayer.trailingAnchor.constraint(equalTo: trailingAnchor),
            tintLayer.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.22
        layer.shadowRadius = 18
        layer.shadowOffset = CGSize(width: 0, height: 6)
    }

    required init?(coder: NSCoder) { fatalError() }

    func applyMaterial() {
        let prefs = GlassPreferences.shared
        let isDark = traitCollection.userInterfaceStyle == .dark
        let intensity = max(0.2, (isDark ? prefs.darkIntensity : prefs.lightIntensity) * prefs.intensity)

        let style: UIBlurEffect.Style
        if prefs.lightweightMode {
            style = isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
        } else {
            switch prefs.style.lowercased() {
            case "clear":
                style = isDark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight
            case "tinted":
                style = isDark ? .systemMaterialDark : .systemMaterialLight
            default:
                style = isDark ? .systemThinMaterialDark : .systemThinMaterialLight
            }
        }
        blur.effect = UIBlurEffect(style: style)

        let tintAlpha = (isDark ? 0.10 : 0.14) * intensity * prefs.opacity
        tintLayer.backgroundColor = UIColor.white.withAlphaComponent(min(0.28, tintAlpha))

        let r = bounds.height / 2
        layer.cornerRadius = r
        blur.layer.cornerRadius = r
        tintLayer.layer.cornerRadius = r
        blur.clipsToBounds = true
        tintLayer.clipsToBounds = true

        layer.borderWidth = prefs.edgeHighlightEnabled ? 0.6 : 0.35
        layer.borderColor = UIColor.white.withAlphaComponent(isDark ? 0.22 : 0.40).cgColor

        gloss.opacity = prefs.lightBloomEnabled ? Float(0.55 * intensity) : 0.25
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let r = bounds.height / 2
        layer.cornerRadius = r
        blur.layer.cornerRadius = r
        tintLayer.layer.cornerRadius = r
        gloss.frame = bounds.insetBy(dx: 1, dy: 1)
        gloss.cornerRadius = r
        // Rim as border approximation via thin gradient stroke path
        rim.frame = bounds
        rim.cornerRadius = r
        rim.borderWidth = 0
        // Use mask for rim ring
        let outer = UIBezierPath(roundedRect: bounds, cornerRadius: r)
        let inset = bounds.insetBy(dx: 1.2, dy: 1.2)
        let inner = UIBezierPath(roundedRect: inset, cornerRadius: max(0, r - 1.2))
        outer.append(inner.reversing())
        let mask = CAShapeLayer()
        mask.path = outer.cgPath
        mask.fillRule = .evenOdd
        rim.mask = mask
        applyMaterial()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        applyMaterial()
    }
}
