import UIKit

/// Search bar + explore / notifications surfaces
@objc public final class GlassSearchChrome: NSObject {
    @objc public static let shared = GlassSearchChrome()

    @objc public func apply(in window: UIView) {
        let p = GlassPreferences.shared
        guard p.styleSearch else { return }

        let search = IGLocator.shared.findViews(classContains: "search", in: window)
            + IGLocator.shared.findViews(classContains: "explore", in: window)

        for v in search {
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("bar") || n.contains("field") || n.contains("input") || n.contains("header") {
                if v.bounds.height > 32 && v.bounds.height < 80 {
                    GlassMaterial.shared.apply(to: v, style: .soft, corner: 14)
                }
            }
        }

        let notif = IGLocator.shared.findViews(classContains: "notif", in: window)
            + IGLocator.shared.findViews(classContains: "activity", in: window)
            + IGLocator.shared.findViews(classContains: "news", in: window)

        for v in notif where v.bounds.height > 36 && v.bounds.height < 100 {
            let n = NSStringFromClass(type(of: v)).lowercased()
            if n.contains("header") || n.contains("bar") || n.contains("toolbar") {
                GlassMaterial.shared.apply(to: v, style: .standard, corner: 0)
            }
        }
    }
}
