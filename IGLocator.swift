//
//  IGLocator.swift
//  GlossyGlass v5
//
//  Finds the real Instagram chrome (tab bar, nav bar, etc.)
//  Multi-strategy so it works across Instagram versions and Live Container.
//

import UIKit

@objc public final class IGLocator: NSObject {

    @objc public static let shared = IGLocator()

    // MARK: - Tab Bar

    @objc public func findTabBar(in root: UIView) -> UIView? {
        // 1. Real UITabBar
        if let bar = findView(ofClass: UITabBar.self, in: root) {
            return bar
        }

        // 2. Instagram private classes (common names)
        let candidates = [
            "IGTabBar",
            "IGMainTabBar",
            "IGTabBarController",
            "IGHomeTabBar"
        ]

        for name in candidates {
            if let view = findView(classNameContains: name, in: root) {
                return view
            }
        }

        // 3. Heuristic: bottom bar-like view
        return findBottomChrome(in: root)
    }

    // MARK: - Navigation Bar

    @objc public func findNavigationBar(in root: UIView) -> UIView? {
        if let bar = findView(ofClass: UINavigationBar.self, in: root) {
            return bar
        }

        let candidates = [
            "IGNavigationBar",
            "IGNavBar",
            "IGMainNavigationBar"
        ]

        for name in candidates {
            if let view = findView(classNameContains: name, in: root) {
                return view
            }
        }

        return nil
    }

    // MARK: - Button containers

    @objc public func findButtonContainers(in root: UIView) -> [UIView] {
        var results: [UIView] = []
        walk(root) { view in
            let name = NSStringFromClass(type(of: view)).lowercased()
            if name.contains("button") || name.contains("action") || name.contains("toolbar") {
                results.append(view)
            }
        }
        return results
    }

    // MARK: - Private helpers

    private func findView<T: UIView>(ofClass: T.Type, in root: UIView) -> T? {
        if let match = root as? T { return match }
        for sub in root.subviews {
            if let found = findView(ofClass: ofClass, in: sub) {
                return found
            }
        }
        return nil
    }

    private func findView(classNameContains: String, in root: UIView) -> UIView? {
        let target = classNameContains.lowercased()
        if NSStringFromClass(type(of: root)).lowercased().contains(target) {
            return root
        }
        for sub in root.subviews {
            if let found = findView(classNameContains: classNameContains, in: sub) {
                return found
            }
        }
        return nil
    }

    private func findBottomChrome(in root: UIView) -> UIView? {
        var best: UIView?
        var bestScore: CGFloat = 0

        walk(root) { view in
            let frame = view.convert(view.bounds, to: nil)
            guard frame.height > 40 && frame.height < 90 else { return }
            guard frame.maxY > UIScreen.main.bounds.height - 120 else { return }

            let score = frame.width * (1.0 / max(frame.height, 1))
            if score > bestScore {
                bestScore = score
                best = view
            }
        }
        return best
    }

    private func walk(_ view: UIView, depth: Int = 0, maxDepth: Int = 12, block: (UIView) -> Void) {
        guard depth < maxDepth else { return }
        block(view)
        for sub in view.subviews {
            walk(sub, depth: depth + 1, maxDepth: maxDepth, block: block)
        }
    }
}
