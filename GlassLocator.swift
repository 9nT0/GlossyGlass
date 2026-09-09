import UIKit

@objc public class GlassLocator: NSObject {
    @objc public static let shared = GlassLocator()

    public func findBestButtonHost() -> (view: UIView, score: Int)? {
        var bestView: UIView?
        var bestScore = 0
        for window in GlassAppSupport.allWindows() {
            walk(window, depth: 0, bestView: &bestView, bestScore: &bestScore)
        }
        guard let v = bestView, bestScore > 0 else { return nil }
        return (v, bestScore)
    }

    @objc public func findBestHostView() -> UIView? {
        return findBestButtonHost()?.view
    }

    @objc public func findBestHostScore() -> Int {
        return findBestButtonHost()?.score ?? 0
    }

    private func walk(_ view: UIView, depth: Int, bestView: inout UIView?, bestScore: inout Int) {
        if depth > 14 { return }
        if let label = view as? UILabel {
            let t = (label.text ?? "").lowercased()
            if t.contains("instagram") { return }
        }
        if let stack = view as? UIStackView, stack.axis == .horizontal {
            let score = scoreStack(stack)
            if score > bestScore {
                bestScore = score
                bestView = stack
            }
        }
        for s in view.subviews {
            walk(s, depth: depth + 1, bestView: &bestView, bestScore: &bestScore)
        }
    }

    private func scoreStack(_ stack: UIStackView) -> Int {
        let controls = stack.arrangedSubviews.filter {
            $0 is UIControl || $0 is UIButton || ($0.bounds.height > 18 && $0.bounds.height < 56)
        }
        guard controls.count >= 2, controls.count <= 6 else { return 0 }
        if stack.bounds.height > 72 { return 0 }
        var score = 20 + controls.count * 10
        if controls.count == 3 || controls.count == 4 { score += 20 }
        let name = String(describing: type(of: stack)).lowercased()
        if name.contains("profile") || name.contains("action") || name.contains("header") { score += 15 }
        if name.contains("story") || name.contains("logo") || name.contains("brand") { score -= 40 }
        if stack.bounds.height > 18 && stack.bounds.height < 48 { score += 12 }
        if GlassAppSupport.shared.isInstagram { score += 10 }
        return max(0, score)
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
