import UIKit

/// Large catalog of named liquid-glass materials + Instagram screen profiles.
@objc public final class GlassMaterialCatalog: NSObject {

    @objc public static let shared = GlassMaterialCatalog()

    @objc public struct Material {
        public let id: String
        public let title: String
        public let style: String
        public let intensity: CGFloat
        public let opacity: CGFloat
        public let saturation: CGFloat
        public let dimming: CGFloat
        public let blur: Bool
        public let edge: Bool
        public let bloom: Bool
    }

    private lazy var all: [Material] = buildCatalog()

    @objc public func materialCount() -> Int { all.count }

    @objc public func materialIDs() -> [String] { all.map { $0.id } }

    @objc public func applyMaterial(id: String) {
        guard let m = all.first(where: { $0.id == id }) else { return }
        let p = GlassPreferences.shared
        p.style = m.style
        p.intensity = m.intensity
        p.opacity = m.opacity
        p.saturation = m.saturation
        p.dimming = m.dimming
        p.blurEnabled = m.blur
        p.edgeHighlightEnabled = m.edge
        p.lightBloomEnabled = m.bloom
        GlassStyleApplicator.applyAll()
    }

    @objc public func catalogJSON() -> String {
        let rows: [[String: Any]] = all.map {
            [
                "id": $0.id, "title": $0.title, "style": $0.style,
                "intensity": $0.intensity, "opacity": $0.opacity,
                "saturation": $0.saturation, "dimming": $0.dimming
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: rows, options: [.prettyPrinted]),
              let s = String(data: data, encoding: .utf8) else { return "[]" }
        return s
    }

    private func buildCatalog() -> [Material] {
        var items: [Material] = []
        let styles = ["clear", "frosted", "tinted", "liquid"]
        let names = [
            "Ice", "Mist", "Pearl", "Smoke", "Obsidian", "Crystal", "Aurora", "Nova",
            "Harbor", "Glacier", "Silk", "Chrome", "Mercury", "Opal", "Quartz", "Dawn",
            "Dusk", "Midnight", "Halo", "Prism", "Nebula", "Frostbite", "Dew", "Foam",
            "Tide", "Lagoon", "Polar", "Silver", "Platinum", "Ghost", "Vapor", "Cloud"
        ]
        var idx = 0
        for style in styles {
            for n in names {
                let i = CGFloat((idx % 10)) / 10.0
                items.append(Material(
                    id: "\(style)_\(n.lowercased())_\(idx)",
                    title: "\(n) \(style.capitalized)",
                    style: style,
                    intensity: 0.35 + i * 0.55,
                    opacity: 0.7 + (i * 0.25),
                    saturation: 0.5 + (i * 0.45),
                    dimming: max(0, 0.25 - i * 0.2),
                    blur: true,
                    edge: idx % 2 == 0,
                    bloom: idx % 3 == 0
                ))
                idx += 1
            }
        }
        // Screen-specific IG profiles
        let screens = ["feed", "profile", "messages", "reels", "explore", "story", "settings"]
        for s in screens {
            items.append(Material(
                id: "ig_\(s)_liquid",
                title: "IG \(s.capitalized) Liquid",
                style: "liquid",
                intensity: s == "reels" ? 0.4 : 0.62,
                opacity: 0.88,
                saturation: 0.7,
                dimming: s == "reels" ? 0.1 : 0.2,
                blur: true, edge: true, bloom: s != "reels"
            ))
        }
        return items
    }
}
