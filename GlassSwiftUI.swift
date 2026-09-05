import SwiftUI

public struct GlassViewRepresentable: UIViewRepresentable {
    public var cornerRadius: CGFloat = 22
    public var gloss: CGFloat = 0.55
    public var interactive: Bool = false
    public var customTint: UIColor? = nil

    public func makeUIView(context: Context) -> GlassView {
        let v = GlassView()
        v.cornerRadius = cornerRadius
        v.glossIntensity = gloss
        v.isInteractive = interactive
        v.customTint = customTint
        return v
    }

    public func updateUIView(_ uiView: GlassView, context: Context) {
        uiView.cornerRadius = cornerRadius
        uiView.glossIntensity = gloss
        uiView.isInteractive = interactive
        uiView.customTint = customTint
    }
}

public extension View {
    func glassBackground(
        cornerRadius: CGFloat = 22,
        gloss: CGFloat = 0.55,
        interactive: Bool = false,
        customTint: UIColor? = nil
    ) -> some View {
        let prefs = GlassPreferences.shared
        guard prefs.isEnabled && prefs.styleCards else {
            return AnyView(self)
        }
        return AnyView(
            background(
                GlassViewRepresentable(
                    cornerRadius: cornerRadius,
                    gloss: gloss,
                    interactive: interactive,
                    customTint: customTint
                )
            )
        )
    }
}

public struct GlassCard<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    public var body: some View {
        content
            .padding()
            .glassBackground(cornerRadius: 24)
    }
}

public struct GlassButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        let prefs = GlassPreferences.shared
        let enabled = prefs.isEnabled && prefs.styleButtons

        return configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .font(.system(size: 17, weight: .semibold))
            .background(
                Group {
                    if enabled {
                        GlassViewRepresentable(
                            cornerRadius: 20,
                            gloss: configuration.isPressed ? 0.65 : 0.55
                        )
                    } else {
                        Color.clear
                    }
                }
            )
            .scaleEffect(configuration.isPressed && enabled ? 0.965 : 1)
            .animation(.spring(response: prefs.springResponse, dampingFraction: prefs.springDamping), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { .init() }
}
