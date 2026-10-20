import UIKit

@objc public final class GlassIcons: NSObject {
    @objc public static let shared = GlassIcons()

    @objc public func apply(to container: UIView) {
        walk(container) { v in
            if let iv = v as? UIImageView, let img = iv.image {
                iv.image = img.withRenderingMode(.alwaysTemplate)
                iv.tintColor = UIColor.white.withAlphaComponent(0.96)
            }
            if let b = v as? UIButton {
                b.tintColor = UIColor.white.withAlphaComponent(0.96)
            }
        }
    }

    private func walk(_ v: UIView, depth: Int = 0, max: Int = 7, block: (UIView) -> Void) {
        guard depth < max else { return }
        block(v)
        for s in v.subviews { walk(s, depth: depth + 1, max: max, block: block) }
    }
}
