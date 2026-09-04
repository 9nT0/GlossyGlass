import UIKit

/// Clean glossy glass view with adaptive Light/Dark support and stable layers
@objc open class GlassView: UIView {

    // MARK: - Public

    @objc public var glossIntensity: CGFloat = 0.50 {
        didSet { updateAppearance() }
    }

    @objc public var cornerRadius: CGFloat = 22 {
        didSet { applyCorners() }
    }

    @objc public var isInteractive: Bool = true

    /// Optional manual tint. When nil, uses adaptive system style.
    @objc public var customTint: UIColor? = nil {
        didSet { updateAppearance() }
    }

    // MARK: - Private layers

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let tintLayer = CALayer()
    private let glossLayer = CAGradientLayer()
    private let borderLayer = CALayer()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        clipsToBounds = true
        isUserInteractionEnabled = true

        // Blur – lightest material for performance
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
        let isDark = traitCollection.userInterfaceStyle == .dark

        // Adaptive tint
        let tint: UIColor
        if let custom = customTint {
            tint = custom
        } else {
            tint = isDark
                ? UIColor.white.withAlphaComponent(0.08)
                : UIColor.white.withAlphaComponent(0.13)
        }
        tintLayer.backgroundColor = tint.cgColor

        // Adaptive gloss (softer in dark mode)
        let intensity = isDark ? glossIntensity * 0.75 : glossIntensity
        glossLayer.colors = [
            UIColor.white.withAlphaComponent(0.38 * intensity).cgColor,
            UIColor.white.withAlphaComponent(0.08 * intensity).cgColor,
            UIColor.clear.cgColor
        ]
        glossLayer.locations = [0.0, 0.32, 1.0]

        // Adaptive border
        borderLayer.borderColor = (isDark
            ? UIColor.white.withAlphaComponent(0.18)
            : UIColor.white.withAlphaComponent(0.30)).cgColor
    }

    // MARK: - Touch

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isInteractive else { return }
        UIView.animate(withDuration: 0.16, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5) {
            self.transform = CGAffineTransform(scaleX: 0.975, y: 0.975)
        }
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
        UIView.animate(withDuration: 0.26, delay: 0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.4) {
            self.transform = .identity
        }
    }
}
