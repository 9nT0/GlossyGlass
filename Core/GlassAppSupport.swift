import UIKit

@objc public final class GlassAppSupport: NSObject {
    @objc public static func allWindows() -> [UIWindow] {
        var result: [UIWindow] = []
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            result.append(contentsOf: ws.windows)
        }
        return result
    }

    @objc public static func keyOrFirstWindow() -> UIWindow? {
        let all = allWindows()
        return all.first(where: { $0.isKeyWindow }) ?? all.first
    }

    @objc public static func topViewController() -> UIViewController? {
        for w in allWindows() {
            var top = w.rootViewController
            while let p = top?.presentedViewController { top = p }
            if top != nil { return top }
        }
        return nil
    }
}
