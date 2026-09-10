import UIKit
import CoreImage

/// Multi-pass effect descriptors + evaluation for liquid / frosted / chrome looks.
@objc public final class GlassEffectPipeline: NSObject {

    @objc public static let shared = GlassEffectPipeline()

    public struct Pass {
        public let name: String
        public let blur: CGFloat
        public let saturation: CGFloat
        public let brightness: CGFloat
        public let opacity: CGFloat
        public let vibrancy: Bool
    }

    @objc public func passes(forStyle style: String, intensity: CGFloat, dark: Bool) -> [[String: CGFloat]] {
        let i = max(0.05, min(1, intensity))
        switch style.lowercased() {
        case "clear":
            return [
                ["blur": 8 * i, "sat": 1.05, "bright": dark ? 0.02 : 0.04, "opacity": 0.55 + 0.3 * i],
                ["blur": 2 * i, "sat": 1.0, "bright": 0, "opacity": 0.25]
            ]
        case "tinted":
            return [
                ["blur": 18 * i, "sat": 1.2, "bright": dark ? -0.04 : 0.06, "opacity": 0.7],
                ["blur": 4, "sat": 1.1, "bright": 0.02, "opacity": 0.35]
            ]
        case "liquid":
            return [
                ["blur": 22 * i, "sat": 1.15, "bright": dark ? 0.0 : 0.05, "opacity": 0.65],
                ["blur": 6 * i, "sat": 1.25, "bright": 0.08, "opacity": 0.4],
                ["blur": 1.5, "sat": 1.05, "bright": 0.12, "opacity": 0.22]
            ]
        default: // frosted
            return [
                ["blur": 16 * i, "sat": 0.95 + 0.2 * i, "bright": dark ? -0.02 : 0.03, "opacity": 0.75],
                ["blur": 3, "sat": 1.0, "bright": 0, "opacity": 0.3]
            ]
        }
    }

    @objc public func recommendedBlurStyle(style: String, dark: Bool, lightweight: Bool) -> Int {
        // Maps to UIBlurEffect.Style raw-ish categories for logging
        if lightweight { return 5 } // ultra thin
        switch style.lowercased() {
        case "clear": return 5
        case "tinted": return 2
        case "liquid": return 1
        default: return 1
        }
    }

    @objc public func evaluateQuality() -> [String: Any] {
        [
            "pipeline": "v4-liquid",
            "passes_clear": passes(forStyle: "clear", intensity: 0.6, dark: true).count,
            "passes_liquid": passes(forStyle: "liquid", intensity: 0.8, dark: true).count,
            "private_glass": GlassPrivateBridge.hasUIGlassEffect,
            "private_backdrop": GlassPrivateBridge.hasBackdropView,
            "ci_software": false
        ]
    }
}
