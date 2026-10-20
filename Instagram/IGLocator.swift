import UIKit

@objc public final class IGLocator: NSObject {
    @objc public static let shared = IGLocator()

    @objc public func findTabBar(in root: UIView) -> UIView? {
        if let b = find(of: UITabBar.self, in: root) { return b }
        for n in ["igtabbar", "igmaintabbar", "igtabbarcontroller", "ighometabbar", "igbottomtab", "tabbar"] {
            if let v = find(classContains: n, in: root) { return v }
        }
        return findBottom(in: root)
    }

    @objc public func findNavigationBar(in root: UIView) -> UIView? {
        if let b = find(of: UINavigationBar.self, in: root) { return b }
        for n in ["ignavigationbar", "ignavbar", "igmainnavigationbar", "navigationbar"] {
            if let v = find(classContains: n, in: root) { return v }
        }
        return nil
    }

    @objc public func findButtonContainers(in root: UIView) -> [UIView] {
        var r: [UIView] = []
        walk(root) { v in
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("button") || n.contains("action") || n.contains("toolbar") || n.contains("barbutton") { r.append(v) }
        }
        return r
    }

    @objc public func findViews(classContains: String, in root: UIView) -> [UIView] {
        var r: [UIView] = []
        let t = classContains.lowercased()
        walk(root) { v in
            if NSStringFromClass(type(of: v)).lowercased().contains(t) { r.append(v) }
        }
        return r
    }

    private func find<T: UIView>(of type: T.Type, in root: UIView) -> T? {
        if let m = root as? T { return m }
        for s in root.subviews { if let f = find(of: type, in: s) { return f } }
        return nil
    }
    private func find(classContains: String, in root: UIView) -> UIView? {
        let t = classContains.lowercased()
        if NSStringFromClass(type(of: root)).lowercased().contains(t) { return root }
        for s in root.subviews { if let f = find(classContains: classContains, in: s) { return f } }
        return nil
    }
    private func findBottom(in root: UIView) -> UIView? {
        var best: UIView?; var score: CGFloat = 0
        walk(root) { v in
            let f = v.convert(v.bounds, to: nil)
            guard f.height > 40, f.height < 100, f.maxY > UIScreen.main.bounds.height - 140 else { return }
            let s = f.width / max(f.height, 1)
            if s > score { score = s; best = v }
        }
        return best
    }
    private func walk(_ v: UIView, depth: Int = 0, max: Int = 14, block: (UIView) -> Void) {
        guard depth < max else { return }
        block(v)
        for s in v.subviews { walk(s, depth: depth + 1, max: max, block: block) }
    }
}
