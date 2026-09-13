import UIKit

@objc public enum GlassSurfaceKind: Int {
    case feed = 0
    case profile = 1
    case reels = 2
    case messages = 3
    case explore = 4
    case story = 5
    case unknown = 6

    public var key: String {
        switch self {
        case .feed: return "feed"
        case .profile: return "profile"
        case .reels: return "reels"
        case .messages: return "messages"
        case .explore: return "explore"
        case .story: return "story"
        case .unknown: return "unknown"
        }
    }
}

public struct GlassSurfaceRecipe {
    public var style: String
    public var intensity: CGFloat
    public var opacity: CGFloat
    public var saturation: CGFloat
    public var dimming: CGFloat

    public func blurEffect(dark: Bool) -> UIBlurEffect {
        // Distinct materials per style — iOS 16–18 system only
        switch style.lowercased() {
        case "clear":
            return UIBlurEffect(style: dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
        case "tinted":
            return UIBlurEffect(style: dark ? .systemMaterialDark : .systemMaterialLight)
        case "liquid", "heavy":
            return UIBlurEffect(style: dark ? .systemThinMaterialDark : .systemThinMaterialLight)
        case "frosted":
            return UIBlurEffect(style: dark ? .systemChromeMaterialDark : .systemChromeMaterialLight)
        default:
            if intensity < 0.4 {
                return UIBlurEffect(style: dark ? .systemUltraThinMaterialDark : .systemUltraThinMaterialLight)
            }
            return UIBlurEffect(style: dark ? .systemThinMaterialDark : .systemThinMaterialLight)
        }
    }
}

@objc public final class GlassSurfaceRouter: NSObject {

    @objc public static let shared = GlassSurfaceRouter()
    @objc public private(set) var activeSurface: GlassSurfaceKind = .unknown
    @objc public var activeSurfaceName: String { activeSurface.key }

    @objc public func refresh() {
        activeSurface = detect()
    }

    public func recipe(for surface: GlassSurfaceKind, role: GlassChromeRole) -> GlassSurfaceRecipe {
        let p = GlassPreferences.shared
        var style = p.style
        var intensity = p.intensity
        var opacity = p.opacity
        var sat = p.saturation
        var dim = p.dimming

        // Obviously different per surface (on top of global prefs)
        switch surface {
        case .feed:
            style = p.style
            intensity = max(intensity, 0.55)
            opacity = max(opacity, 0.88)
        case .profile:
            style = (p.style.lowercased() == "clear") ? "frosted" : p.style
            intensity = min(1, intensity + 0.12)
            opacity = max(opacity, 0.90)
            sat = min(1, sat + 0.1)
        case .reels:
            style = "clear"
            intensity = min(intensity, 0.45)
            opacity = min(opacity, 0.70)
            dim = max(0, dim * 0.4)
        case .messages:
            style = (p.style.lowercased() == "clear") ? "frosted" : "liquid"
            intensity = max(intensity, 0.65)
            opacity = max(opacity, 0.92)
        case .explore:
            intensity = max(0.5, intensity * 0.9)
            opacity = max(0.85, opacity)
        case .story:
            style = "clear"
            intensity = min(0.4, intensity)
            opacity = min(0.55, opacity)
        case .unknown:
            break
        }

        if role == .tab {
            opacity = max(opacity, 0.85)
            intensity = max(intensity, 0.5)
        }
        if role == .nav || role == .header {
            opacity = max(opacity, 0.8)
        }

        return GlassSurfaceRecipe(
            style: style,
            intensity: intensity,
            opacity: opacity,
            saturation: sat,
            dimming: dim
        )
    }

    private func detect() -> GlassSurfaceKind {
        // 1) Top VC / chain names (safe — no KVC)
        if let top = GlassAppSupport.topViewController() {
            let names = vcChainNames(top) + [NSStringFromClass(type(of: top))]
            let blob = names.joined(separator: " ").lowercased()

            if blob.contains("direct") || blob.contains("inbox") || blob.contains("thread")
                || blob.contains("message") || blob.contains("igdirect") {
                return .messages
            }
            if blob.contains("reel") || blob.contains("clips") || blob.contains("sundial")
                || blob.contains("igvideo") {
                return .reels
            }
            if blob.contains("profile") || blob.contains("userdetail") || blob.contains("selfprofile")
                || blob.contains("igprofile") {
                return .profile
            }
            if blob.contains("explore") || blob.contains("search") || blob.contains("discover") {
                return .explore
            }
            if blob.contains("story") || blob.contains("stories") {
                return .story
            }
            if blob.contains("feed") || blob.contains("home") || blob.contains("mainfeed")
                || blob.contains("ighome") {
                return .feed
            }
            if let tab = top.tabBarController ?? (top as? UITabBarController) {
                return mapTabIndex(tab.selectedIndex)
            }
        }

        // 2) Only real UITabBarController instances in hierarchy (no KVC)
        for w in GlassAppSupport.allWindows() {
            if let kind = detectFromTabIn(w) { return kind }
        }
        return .unknown
    }

    private func detectFromTabIn(_ view: UIView) -> GlassSurfaceKind? {
        // Only real UITabBarController — never KVC selectedIndex on random IG views
        // (IGTabBarControllerSwipeCollectionView crashes on value(forKey: "selectedIndex"))
        if let tab = view as? UITabBarController {
            return mapTabIndex(tab.selectedIndex)
        }
        if let bar = view as? UITabBar, let vc = bar.delegate as? UITabBarController {
            return mapTabIndex(vc.selectedIndex)
        }
        // Safe limited walk — skip collection views / scroll views
        if view is UICollectionView || view is UIScrollView || view is UITableView {
            return nil
        }
        let name = NSStringFromClass(type(of: view))
        if name.contains("Swipe") || name.contains("Collection") || name.contains("Scroll") {
            return nil
        }
        for s in view.subviews {
            if let k = detectFromTabIn(s) { return k }
        }
        return nil
    }

    private func mapTabIndex(_ index: Int) -> GlassSurfaceKind {
        // Common IG layout: 0 home, 1 search/explore, 2 create, 3 reels, 4 profile
        switch index {
        case 0: return .feed
        case 1: return .explore
        case 2: return .reels
        case 3: return .reels
        case 4: return .profile
        default: return .unknown
        }
    }


    private func vcChainNames(_ vc: UIViewController) -> [String] {
        var out = [NSStringFromClass(type(of: vc))]
        for c in vc.children { out.append(contentsOf: vcChainNames(c)) }
        if let p = vc.presentedViewController { out.append(contentsOf: vcChainNames(p)) }
        return out
    }
}
