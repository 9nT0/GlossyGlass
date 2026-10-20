import UIKit

@objc public final class IGLocator: NSObject {
    @objc public static let shared = IGLocator()

    private let tabNames = [
        "igtabbar", "igmaintabbar", "igtabbarcontroller", "ighometabbar",
        "igbottomtab", "tabbar", "igmainfeedtabbar", "igtabbarbutton",
        "igdock", "igbottombar", "ignavigationtab"
    ]
    private let navNames = [
        "ignavigationbar", "ignavbar", "igmainnavigationbar", "navigationbar",
        "ignav", "igheaderbar", "igtopbar"
    ]
    private let composerNames = [
        "composer", "input", "messagebar", "chatbar", "textbox",
        "igdirectcomposer", "igdirectthreadcomposer", "igcomposer",
        "igmessageinput", "igdirectinput", "replybar"
    ]
    private let callNames = [
        "call", "video", "phone", "audiocall", "videocall", "igdirectthreadcall"
    ]
    private let contentBlocklist = [
        "collectionview", "tableview", "scrollview", "cell", "messagecell",
        "feeditem", "mediaview", "player", "webview",
        "igdirectthreadview", "igdirectthreadcell", "igfeed", "storyviewer"
    ]

    @objc public func findTabBar(in root: UIView) -> UIView? {
        if let bar = find(of: UITabBar.self, in: root) { return bar }
        for n in tabNames {
            if let v = find(classContains: n, in: root), !isContent(v) { return v }
        }
        return findBottomChrome(in: root)
    }

    @objc public func findNavigationBar(in root: UIView) -> UIView? {
        if let bar = find(of: UINavigationBar.self, in: root) { return bar }
        for n in navNames {
            if let v = find(classContains: n, in: root), !isContent(v) { return v }
        }
        return findTopChrome(in: root)
    }

    @objc public func findButtonContainers(in root: UIView) -> [UIView] {
        var r: [UIView] = []
        walk(root) { v in
            guard !isContent(v) else { return }
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("button") || n.contains("action") || n.contains("toolbar") || n.contains("barbutton") {
                r.append(v)
            }
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

    @objc public func findComposers(in root: UIView) -> [UIView] {
        var r: [UIView] = []
        for n in composerNames { r += findViews(classContains: n, in: root) }
        walk(root) { v in
            let f = v.convert(v.bounds, to: nil)
            guard f.height > 36, f.height < 100 else { return }
            guard f.maxY > UIScreen.main.bounds.height - 160 else { return }
            guard f.width > UIScreen.main.bounds.width * 0.5 else { return }
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("input") || n.contains("composer") || n.contains("bar") || n.contains("toolbar") {
                r.append(v)
            }
        }
        return r.filter { !isContent($0) }
    }

    @objc public func findCallButtons(in root: UIView) -> [UIView] {
        var r: [UIView] = []
        for n in callNames {
            for v in findViews(classContains: n, in: root) {
                let name = NSStringFromClass(type(of: v)).lowercased()
                if v is UIControl || name.contains("button") {
                    let s = min(v.bounds.width, v.bounds.height)
                    if s > 24 && s < 72 { r.append(v) }
                }
            }
        }
        if let nav = findNavigationBar(in: root) {
            for sub in nav.subviews {
                let s = min(sub.bounds.width, sub.bounds.height)
                if (sub is UIControl || sub is UIButton) && s > 28 && s < 56 { r.append(sub) }
            }
        }
        return r
    }

    @objc public func isContent(_ v: UIView) -> Bool {
        if v is UICollectionView || v is UITableView { return true }
        if v is UICollectionViewCell || v is UITableViewCell { return true }
        let n = NSStringFromClass(type(of: v)).lowercased()
        for b in contentBlocklist where n.contains(b) { return true }
        let f = v.convert(v.bounds, to: nil)
        if f.height > UIScreen.main.bounds.height * 0.45 && f.width > UIScreen.main.bounds.width * 0.8 {
            if n.contains("view") && !n.contains("bar") && !n.contains("nav") && !n.contains("tab") {
                return true
            }
        }
        return false
    }

    private func findBottomChrome(in root: UIView) -> UIView? {
        var best: UIView?; var score: CGFloat = 0
        walk(root) { v in
            guard !isContent(v) else { return }
            let f = v.convert(v.bounds, to: nil)
            guard f.height > 40, f.height < 110 else { return }
            guard f.maxY > UIScreen.main.bounds.height - 140 else { return }
            guard f.width > UIScreen.main.bounds.width * 0.7 else { return }
            let s = f.width / max(f.height, 1) + (f.maxY / UIScreen.main.bounds.height) * 2
            if s > score { score = s; best = v }
        }
        return best
    }

    private func findTopChrome(in root: UIView) -> UIView? {
        var best: UIView?; var score: CGFloat = 0
        walk(root) { v in
            guard !isContent(v) else { return }
            let f = v.convert(v.bounds, to: nil)
            guard f.height > 36, f.height < 120 else { return }
            guard f.minY < 120 else { return }
            guard f.width > UIScreen.main.bounds.width * 0.6 else { return }
            let s = f.width / max(f.height, 1)
            if s > score { score = s; best = v }
        }
        return best
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
    private func walk(_ v: UIView, depth: Int = 0, max: Int = 16, block: (UIView) -> Void) {
        guard depth < max else { return }
        block(v)
        for s in v.subviews { walk(s, depth: depth + 1, max: max, block: block) }
    }
}
