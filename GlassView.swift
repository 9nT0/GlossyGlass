import UIKit

@objc open class GlassView: UIView {

    @objc public var glassTint: UIColor = UIColor.white.withAlphaComponent(0.12) {
        didSet { update() }
    }

    @objc public var glossIntensity: CGFloat = 0.55 {
        didSet { update() }
    }

    @objc public var cornerRadius: CGFloat = 22 {
        didSet {
            layer.cornerRadius = cornerRadius
            blurView.layer.cornerRadius = cornerRadius
            glossLayer.cornerRadius = cornerRadius
            borderLayer.cornerRadius = cornerRadius
        }
    }

    @objc public var isInteractive: Bool = true

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterial))
    private let tintLayer = CALayer()
    private let glossLayer = CAGradientLayer()
    private let borderLayer = CALayer()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
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
        glossLayer.startPoint = CGPoint(x: 0.5, y: 0)
        glossLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.addSublayer(glossLayer)

        borderLayer.borderWidth = 0.6
        layer.addSublayer(borderLayer)

        layer.cornerRadius = cornerRadius
        blurView.layer.cornerRadius = cornerRadius
        update()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        tintLayer.frame = bounds
        glossLayer.frame = bounds
        borderLayer.frame = bounds
    }

    private func update() {
        tintLayer.backgroundColor = glassTint.cgColor
        glossLayer.colors = [
            UIColor.white.withAlphaComponent(0.45 * glossIntensity).cgColor,
            UIColor.white.withAlphaComponent(0.10 * glossIntensity).cgColor,
            UIColor.clear.cgColor
        ]
        glossLayer.locations = [0.0, 0.35, 1.0]
        borderLayer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard isInteractive else { return }
        UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        reset()
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        reset()
    }

    private func reset() {
        guard isInteractive else { return }
        UIView.animate(withDuration: 0.28, delay: 0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.4) {
            self.transform = .identity
        }
    }
}
