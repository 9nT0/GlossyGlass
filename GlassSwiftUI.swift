import SwiftUI

public struct GlassViewRepresentable: UIViewRepresentable {
    public var cornerRadius: CGFloat = 22
    public var gloss: CGFloat = 0.50
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
        gloss: CGFloat = 0.50,
        interactive: Bool = false,
        customTint: UIColor? = nil
    ) -> some View {
        background(
            GlassViewRepresentable(
                cornerRadius: cornerRadius,
                gloss: gloss,
                interactive: interactive,
                customTint: customTint
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
        configuration.label
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .font(.system(size: 17, weight: .semibold))
            .glassBackground(
                cornerRadius: 20,
                gloss: configuration.isPressed ? 0.62 : 0.50
            )
            .scaleEffect(configuration.isPressed ? 0.965 : 1)
            .animation(.spring(response: 0.26, dampingFraction: 0.72), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { .init() }
}
