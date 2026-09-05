import UIKit

/// High-quality glass view with improved materials, refraction-like edges, and adaptive intensity
@objc open class GlassView: UIView {

    @objc public var glossIntensity: CGFloat = 0.55 {
        didSet { updateAppearance() }
    }

    @objc public var cornerRadius: CGFloat = 22 {
        didSet { applyCorners() }
    }

    @objc public var isInteractive: Bool = true

    @objc public var customTint: UIColor? = nil {
        didSet { updateAppearance() }
    }

    // Layers
    private let blurView = UIVisualEffectView(effect: nil)
    private let tintLayer = CALayer()
    private let glossLayer = CAGradientLayer()
    private let edgeHighlight = CAGradientLayer()
    private let borderLayer = CALayer()
    private var preferencesObserver: NSObjectProtocol?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        if let obs = preferencesObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private func commonInit() {
        backgroundColor = .clear
        clipsToBounds = true
        isUserInteractionEnabled = true

        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.clipsToBounds = true
        addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        layer.addSublayer(tintLayer)

        // Main gloss (top-down)
        glossLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        glossLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        layer.addSublayer(glossLayer)

        // Soft edge highlight (simulates refraction rim)
        edgeHighlight.startPoint = CGPoint(x: 0.0, y: 0.0)
        edgeHighlight.endPoint   = CGPoint(x: 1.0, y: 1.0)
        edgeHighlight.opacity = 0.35
        layer.addSublayer(edgeHighlight)

        borderLayer.borderWidth = 0.6
        layer.addSublayer(borderLayer)

        preferencesObserver = NotificationCenter.default.addObserver(
            forName: .glassPreferencesDidChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateAppearance()
        }

        applyCorners()
        updateAppearance()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        let b = bounds
        tintLayer.frame = b
        glossLayer.frame = b
        edgeHighlight.frame = b
        borderLayer.frame = b
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }

    private func applyCorners() {
        let r = cornerRadius
        layer.cornerRadius = r
        blurView.layer.cornerRadius = r
        glossLayer.cornerRadius = r
        edgeHighlight.cornerRadius = r
        borderLayer.cornerRadius = r
        // Continuous corner feel (iOS 26 style)
        if #available(iOS 13.0, *) {
            layer.cornerCurve = .continuous
            blurView.layer.cornerCurve = .continuous
        }
    }

    private func updateAppearance() {
        let prefs = GlassPreferences.shared

        guard prefs.isEnabled else {
            blurView.effect = nil
            tintLayer.backgroundColor = UIColor.clear.cgColor
            glossLayer.colors = [UIColor.clear.cgColor]
            edgeHighlight.colors = [UIColor.clear.cgColor]
            borderLayer.borderColor = UIColor.clear.cgColor
            return
        }

        let isDark = traitCollection.userInterfaceStyle == .dark
        let intensity = isDark ? prefs.darkIntensity : prefs.lightIntensity

        // Material choice
        let blurStyle: UIBlurEffect.Style
        switch prefs.glassMode {
        case 1: // Clear
            blurStyle = prefs.lightweightMode ? .systemUltraThinMaterial : .systemThinMaterial
        case 2: // Tinted
            blurStyle = .systemMaterial
        default: // Frosted
            blurStyle = prefs.lightweightMode ? .systemThinMaterial : .systemMaterial
        }
        blurView.effect = UIBlurEffect(style: blurStyle)

        // Tint
        let tint: UIColor
        if let manual = customTint {
            tint = manual
        } else if let prefTint = prefs.customTint {
            tint = prefTint
        } else {
            tint = isDark
                ? UIColor.white.withAlphaComponent(0.06 * intensity + 0.02)
                : UIColor.white.withAlphaComponent(0.10 * intensity + 0.04)
        }
        tintLayer.backgroundColor = tint.cgColor

        // Main gloss
        let topAlpha: CGFloat = prefs.lightweightMode ? 0.25 : 0.42
        glossLayer.colors = [
            UIColor.white.withAlphaComponent(topAlpha * intensity).cgColor,
            UIColor.white.withAlphaComponent(0.06 * intensity).cgColor,
            UIColor.clear.cgColor
        ]
        glossLayer.locations = [0.0, 0.28, 1.0]

        // Edge highlight (refraction-like rim)
        let rimAlpha = prefs.chromaticAberration ? 0.22 : 0.14
        edgeHighlight.colors = [
            UIColor.white.withAlphaComponent(rimAlpha * intensity).cgColor,
            UIColor.clear.cgColor,
            UIColor.white.withAlphaComponent(rimAlpha * 0.6 * intensity).cgColor
        ]
        edgeHighlight.locations = [0.0, 0.5, 1.0]

        // Border
        borderLayer.borderColor = (isDark
            ? UIColor.white.withAlphaComponent(0.14 + 0.10 * intensity)
            : UIColor.white.withAlphaComponent(0.22 + 0.12 * intensity)).cgColor
        borderLayer.borderWidth = prefs.lightweightMode ? 0.45 : 0.65

        // Debug overlay
        if prefs.debugOverlay {
            layer.borderColor = UIColor.systemGreen.withAlphaComponent(0.6).cgColor
            layer.borderWidth = 1.0
        }
    }

    // MARK: - Touch

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isInteractive, GlassPreferences.shared.isEnabled else { return }
        GlassAnimations.pressIn(self, scale: 0.975)
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        resetTransform()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        resetTransform()
    }

    private func resetTransform() {
        guard isInteractive else { return }
        GlassAnimations.pressOut(self)
    }
}
