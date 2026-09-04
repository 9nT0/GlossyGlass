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
        minimumTrackTintColor = UIColor.white.withAlphaComponent(0.85)
        maximumTrackTintColor = UIColor.white.withAlphaComponent(0.20)
        let thumb = makeThumb()
        setThumbImage(thumb, for: .normal)
        setThumbImage(thumb, for: .highlighted)
    }

    private func makeThumb() -> UIImage {
        let size: CGFloat = 24
        let r = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return r.image { ctx in
            let rect = CGRect(x: 1, y: 1, width: size-2, height: size-2)
            ctx.cgContext.setShadow(offset: CGSize(width: 0, height: 2), blur: 4, color: UIColor.black.withAlphaComponent(0.25).cgColor)
            UIColor.white.setFill()
            UIBezierPath(ovalIn: rect).fill()
        }
    }

    public override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var r = super.trackRect(forBounds: bounds)
        r.size.height = 5
        r.origin.y = (bounds.height - 5) / 2
        return r
    }
}
