import UIKit

/// GlossyGlass v3 renderer
/// Layer stack (bottom → top):
///   blur → vibrancy → dimming → tint → noise → gloss → bloom → edge highlight → border
/// Every preference is consumed. No dead controls.
@objc open class GlassView: UIView {

    // MARK: - Public API

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

    // MARK: - Layers / views

    private let blurView = UIVisualEffectView(effect: nil)
    private let vibrancyView = UIVisualEffectView(effect: nil)
    private let dimmingLayer = CALayer()
    private let tintLayer = CALayer()
    private let noiseLayer = CALayer()
    private let glossLayer = CAGradientLayer()
    private let bloomLayer = CAGradientLayer()
    private let edgeHighlightLayer = CAGradientLayer()
    private let borderLayer = CALayer()

    private var preferencesObserver: NSObjectProtocol?
    private var noiseImage: UIImage?

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
        layer.cornerCurve = .continuous

        // Blur
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.clipsToBounds = true
        addSubview(blurView)

        // Vibrancy sits inside blur content view when enabled
        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        vibrancyView.clipsToBounds = true
        blurView.contentView.addSubview(vibrancyView)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            vibrancyView.topAnchor.constraint(equalTo: blurView.contentView.topAnchor),
            vibrancyView.leadingAnchor.constraint(equalTo: blurView.contentView.leadingAnchor),
            vibrancyView.trailingAnchor.constraint(equalTo: blurView.contentView.trailingAnchor),
            vibrancyView.bottomAnchor.constraint(equalTo: blurView.contentView.bottomAnchor)
        ])

        // Order matters (bottom → top)
        layer.addSublayer(dimmingLayer)
        layer.addSublayer(tintLayer)
        layer.addSublayer(noiseLayer)
        glossLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        glossLayer.endPoint   = CGPoint(x: 0.5, y: 1.0)
        layer.addSublayer(glossLayer)

        bloomLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        bloomLayer.endPoint   = CGPoint(x: 0.5, y: 0.55)
        layer.addSublayer(bloomLayer)

        edgeHighlightLayer.startPoint = CGPoint(x: 0.5, y: 0.0)
        edgeHighlightLayer.endPoint   = CGPoint(x: 0.5, y: 0.18)
        layer.addSublayer(edgeHighlightLayer)

        borderLayer.borderWidth = 0.55
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

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        let b = bounds
        dimmingLayer.frame = b
        tintLayer.frame = b
        noiseLayer.frame = b
        glossLayer.frame = b
        bloomLayer.frame = b
        edgeHighlightLayer.frame = b
        borderLayer.frame = b
        applyCorners()
    }

    private func applyCorners() {
        let prefs = GlassPreferences.shared
        let r = min(max(0, prefs.cornerRadius > 0 ? prefs.cornerRadius : cornerRadius),
                    min(bounds.width, bounds.height) / 2)
        let continuous: CALayerCornerCurve = .continuous

        layer.cornerRadius = r
        layer.cornerCurve = continuous
        blurView.layer.cornerRadius = r
        blurView.layer.cornerCurve = continuous
        blurView.clipsToBounds = true
        vibrancyView.layer.cornerRadius = r
        vibrancyView.layer.cornerCurve = continuous

        dimmingLayer.cornerRadius = r
        tintLayer.cornerRadius = r
        noiseLayer.cornerRadius = r
        glossLayer.cornerRadius = r
        bloomLayer.cornerRadius = r
        edgeHighlightLayer.cornerRadius = r
        borderLayer.cornerRadius = r
        borderLayer.cornerCurve = continuous
    }

    // MARK: - Appearance (consumes ALL preferences)

    @objc public func updateAppearance() {
        let prefs = GlassPreferences.shared

        guard prefs.isEnabled else {
            blurView.effect = nil
            vibrancyView.effect = nil
            dimmingLayer.backgroundColor = UIColor.clear.cgColor
            tintLayer.backgroundColor = UIColor.clear.cgColor
            noiseLayer.contents = nil
            noiseLayer.opacity = 0
            glossLayer.colors = [UIColor.clear.cgColor]
            bloomLayer.colors = [UIColor.clear.cgColor]
            edgeHighlightLayer.colors = [UIColor.clear.cgColor]
            borderLayer.borderColor = UIColor.clear.cgColor
            return
        }

        // Accessibility: Reduce Transparency → solid-ish fallback
        let reduceTransparency = UIAccessibility.isReduceTransparencyEnabled

        let isDark = traitCollection.userInterfaceStyle == .dark
        let masterOpacity = max(0, min(1, prefs.opacity))
        let effectiveIntensity = max(0, min(1,
            (isDark ? prefs.darkIntensity : prefs.lightIntensity) * prefs.intensity
        ))

        // MARK: Style → blur material
        let blurStyle: UIBlurEffect.Style
        switch prefs.style.lowercased() {
        case "clear":
            blurStyle = .systemUltraThinMaterial
        case "tinted":
            blurStyle = isDark ? .systemThinMaterialDark : .systemThinMaterialLight
        default: // Frosted
            if prefs.lightweightMode {
                blurStyle = .systemUltraThinMaterial
            } else {
                blurStyle = .systemThinMaterial
            }
        }

        if reduceTransparency || !prefs.blurEnabled {
            blurView.effect = nil
            // Compensate with a soft fill so the surface doesn't disappear
            let fill = isDark
                ? UIColor.secondarySystemBackground.withAlphaComponent(0.92 * masterOpacity)
                : UIColor.secondarySystemBackground.withAlphaComponent(0.88 * masterOpacity)
            backgroundColor = fill
        } else {
            backgroundColor = .clear
            blurView.effect = UIBlurEffect(style: blurStyle)
        }

        // MARK: Vibrancy
        if prefs.vibrancyEnabled && prefs.blurEnabled && !reduceTransparency {
            let blur = UIBlurEffect(style: blurStyle)
            vibrancyView.effect = UIVibrancyEffect(blurEffect: blur, style: .label)
            vibrancyView.isHidden = false
        } else {
            vibrancyView.effect = nil
            vibrancyView.isHidden = true
        }

        // MARK: Dimming (darkens content behind glass slightly)
        let dimAlpha = prefs.dimming * masterOpacity * (isDark ? 0.55 : 0.35)
        dimmingLayer.backgroundColor = UIColor.black.withAlphaComponent(dimAlpha).cgColor

        // MARK: Tint
        let tint: UIColor
        if let manual = customTint {
            tint = manual
        } else if let prefTint = prefs.customTint {
            tint = prefTint
        } else {
            // Saturation-ish boost: stronger white in light, softer in dark
            let base = 0.06 + (prefs.saturation * 0.10)
            tint = isDark
                ? UIColor.white.withAlphaComponent(base * 0.7 * masterOpacity)
                : UIColor.white.withAlphaComponent(base * masterOpacity)
        }
        // Apply overall opacity + intensity to tint
        tintLayer.backgroundColor = tint.withAlphaComponent(
            tint.cgColor.alpha * effectiveIntensity
        ).cgColor

        // MARK: Noise (subtle grain)
        if prefs.noiseEnabled && !prefs.lightweightMode {
            if noiseImage == nil {
                noiseImage = Self.makeNoiseImage(size: CGSize(width: 64, height: 64))
            }
            noiseLayer.contents = noiseImage?.cgImage
            noiseLayer.contentsGravity = .resize
            noiseLayer.opacity = Float(0.035 * masterOpacity)
            noiseLayer.isHidden = false
        } else {
            noiseLayer.contents = nil
            noiseLayer.opacity = 0
            noiseLayer.isHidden = true
        }

        // MARK: Gloss (specular gradient)
        let topAlpha: CGFloat = (prefs.lightweightMode ? 0.22 : 0.36) * effectiveIntensity * masterOpacity
        let midAlpha: CGFloat = 0.08 * effectiveIntensity * masterOpacity
        glossLayer.colors = [
            UIColor.white.withAlphaComponent(topAlpha).cgColor,
            UIColor.white.withAlphaComponent(midAlpha).cgColor,
            UIColor.clear.cgColor
        ]
        glossLayer.locations = [0.0, 0.28, 1.0]

        // MARK: Light Bloom (soft top glow)
        if prefs.lightBloomEnabled && !prefs.lightweightMode {
            let bloomAlpha = 0.10 * effectiveIntensity * masterOpacity
            bloomLayer.colors = [
                UIColor.white.withAlphaComponent(bloomAlpha).cgColor,
                UIColor.clear.cgColor
            ]
            bloomLayer.locations = [0.0, 1.0]
            bloomLayer.isHidden = false
        } else {
            bloomLayer.colors = [UIColor.clear.cgColor]
            bloomLayer.isHidden = true
        }

        // MARK: Edge highlight (refraction-like rim from v2)
        if prefs.edgeHighlightEnabled {
            let rimAlpha: CGFloat = (prefs.lightweightMode ? 0.10 : 0.16) * effectiveIntensity * masterOpacity
            edgeHighlightLayer.colors = [
                UIColor.white.withAlphaComponent(rimAlpha).cgColor,
                UIColor.clear.cgColor
            ]
            edgeHighlightLayer.locations = [0.0, 1.0]
            edgeHighlightLayer.isHidden = false
        } else {
            edgeHighlightLayer.colors = [UIColor.clear.cgColor]
            edgeHighlightLayer.isHidden = true
        }

        // MARK: Border
        let borderAlpha: CGFloat = (isDark ? 0.14 : 0.26) * masterOpacity
        borderLayer.borderColor = UIColor.white.withAlphaComponent(borderAlpha).cgColor
        borderLayer.borderWidth = prefs.lightweightMode ? 0.4 : 0.55
    }

    // MARK: - Noise texture generator

    private static func makeNoiseImage(size: CGSize) -> UIImage? {
        let w = Int(size.width)
        let h = Int(size.height)
        guard w > 0, h > 0 else { return nil }

        var pixels = [UInt8](repeating: 0, count: w * h * 4)
        for i in 0..<(w * h) {
            let v = UInt8.random(in: 0...255)
            let o = i * 4
            pixels[o] = v
            pixels[o + 1] = v
            pixels[o + 2] = v
            pixels[o + 3] = 40 // low alpha grain
        }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(
            data: &pixels,
            width: w,
            height: h,
            bitsPerComponent: 8,
            bytesPerRow: w * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ), let cg = ctx.makeImage() else { return nil }

        return UIImage(cgImage: cg)
    }

    // MARK: - Trait changes

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateAppearance()
        }
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
