import UIKit

@objc public final class GlassMaterial: NSObject {
    @objc public static let shared = GlassMaterial()

    private let effectTag = 0x4747_4546
    private let rimTag    = 0x4747_5249
    private let glossTag  = 0x4747_474C

    /// Apply liquid glass directly onto a real host view.
    @objc public func apply(to host: UIView, style: GlassStyle = .standard, corner: CGFloat = 0) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else {
            remove(from: host)
            return
        }

        remove(from: host)

        let intensity = prefs.intensity
        let opacity = prefs.opacity
        let glossy = prefs.glossyMode

        let blurStyle: UIBlurEffect.Style
        switch style {
        case .pill, .strong:
            blurStyle = glossy ? .systemThinMaterialDark : .systemChromeMaterialDark
        case .soft:
            blurStyle = .systemUltraThinMaterialDark
        default:
            blurStyle = intensity > 0.75 ? .systemChromeMaterialDark : .systemUltraThinMaterialDark
        }

        let effect = UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
        effect.tag = effectTag
        effect.isUserInteractionEnabled = false
        effect.translatesAutoresizingMaskIntoConstraints = false
        effect.alpha = opacity

        host.insertSubview(effect, at: 0)
        NSLayoutConstraint.activate([
            effect.topAnchor.constraint(equalTo: host.topAnchor),
            effect.bottomAnchor.constraint(equalTo: host.bottomAnchor),
            effect.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            effect.trailingAnchor.constraint(equalTo: host.trailingAnchor)
        ])

        host.layer.cornerCurve = .continuous
        if corner > 0 {
            host.layer.cornerRadius = corner
            host.clipsToBounds = true
        }

        if glossy || intensity > 0.6 {
            addRim(to: host, intensity: intensity, corner: corner)
        }
        if glossy {
            addGloss(to: host)
        }

        host.backgroundColor = .clear
    }

    /// Circular glass treatment (call buttons, etc.)
    @objc public func applyCircle(to host: UIView) {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled, !prefs.safeMode else { return }

        remove(from: host)

        let size = min(host.bounds.width, host.bounds.height)
        let radius = size > 0 ? size / 2 : 22

        let effect = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        effect.tag = effectTag
        effect.isUserInteractionEnabled = false
        effect.translatesAutoresizingMaskIntoConstraints = false
        effect.alpha = prefs.opacity
        effect.layer.cornerCurve = .continuous
        effect.layer.cornerRadius = radius
        effect.clipsToBounds = true

        host.insertSubview(effect, at: 0)
        NSLayoutConstraint.activate([
            effect.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            effect.centerYAnchor.constraint(equalTo: host.centerYAnchor),
            effect.widthAnchor.constraint(equalToConstant: radius * 2),
            effect.heightAnchor.constraint(equalToConstant: radius * 2)
        ])

        host.layer.cornerCurve = .continuous
        host.layer.cornerRadius = radius
        host.clipsToBounds = true
        host.backgroundColor = .clear

        // Soft ring
        let ring = UIView()
        ring.tag = rimTag
        ring.isUserInteractionEnabled = false
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.backgroundColor = .clear
        ring.layer.borderWidth = 1.0
        ring.layer.borderColor = UIColor.white.withAlphaComponent(0.28).cgColor
        ring.layer.cornerRadius = radius
        host.addSubview(ring)
        NSLayoutConstraint.activate([
            ring.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            ring.centerYAnchor.constraint(equalTo: host.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: radius * 2),
            ring.heightAnchor.constraint(equalToConstant: radius * 2)
        ])
    }

    @objc public func remove(from host: UIView) {
        host.viewWithTag(effectTag)?.removeFromSuperview()
        host.viewWithTag(rimTag)?.removeFromSuperview()
        host.viewWithTag(glossTag)?.removeFromSuperview()
    }

    private func addRim(to host: UIView, intensity: CGFloat, corner: CGFloat) {
        let rim = UIView()
        rim.tag = rimTag
        rim.isUserInteractionEnabled = false
        rim.translatesAutoresizingMaskIntoConstraints = false
        rim.backgroundColor = .clear
        rim.layer.borderWidth = 0.7
        rim.layer.borderColor = UIColor.white.withAlphaComponent(0.22 * intensity).cgColor
        rim.layer.cornerCurve = .continuous
        rim.layer.cornerRadius = corner
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
        gloss.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        host.addSubview(gloss)
        NSLayoutConstraint.activate([
            gloss.topAnchor.constraint(equalTo: host.topAnchor),
            gloss.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            gloss.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            gloss.heightAnchor.constraint(equalTo: host.heightAnchor, multiplier: 0.36)
        ])
    }
}

@objc public enum GlassStyle: Int {
    case standard = 0
    case pill = 1
    case strong = 2
    case soft = 3
}
