import UIKit

/// Multi-strategy chrome host finder for IG 433 + LiveContainer.
@objc public final class GlassLocator: NSObject {

    @objc public static let shared = GlassLocator()

    public struct HostHit {
        public let view: UIView
        public let score: Int
        public let kind: String
    }

    public func findBestButtonHost() -> (view: UIView, score: Int)? {
        let hits = scanButtonHosts()
        guard let best = hits.max(by: { $0.score < $1.score }), best.score >= 16 else { return nil }
        return (best.view, best.score)
    }

    @objc public func chromeCandidateCount() -> Int { scanChromeHosts().count }

    @objc public func chromeCandidatesSummary() -> String {
        let hits = scanChromeHosts()
        if hits.isEmpty { return "none" }
        return hits.prefix(10).map { "\($0.kind):\($0.score)" }.joined(separator: ",")
    }

    public func scanChromeHosts() -> [HostHit] {
        var hits: [HostHit] = []
        var seen = Set<ObjectIdentifier>()
        for w in GlassAppSupport.allWindows() {
            collect(w, depth: 0, hits: &hits, seen: &seen)
        }
        // Deduplicate by kind preference
        return hits.sorted { $0.score > $1.score }
    }

    public func scanButtonHosts() -> [HostHit] {
        var hits: [HostHit] = []
        for w in GlassAppSupport.allWindows() {
            collectButton(w, depth: 0, hits: &hits)
        }
        return hits
    }

    private func collect(_ view: UIView, depth: Int, hits: inout [HostHit], seen: inout Set<ObjectIdentifier>) {
        guard depth < 22 else { return }
        let oid = ObjectIdentifier(view)
        guard !seen.contains(oid) else { return }

        // Strategy A: UIKit bars
        if view is UINavigationBar {
            seen.insert(oid)
            hits.append(HostHit(view: view, score: 95, kind: "UINavigationBar"))
        }
        if view is UITabBar {
            seen.insert(oid)
            hits.append(HostHit(view: view, score: 100, kind: "UITabBar"))
        }

        let name = NSStringFromClass(type(of: view))
        let lower = name.lowercased()
        // Skip inner chrome content / non-hosts
        if lower.contains("contentview") || lower.contains("buttonbar")
            || lower.contains("stackview") || lower.contains("layoutguide")
            || lower.contains("visualeffect") || lower.contains("transitionview") {
            for s in view.subviews { collect(s, depth: depth + 1, hits: &hits, seen: &seen) }
            return
        }
        let frame = view.convert(view.bounds, to: nil)
        guard let win = view.window else {
            for s in view.subviews { collect(s, depth: depth + 1, hits: &hits, seen: &seen) }
            return
        }

        let w = frame.width
        let h = frame.height
        let barW = w > win.bounds.width * 0.50
        let barH = h > 34 && h < 110

        // Strategy B: class name dictionary (IG 433 / Meta)
        let tabNames = [
            "igtabbar", "igtabbarcontroller", "igdstabbar", "igcustomtabbar",
            "igmaintab", "ighometab", "tabbar", "tabcontroller", "bottomtab"
        ]
        let navNames = [
            "ignavigationbar", "ignavbar", "navigationbar", "navbar",
            "igheader", "headerbar", "igmainheader", "igfeedheader"
        ]
        if barW && barH {
            if tabNames.contains(where: { lower.contains($0) }) {
                seen.insert(oid)
                hits.append(HostHit(view: view, score: 88, kind: "NameTab:\(name)"))
            }
            if navNames.contains(where: { lower.contains($0) }) {
                seen.insert(oid)
                hits.append(HostHit(view: view, score: 82, kind: "NameNav:\(name)"))
            }
        }

        // Strategy C: geometry bottom dock with 3–6 controls
        let bottom = frame.maxY > win.bounds.height - 120 && frame.minY > win.bounds.height - 160
        if bottom && barW && barH {
            let controls = countControls(view)
            if controls >= 3 && controls <= 8 {
                seen.insert(oid)
                hits.append(HostHit(view: view, score: 50 + controls * 6, kind: "GeoBottom x\(controls)"))
            }
        }

        // Strategy D: geometry top header strip
        let top = frame.minY < 100 && frame.maxY < 180
        if top && barW && h > 40 && h < 100 {
            if lower.contains("header") || lower.contains("nav") || countControls(view) >= 2 {
                seen.insert(oid)
                hits.append(HostHit(view: view, score: 58, kind: "GeoTop"))
            }
        }

        // Strategy E: accessibility / identifier
        let ax = (view.accessibilityIdentifier ?? "").lowercased()
        let al = (view.accessibilityLabel ?? "").lowercased()
        if barW && barH {
            if ax.contains("tab") || al.contains("tab bar") || al.contains("tabbar") {
                seen.insert(oid)
                hits.append(HostHit(view: view, score: 75, kind: "AXTab"))
            }
        }

        // Strategy F: parent chain — child of tab controller host
        if let parent = view.superview {
            let pn = NSStringFromClass(type(of: parent)).lowercased()
            if pn.contains("tabbar") && barH && barW {
                seen.insert(oid)
                hits.append(HostHit(view: view, score: 72, kind: "ParentTab"))
            }
        }

        for s in view.subviews {
            collect(s, depth: depth + 1, hits: &hits, seen: &seen)
        }
    }

    private func countControls(_ view: UIView) -> Int {
        var n = 0
        for s in view.subviews {
            if s is UIControl || s is UIButton { n += 1 }
            let sn = NSStringFromClass(type(of: s)).lowercased()
            if sn.contains("button") || sn.contains("tabitem") { n += 1 }
        }
        return n
    }

    private func collectButton(_ view: UIView, depth: Int, hits: inout [HostHit]) {
        guard depth < 16 else { return }
        if let stack = view as? UIStackView, stack.axis == .horizontal {
            let controls = stack.arrangedSubviews.filter { $0 is UIButton || $0 is UIControl }.count
            if controls >= 2 && controls <= 6 {
                var score = 20 + controls * 8
                let parent = view.superview.map { NSStringFromClass(type(of: $0)) } ?? ""
                if parent.contains("Profile") || parent.contains("Action") { score += 25 }
                hits.append(HostHit(view: stack, score: score, kind: "Stack"))
            }
        }
        for s in view.subviews { collectButton(s, depth: depth + 1, hits: &hits) }
    }
}
