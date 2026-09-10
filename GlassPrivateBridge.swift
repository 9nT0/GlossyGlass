import UIKit
import ObjectiveC

/// Swift façade over GlassPrivateAPI.m runtime private primitives.
@objc public final class GlassPrivateBridge: NSObject {

    @objc public static var hasUIGlassEffect: Bool {
        GGPrivate_HasUIGlassEffect()
    }

    @objc public static var hasBackdropView: Bool {
        GGPrivate_HasBackdropView()
    }

    @objc public static func capabilityReport() -> String {
        guard let cstr = GGPrivate_CapabilityReport() else { return "unavailable" }
        return cstr as String
    }

    @objc public static func makeGlassEffect(clear: Bool) -> UIVisualEffect? {
        GGPrivate_MakeGlassEffect(clear)
    }

    @objc public static func systemChromeMaterial(dark: Bool, ultraThin: Bool) -> UIVisualEffect {
        GGPrivate_SystemChromeMaterial(dark, ultraThin) ?? UIBlurEffect(style: dark ? .systemThinMaterialDark : .systemThinMaterialLight)
    }

    @objc public static func makeBackdrop(frame: CGRect, dark: Bool, blur: Float, saturation: Float) -> UIView? {
        GGPrivate_MakeBackdropView(frame, dark, blur, saturation)
    }

    @objc public static func applyLayerFilters(_ layer: CALayer, blur: Float, saturate: Float, brightness: Float) -> Bool {
        GGPrivate_ApplyLayerFilters(layer, blur, saturate, brightness)
    }

    @objc public static func clearLayerFilters(_ layer: CALayer) {
        GGPrivate_ClearLayerFilters(layer)
    }

    @objc public static func setContinuousCorners(_ view: UIView, radius: CGFloat) {
        GGPrivate_SetContinuousCorners(view, radius)
    }
}

// C declarations for Swift
@_silgen_name("GGPrivate_HasUIGlassEffect")
func GGPrivate_HasUIGlassEffect() -> Bool

@_silgen_name("GGPrivate_HasBackdropView")
func GGPrivate_HasBackdropView() -> Bool

@_silgen_name("GGPrivate_MakeGlassEffect")
func GGPrivate_MakeGlassEffect(_ clearStyle: Bool) -> UIVisualEffect?

@_silgen_name("GGPrivate_MakeBackdropView")
func GGPrivate_MakeBackdropView(_ frame: CGRect, _ dark: Bool, _ blurRadius: Float, _ saturation: Float) -> UIView?

@_silgen_name("GGPrivate_ApplyLayerFilters")
func GGPrivate_ApplyLayerFilters(_ layer: CALayer?, _ blur: Float, _ saturate: Float, _ brightness: Float) -> Bool

@_silgen_name("GGPrivate_ClearLayerFilters")
func GGPrivate_ClearLayerFilters(_ layer: CALayer?)

@_silgen_name("GGPrivate_SystemChromeMaterial")
func GGPrivate_SystemChromeMaterial(_ dark: Bool, _ ultraThin: Bool) -> UIVisualEffect?

@_silgen_name("GGPrivate_CapabilityReport")
func GGPrivate_CapabilityReport() -> NSString?

@_silgen_name("GGPrivate_SetContinuousCorners")
func GGPrivate_SetContinuousCorners(_ view: UIView?, _ radius: CGFloat)


@_silgen_name("GGEmbedded_LUTByteCount")
func GGEmbedded_LUTByteCount() -> UInt

@_silgen_name("GGEmbedded_EnsureLUT")
func GGEmbedded_EnsureLUT() -> Bool
