import UIKit

@objc open class GlassButton: UIButton {

    private let glass = GlassView()

    @objc public var glassTint: UIColor = UIColor.white.withAlphaComponent(0.13) {
        didSet { glass.glassTint = glassTint }
    }

    @objc public var glossIntensity: CGFloat = 0.55 {
        didSet { glass.glossIntensity = glossIntensity }
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
        contentEdgeInsets = UIEdgeInsets(top: 13, left: 20, bottom: 13, right: 20)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glass.cornerRadius = min(bounds.height / 2.15, 22)
    }

    public override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.18, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
            }
        }
    }
}
