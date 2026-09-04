import SwiftUI

public struct GlassViewRepresentable: UIViewRepresentable {
    public var cornerRadius: CGFloat = 22
    public var tint: UIColor = UIColor.white.withAlphaComponent(0.12)
    public var gloss: CGFloat = 0.55
    public var interactive: Bool = false

    public func makeUIView(context: Context) -> GlassView {
        let v = GlassView()
        v.cornerRadius = cornerRadius
        v.glassTint = tint
        v.glossIntensity = gloss
        v.isInteractive = interactive
        return v
    }

    public func updateUIView(_ uiView: GlassView, context: Context) {
        uiView.cornerRadius = cornerRadius
        uiView.glassTint = tint
        uiView.glossIntensity = gloss
        uiView.isInteractive = interactive
    }
}

public extension View {
    func glassBackground(
        cornerRadius: CGFloat = 22,
        tint: UIColor = UIColor.white.withAlphaComponent(0.12),
        gloss: CGFloat = 0.55,
        interactive: Bool = false
    ) -> some View {
        background(GlassViewRepresentable(cornerRadius: cornerRadius, tint: tint, gloss: gloss, interactive: interactive))
    }
}

public struct GlassCard<Content: View>: View {
    let content: Content
    public init(@ViewBuilder content: () -> Content) { self.content = content() }
    public var body: some View {
        content.padding().glassBackground(cornerRadius: 24)
    }
}

public struct GlassButtonStyle: ButtonStyle {
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .font(.system(size: 17, weight: .semibold))
            .glassBackground(cornerRadius: 20, gloss: configuration.isPressed ? 0.68 : 0.55)
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.28, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

public extension ButtonStyle where Self == GlassButtonStyle {
    static var glass: GlassButtonStyle { .init() }
}
