import UIKit

/// Hooks for long-press / context menus across Instagram
@objc public final class GlassContextHooks: NSObject {
    @objc public static let shared = GlassContextHooks()
    private var watching = false

    @objc public func start() {
        guard !watching else { return }
        watching = true
        // Observe presented view controllers for context menus / action sheets
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didPresent),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.scanMenus()
        }
    }

    @objc private func didPresent() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.scanMenus() }
    }

    private func scanMenus() {
        guard GlassPreferences.shared.styleContext,
              GlassPreferences.shared.isEnabled,
              !GlassPreferences.shared.safeMode,
              let window = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .flatMap({ $0.windows })
                .first(where: { $0.isKeyWindow }) else { return }

        GlassContextChrome.shared.apply(in: window)
    }
}
