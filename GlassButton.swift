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
        // Respect preference for buttons
        guard GlassPreferences.shared.styleButtons else {
            // Still create a basic button look if styling is disabled
            backgroundColor = .clear
            return
        }

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

        // Observe preference changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(preferencesChanged),
            name: .glassPreferencesDidChange,
            object: nil
        )
    }

    @objc private func preferencesChanged() {
        glass.isHidden = !GlassPreferences.shared.isEnabled || !GlassPreferences.shared.styleButtons
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        glass.cornerRadius = min(bounds.height / 2.2, 20)
    }

    public override var isHighlighted: Bool {
        didSet {
            guard GlassPreferences.shared.isEnabled else { return }
            if isHighlighted {
                GlassAnimations.pressIn(self, scale: 0.965)
            } else {
                GlassAnimations.pressOut(self)
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
