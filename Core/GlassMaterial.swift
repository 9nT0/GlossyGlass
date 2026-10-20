import UIKit
import QuartzCore

@objc public final class GlassMaterial: NSObject {
    @objc public static let shared = GlassMaterial()
    private let effectTag = 0x4747_4546
    private let rimTag = 0x4747_5249
    private let glossTag = 0x4747_474C
    private let bloomTag = 0x4747_424C
    private let tintTag = 0x4747_544E

    @objc public func apply(to host: UIView, style: GlassStyle = .standard, corner: CGFloat = 0) {
        let p = GlassPreferences.shared
        guard p.isEnabled, !p.safeMode else { remove(from: host); return }
        remove(from: host)

        let glossy = p.glossyMode
        let blur: UIBlurEffect.Style = glossy ? .systemThinMaterialDark :
            (p.intensity > 0.8 ? .systemChromeMaterialDark : .systemUltraThinMaterialDark)

        let effect = UIVisualEffectView(effect: UIBlurEffect(style: blur))
        effect.tag = effectTag
        effect.isUserInteractionEnabled = false
        effect.translatesAutoresizingMaskIntoConstraints = false
        effect.alpha = p.opacity
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
            effect.layer.cornerCurve = .continuous
            effect.layer.cornerRadius = corner
            effect.clipsToBounds = true
        }

        if glossy {
            addTint(host, p.intensity)
            addRim(host, p.intensity, corner, true)
            addGloss(host)
            addBloom(host, p.intensity)
        } else if p.intensity > 0.65 {
            addRim(host, p.intensity * 0.7, corner, false)
        }
        host.backgroundColor = .clear
        host.isOpaque = false
    }

    @objc public func applyCircle(to host: UIView) {
        let p = GlassPreferences.shared
        guard p.isEnabled, !p.safeMode else { return }
        remove(from: host)
        let size = max(min(host.bounds.width, host.bounds.height), 40)
        let r = size / 2

        let effect = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        effect.tag = effectTag
        effect.isUserInteractionEnabled = false
        effect.translatesAutoresizingMaskIntoConstraints = false
        effect.alpha = p.opacity
        effect.layer.cornerCurve = .continuous
        effect.layer.cornerRadius = r
        effect.clipsToBounds = true
        host.insertSubview(effect, at: 0)
        NSLayoutConstraint.activate([
            effect.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            effect.centerYAnchor.constraint(equalTo: host.centerYAnchor),
            effect.widthAnchor.constraint(equalToConstant: size),
            effect.heightAnchor.constraint(equalToConstant: size)
        ])
        host.layer.cornerCurve = .continuous
        host.layer.cornerRadius = r
        host.clipsToBounds = true
        host.backgroundColor = .clear

        let ring = UIView()
        ring.tag = rimTag
        ring.isUserInteractionEnabled = false
        ring.translatesAutoresizingMaskIntoConstraints = false
        ring.backgroundColor = .clear
        ring.layer.borderWidth = p.glossyMode ? 1.2 : 0.8
        ring.layer.borderColor = UIColor.white.withAlphaComponent(p.glossyMode ? 0.35 : 0.22).cgColor
        ring.layer.cornerRadius = r
        host.addSubview(ring)
        NSLayoutConstraint.activate([
            ring.centerXAnchor.constraint(equalTo: host.centerXAnchor),
            ring.centerYAnchor.constraint(equalTo: host.centerYAnchor),
            ring.widthAnchor.constraint(equalToConstant: size),
            ring.heightAnchor.constraint(equalToConstant: size)
        ])
        if p.glossyMode { addBloom(host, p.intensity) }
    }

    @objc public func remove(from host: UIView) {
        [effectTag, rimTag, glossTag, bloomTag, tintTag].forEach { host.viewWithTag($0)?.removeFromSuperview() }
    }

    private func addTint(_ host: UIView, _ i: CGFloat) {
        let v = UIView()
        v.tag = tintTag
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor(red: 0.55, green: 0.65, blue: 1.0, alpha: 0.06 * i)
        host.insertSubview(v, at: 1)
        pin(v, host)
    }
    private func addRim(_ host: UIView, _ i: CGFloat, _ c: CGFloat, _ strong: Bool) {
        let v = UIView()
        v.tag = rimTag
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = .clear
        v.layer.borderWidth = strong ? 0.9 : 0.55
        v.layer.borderColor = UIColor.white.withAlphaComponent((strong ? 0.28 : 0.16) * i).cgColor
        v.layer.cornerCurve = .continuous
        v.layer.cornerRadius = c
        host.addSubview(v)
        pin(v, host)
    }
    private func addGloss(_ host: UIView) {
        let v = UIView()
        v.tag = glossTag
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.09)
        host.addSubview(v)
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: host.topAnchor),
            v.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            v.heightAnchor.constraint(equalTo: host.heightAnchor, multiplier: 0.38)
        ])
    }
    private func addBloom(_ host: UIView, _ i: CGFloat) {
        let v = UIView()
        v.tag = bloomTag
        v.isUserInteractionEnabled = false
        v.translatesAutoresizingMaskIntoConstraints = false
        v.backgroundColor = UIColor.white.withAlphaComponent(0.04 * i)
        v.layer.shadowColor = UIColor.white.cgColor
        v.layer.shadowOpacity = Float(0.35 * i)
        v.layer.shadowRadius = 12
        v.layer.shadowOffset = .zero
        host.addSubview(v)
        pin(v, host)
    }
    private func pin(_ v: UIView, _ h: UIView) {
        NSLayoutConstraint.activate([
            v.topAnchor.constraint(equalTo: h.topAnchor),
            v.bottomAnchor.constraint(equalTo: h.bottomAnchor),
            v.leadingAnchor.constraint(equalTo: h.leadingAnchor),
            v.trailingAnchor.constraint(equalTo: h.trailingAnchor)
        ])
    }
}

@objc public enum GlassStyle: Int {
    case standard = 0, pill = 1, strong = 2, soft = 3
}
