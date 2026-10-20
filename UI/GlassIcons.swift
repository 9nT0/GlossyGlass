//
//  GlassIcons.swift
//  GlossyGlass v5
//
//  Remade / improved icons for Glossy Mode.
//  Uses SF Symbols with glass-friendly configuration + light tinting.
//

import UIKit

@objc public final class GlassIcons: NSObject {

    @objc public static let shared = GlassIcons()

    /// Apply improved icon treatment to a container (usually the tab bar).
    @objc public func apply(to container: UIView) {
        // Walk the subviews looking for UIImageViews / UIButtons that hold icons
        walk(container) { view in
            if let imageView = view as? UIImageView, let image = imageView.image {
                // Prefer template rendering so tint works
                imageView.image = image.withRenderingMode(.alwaysTemplate)
                imageView.tintColor = UIColor.white.withAlphaComponent(0.95)
            }

            if let button = view as? UIButton {
                button.tintColor = UIColor.white.withAlphaComponent(0.95)
                // Slightly larger hit target feel
                button.contentEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
            }
        }
    }

    /// Returns a glass-friendly SF Symbol configuration
    @objc public func glassSymbol(named name: String, pointSize: CGFloat = 22) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: .medium)
        return UIImage(systemName: name, withConfiguration: config)?
            .withRenderingMode(.alwaysTemplate)
    }

    // MARK: - Private

    private func walk(_ view: UIView, depth: Int = 0, maxDepth: Int = 6, block: (UIView) -> Void) {
        guard depth < maxDepth else { return }
        block(view)
        for sub in view.subviews {
            walk(sub, depth: depth + 1, maxDepth: maxDepth, block: block)
        }
    }
}
