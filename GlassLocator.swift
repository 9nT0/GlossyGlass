import UIKit

/// Multi-strategy view locator used by injector
@objc public class GlassLocator: NSObject {
    @objc public static let shared = GlassLocator()

    @objc public func findBestButtonHost() -> (UIView, Int)? {
        var best: (UIView, Int)?
        for window in GlassAppSupport.allWindows() {
            walk(window, depth: 0, best: &best)
        }
        return best
    }

    private func walk(_ view: UIView, depth: Int, best: inout (UIView, Int)?) {
        if depth > 14 { return }
        if let stack = view as? UIStackView, stack.axis == .horizontal {
            let score = scoreStack(stack)
            if score > 0, score > (best?.1 ?? 0) {
                best = (stack, score)
            }
        }
        for s in view.subviews { walk(s, depth: depth + 1, best: &best) }
    }

    private func scoreStack(_ stack: UIStackView) -> Int {
        let controls = stack.arrangedSubviews.filter {
            $0 is UIControl || $0 is UIButton || ($0.bounds.height > 18 && $0.bounds.height < 56)
        }
        guard controls.count >= 2, controls.count <= 6 else { return 0 }
        var score = 20 + controls.count * 10
        if controls.count == 3 || controls.count == 4 { score += 20 }
        let name = String(describing: type(of: stack)).lowercased()
        if name.contains("profile") || name.contains("action") || name.contains("header") { score += 15 }
        if GlassAppSupport.shared.isInstagram { score += 10 }
        return score
    }

    @objc public func findMessagesControls() -> [UIView] {
        var out: [UIView] = []
        for w in GlassAppSupport.allWindows() {
            collectMessages(in: w, depth: 0, out: &out)
        }
        return out
    }

    private func collectMessages(in view: UIView, depth: Int, out: inout [UIView]) {
        if depth > 16 { return }
        let name = String(describing: type(of: view)).lowercased()
        let lab = (view.accessibilityLabel ?? "").lowercased()
        let hit = name.contains("direct") || name.contains("message") || name.contains("inbox")
            || lab.contains("message") || lab.contains("direct") || lab.contains("inbox")
        if hit && (view is UIControl || view.isUserInteractionEnabled) {
            out.append(view)
        }
        for s in view.subviews { collectMessages(in: s, depth: depth + 1, out: &out) }
    }
}
