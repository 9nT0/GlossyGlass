import UIKit

@objc open class GlassButton: UIButton {

    private let glass = GlassView()

    @objc public var glossIntensity: CGFloat = 0.50 {
        didSet { glass.glossIntensity = glossIntensity }
    }

    @objc public var customTint: UIColor? = nil {
        didSet { glass.customTint = customTint }
    }

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
        glass.isUserInteractionEnabled = false
        glass.isInteractive = false
        glass.translatesAutoresizingMaskIntoConstraints = false
        insertSubview(glass, at: 0)

        NSLayoutConstraint.activate([
            glass.topAnchor.constraint(equalTo: topAnchor),
            glass.leadingAnchor.constraint(equalTo: leadingAnchor),
            glass.trailingAnchor.constraint(equalTo: trailingAnchor),
            glass.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        setTitleColor(.label, for: .normal)
        setTitleColor(.label.withAlphaComponent(0.55), for: .highlighted)
        contentEdgeInsets = UIEdgeInsets(top: 12, left: 18, bottom: 12, right: 18)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glass.cornerRadius = min(bounds.height / 2.2, 20)
    }

    public override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.16, delay: 0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.965, y: 0.965) : .identity
            }
        }
    }
}
