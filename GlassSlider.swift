import UIKit

@objc open class GlassSlider: UISlider {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        // Lighter track for performance
        minimumTrackTintColor = UIColor.label.withAlphaComponent(0.75)
        maximumTrackTintColor = UIColor.label.withAlphaComponent(0.15)

        let thumb = makeThumb()
        setThumbImage(thumb, for: .normal)
        setThumbImage(thumb, for: .highlighted)
    }

    private func makeThumb() -> UIImage {
        let size: CGFloat = 22
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let rect = CGRect(x: 1.5, y: 1.5, width: size-3, height: size-3)
            ctx.cgContext.setShadow(offset: CGSize(width: 0, height: 1.5), blur: 3, color: UIColor.black.withAlphaComponent(0.22).cgColor)
            UIColor.white.setFill()
            UIBezierPath(ovalIn: rect).fill()
        }
    }

    public override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var r = super.trackRect(forBounds: bounds)
        r.size.height = 4.5
        r.origin.y = (bounds.height - 4.5) / 2
        return r
    }
}
