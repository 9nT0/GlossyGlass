//
//  GlassMaterial.swift
//  GlossyGlass v5
//
//  Real material engine. Paints ON the host view — no floating overlays.
//

import UIKit

@objc public final class GlassMaterial: NSObject {

    @objc public static let shared = GlassMaterial()

    // Tags so we can find / update our own layers without polluting the hierarchy
    private let effectTag  = 0x4747_4546 // GGEF
    private let rimTag     = 0x4747_5249 // GGRI
    private let glossTag   = 0x4747_474C // GGGL

    // MARK: - Public apply

    /// Apply liquid glass material directly onto a host view.
    /// Call this on the real tab bar / nav bar / button background.
    @objc public func apply(to host: UIView, compact: Bool = false) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else {
            remove(from: host)
            return
        }

        // Clean previous material if any
        remove(from: host)

        let intensity = prefs.intensity
        let opacity   = prefs.opacity
        let glossy    = prefs.glossyMode

        // Base blur
        let style: UIBlurEffect.Style
        if glossy {
            // Stronger, more “liquid” look for Glossy Mode
            style = .systemThinMaterialDark
        } else {
            style = intensity > 0.7 ? .systemChromeMaterialDark : .systemUltraThinMaterialDark
        }

        let effectView = UIVisualEffectView(effect: UIBlurEffect(style: style))
        effectView.tag = effectTag
        effectView.isUserInteractionEnabled = false
        effectView.translatesAutoresizingMaskIntoConstraints = false
        effectView.alpha = opacity

        host.insertSubview(effectView, at: 0)

        NSLayoutConstraint.activate([
            effectView.topAnchor.constraint(equalTo: host.topAnchor),
            effectView.bottomAnchor.constraint(equalTo: host.bottomAnchor),
            effectView.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            effectView.trailingAnchor.constraint(equalTo: host.trailingAnchor)
        ])

        // Continuous corner (iOS 26 feel)
        host.layer.cornerCurve = .continuous
        if compact {
            host.layer.cornerRadius = 22
            host.clipsToBounds = true
        } else {
            host.layer.cornerRadius = 0
        }

        // Specular rim (cheap, no extra views when possible)
        if glossy || intensity > 0.6 {
            addRim(to: host, intensity: intensity)
        }

        // Soft top gloss for liquid feel
        if glossy {
            addGloss(to: host)
        }
    }

    // MARK: - Remove

    @objc public func remove(from host: UIView) {
        host.viewWithTag(effectTag)?.removeFromSuperview()
        host.viewWithTag(rimTag)?.removeFromSuperview()
        host.viewWithTag(glossTag)?.removeFromSuperview()
        host.layer.cornerRadius = 0
        host.clipsToBounds = false
    }

    // MARK: - Private helpers

    private func addRim(to host: UIView, intensity: CGFloat) {
        let rim = UIView()
        rim.tag = rimTag
        rim.isUserInteractionEnabled = false
        rim.translatesAutoresizingMaskIntoConstraints = false
        rim.backgroundColor = .clear
        rim.layer.borderWidth = 0.6
        rim.layer.borderColor = UIColor.white.withAlphaComponent(0.18 * intensity).cgColor
        rim.layer.cornerCurve = .continuous
        rim.layer.cornerRadius = host.layer.cornerRadius

        host.addSubview(rim)
        NSLayoutConstraint.activate([
            rim.topAnchor.constraint(equalTo: host.topAnchor),
            rim.bottomAnchor.constraint(equalTo: host.bottomAnchor),
            rim.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            rim.trailingAnchor.constraint(equalTo: host.trailingAnchor)
        ])
    }

    private func addGloss(to host: UIView) {
        let gloss = UIView()
        gloss.tag = glossTag
        gloss.isUserInteractionEnabled = false
        gloss.translatesAutoresizingMaskIntoConstraints = false
        gloss.backgroundColor = UIColor.white.withAlphaComponent(0.06)

        host.addSubview(gloss)
        NSLayoutConstraint.activate([
            gloss.topAnchor.constraint(equalTo: host.topAnchor),
            gloss.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            gloss.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            gloss.heightAnchor.constraint(equalTo: host.heightAnchor, multiplier: 0.35)
        ])
    }
}
