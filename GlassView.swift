import UIKit

/// Clean glossy glass view with adaptive Light/Dark support,
/// stable layers, and full preference support.
@objc open class GlassView: UIView {

    // MARK: - Public API

    @objc public var glossIntensity: CGFloat = 0.50 {
        didSet { updateAppearance() }
    }

    @objc public var cornerRadius: CGFloat = 22 {
        didSet { applyCorners() }
    }

    @objc public var isInteractive: Bool = true

    /// Optional manual tint. When nil, uses adaptive system style or preferences.
    @objc public var customTint: UIColor? = nil {
        didSet { updateAppearance() }
    }

    // MARK: - Private layers

    private let blurView = UIVisualEffectView(effect: nil)
    private let tintLayer = CALayer()
    private let glossLayer = CAGradientLayer()
    private let borderLayer = CALayer()

    private var preferencesObserver: NSObjectProtocol?

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    deinit {
        if let observer = preferencesObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    private func commonInit() {
        backgroundColor = .clear
        clipsToBounds = true
        isUserInteractionEnabled = true

        // Blur
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
        glossLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        glossLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        layer.addSublayer(glossLayer)

        borderLayer.borderWidth = 0.55
        layer.addSublayer(borderLayer)

        // Listen for preference changes
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

    // MARK: - Layout (stable on rotation / size change)

    public override func layoutSubviews() {
        super.layoutSubviews()
        let b = bounds
        tintLayer.frame = b
        glossLayer.frame = b
        borderLayer.frame = b
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
    }

    // MARK: - Appearance

    private func applyCorners() {
        let r = cornerRadius
        layer.cornerRadius = r
        blurView.layer.cornerRadius = r
        glossLayer.cornerRadius = r
        borderLayer.cornerRadius = r
    }

    private func updateAppearance() {
        let prefs = GlassPreferences.shared

        // Master switch – if disabled, make everything transparent
        guard prefs.isEnabled else {
            blurView.effect = nil
            tintLayer.backgroundColor = UIColor.clear.cgColor
            glossLayer.colors = [UIColor.clear.cgColor]
            borderLayer.borderColor = UIColor.clear.cgColor
            return
        }

        let isDark = traitCollection.userInterfaceStyle == .dark
        let intensity = prefs.glossIntensity

        // Blur style – lighter material in lightweight mode
        let blurStyle: UIBlurEffect.Style = prefs.lightweightMode
            ? .systemUltraThinMaterial
            : .systemThinMaterial
        blurView.effect = UIBlurEffect(style: blurStyle)

        // Tint
        let tint: UIColor
        if let manual = customTint {
            tint = manual
        } else if let prefTint = prefs.customTint {
            tint = prefTint
        } else {
            tint = isDark
                ? UIColor.white.withAlphaComponent(0.07)
                : UIColor.white.withAlphaComponent(0.12)
        }
        tintLayer.backgroundColor = tint.cgColor

        // Gloss (softer in dark mode + respects intensity)
        let adjustedIntensity = isDark ? intensity * 0.70 : intensity
        let topAlpha: CGFloat = prefs.lightweightMode ? 0.28 : 0.38
        glossLayer.colors = [
            UIColor.white.withAlphaComponent(topAlpha * adjustedIntensity).cgColor,
            UIColor.white.withAlphaComponent(0.07 * adjustedIntensity).cgColor,
            UIColor.clear.cgColor
        ]
        glossLayer.locations = [0.0, 0.30, 1.0]

        // Border
        borderLayer.borderColor = (isDark
            ? UIColor.white.withAlphaComponent(0.16)
            : UIColor.white.withAlphaComponent(0.28)).cgColor
        borderLayer.borderWidth = prefs.lightweightMode ? 0.4 : 0.55
    }

    // MARK: - Touch feedback

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

