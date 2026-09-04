import UIKit

/// Clean, light, adaptive TabBar + NavigationBar styling
@objc public class GlassNavigationHelper: NSObject {

    /// Applies a clean translucent style to UITabBar (call once)
    @objc public static func applyTabBarStyle(to tabBar: UITabBar) {
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()

        // Ultra light material – good performance
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        let item = UITabBarItemAppearance()
        item.normal.iconColor = UIColor.label.withAlphaComponent(0.42)
        item.selected.iconColor = .label

        let normalFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        let selectedFont = UIFont.systemFont(ofSize: 10, weight: .semibold)

        item.normal.titleTextAttributes = [
            .foregroundColor: UIColor.label.withAlphaComponent(0.42),
            .font: normalFont
        ]
        item.selected.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: selectedFont
        ]

        appearance.stackedLayoutAppearance = item
        appearance.inlineLayoutAppearance = item
        appearance.compactInlineLayoutAppearance = item

        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance

        // Soft floating shadow (very light)
        tabBar.clipsToBounds = false
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.06
        tabBar.layer.shadowRadius = 16
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -5)
    }

    /// Applies a clean translucent style to UINavigationBar (call once)
    @objc public static func applyNavigationBarStyle(to navigationBar: UINavigationBar) {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()

        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        appearance.backgroundColor = UIColor.clear
        appearance.shadowColor = .clear

        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        appearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]

        navigationBar.standardAppearance = appearance
        navigationBar.scrollEdgeAppearance = appearance
        navigationBar.compactAppearance = appearance
        navigationBar.tintColor = .label
    }
}
