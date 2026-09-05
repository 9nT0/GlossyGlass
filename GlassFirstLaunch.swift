import UIKit

/// Shows a short first-launch guide once
@objc public class GlassFirstLaunch: NSObject {

    private static let key = "GG_HasShownFirstLaunch"

    @objc public static func checkAndShowIfNeeded() {
        let defaults = UserDefaults(suiteName: "com.glossyglass.preferences") ?? .standard
        guard defaults.bool(forKey: key) == false else { return }
        defaults.set(true, forKey: key)

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            presentGuide()
        }
    }

    private static func presentGuide() {
        guard let root = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap({ $0.windows })
            .first(where: { $0.isKeyWindow })?.rootViewController else { return }

        var top = root
        while let presented = top.presentedViewController { top = presented }

        let alert = UIAlertController(
            title: "GlossyGlass",
            message: "Welcome!\n\n• Tap the “Glass” button on profile to open settings\n• Use presets for quick looks\n• Long-press messages for the lift effect\n\nMade by Killswitch",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Got it", style: .default))
        top.present(alert, animated: true)
    }
}
