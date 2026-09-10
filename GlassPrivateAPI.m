#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <QuartzCore/QuartzCore.h>
#import <dlfcn.h>

/// Private UIKit / CoreAnimation glass primitives — resolved only at runtime.
/// Never linked against private frameworks by name at build time.

#pragma mark - Helpers

static Class GG_Cls(const char *name) {
    return NSClassFromString([NSString stringWithUTF8String:name]);
}

static SEL GG_Sel(const char *name) {
    return sel_registerName(name);
}

static id GG_Call0(id obj, const char *selName) {
    SEL s = GG_Sel(selName);
    if (!obj || ![obj respondsToSelector:s]) return nil;
    return ((id (*)(id, SEL))objc_msgSend)(obj, s);
}

static id GG_Call1(id obj, const char *selName, id a) {
    SEL s = GG_Sel(selName);
    if (!obj || ![obj respondsToSelector:s]) return nil;
    return ((id (*)(id, SEL, id))objc_msgSend)(obj, s, a);
}

static void GG_Call1v(id obj, const char *selName, id a) {
    SEL s = GG_Sel(selName);
    if (!obj || ![obj respondsToSelector:s]) return;
    ((void (*)(id, SEL, id))objc_msgSend)(obj, s, a);
}

static void GG_CallFloat(id obj, const char *selName, float v) {
    SEL s = GG_Sel(selName);
    if (!obj || ![obj respondsToSelector:s]) return;
    ((void (*)(id, SEL, float))objc_msgSend)(obj, s, v);
}

static void GG_CallBool(id obj, const char *selName, BOOL v) {
    SEL s = GG_Sel(selName);
    if (!obj || ![obj respondsToSelector:s]) return;
    ((void (*)(id, SEL, BOOL))objc_msgSend)(obj, s, v);
}

#pragma mark - Public C API (Swift-callable via @_silgen_name / bridging)

/// Returns YES if UIGlassEffect (iOS 26+) exists.
BOOL GGPrivate_HasUIGlassEffect(void) {
    return GG_Cls("UIGlassEffect") != Nil;
}

/// Returns YES if _UIBackdropView is available.
BOOL GGPrivate_HasBackdropView(void) {
    return GG_Cls("_UIBackdropView") != Nil || GG_Cls("UIBackdropView") != Nil;
}

/// Create a UIVisualEffect from UIGlassEffect when present.
UIVisualEffect *GGPrivate_MakeGlassEffect(BOOL clearStyle) {
    Class c = GG_Cls("UIGlassEffect");
    if (!c) return nil;

    if (clearStyle) {
        SEL clearSel = GG_Sel("clearEffect");
        if ([c respondsToSelector:clearSel]) {
            id e = ((id (*)(Class, SEL))objc_msgSend)(c, clearSel);
            if ([e isKindOfClass:[UIVisualEffect class]]) return (UIVisualEffect *)e;
        }
        SEL regular = GG_Sel("regularEffect");
        if ([c respondsToSelector:regular]) {
            id e = ((id (*)(Class, SEL))objc_msgSend)(c, regular);
            if ([e isKindOfClass:[UIVisualEffect class]]) return (UIVisualEffect *)e;
        }
    }

    // effectWithStyle: if available (enum as NSInteger)
    SEL styled = GG_Sel("effectWithStyle:");
    if ([c respondsToSelector:styled]) {
        id e = ((id (*)(Class, SEL, NSInteger))objc_msgSend)(c, styled, clearStyle ? 1 : 0);
        if ([e isKindOfClass:[UIVisualEffect class]]) return (UIVisualEffect *)e;
    }

    id e = [[c alloc] init];
    if ([e isKindOfClass:[UIVisualEffect class]]) return (UIVisualEffect *)e;
    return nil;
}

/// Create _UIBackdropView with private style settings when available.
UIView *GGPrivate_MakeBackdropView(CGRect frame, BOOL dark, float blurRadius, float saturation) {
    Class c = GG_Cls("_UIBackdropView");
    if (!c) c = GG_Cls("UIBackdropView");
    if (!c) return nil;

    UIView *view = nil;
    SEL initFrame = GG_Sel("initWithFrame:autosizesToFitSuperview:settings:");
    SEL initSimple = GG_Sel("initWithFrame:");

    // Try settings object
    Class settingsCls = GG_Cls("_UIBackdropViewSettings");
    if (!settingsCls) settingsCls = GG_Cls("UIBackdropViewSettings");

    id settings = nil;
    if (settingsCls) {
        SEL settingsSel = dark ? GG_Sel("darkSettings") : GG_Sel("lightSettings");
        if (![settingsCls respondsToSelector:settingsSel]) {
            settingsSel = GG_Sel("settingsForPrivateStyle:");
            if ([settingsCls respondsToSelector:settingsSel]) {
                settings = ((id (*)(Class, SEL, NSInteger))objc_msgSend)(settingsCls, settingsSel, dark ? 2020 : 2010);
            }
        } else {
            settings = ((id (*)(Class, SEL))objc_msgSend)(settingsCls, settingsSel);
        }
        if (!settings) {
            settings = [[settingsCls alloc] init];
        }
        if (settings) {
            GG_CallFloat(settings, "setBlurRadius:", blurRadius);
            GG_CallFloat(settings, "setSaturationDeltaFactor:", saturation);
            GG_CallBool(settings, "setUsesGrayscaleTintView:", NO);
            GG_CallBool(settings, "setUsesColorTintView:", YES);
        }
    }

    if (settings && [c instancesRespondToSelector:initFrame]) {
        view = ((id (*)(id, SEL, CGRect, BOOL, id))objc_msgSend)([c alloc], initFrame, frame, YES, settings);
    }
    if (!view) {
        view = ((id (*)(id, SEL, CGRect))objc_msgSend)([c alloc], initSimple, frame);
        if (settings) {
            GG_Call1v(view, "transitionToSettings:", settings);
            GG_Call1v(view, "setSettings:", settings);
        }
    }
    if (view) {
        view.userInteractionEnabled = NO;
        view.clipsToBounds = YES;
    }
    return view;
}

/// Apply CAFilter gaussianBlur / saturate on a layer (private CAFilter).
BOOL GGPrivate_ApplyLayerFilters(CALayer *layer, float blur, float saturate, float brightness) {
    if (!layer) return NO;
    Class filterCls = GG_Cls("CAFilter");
    if (!filterCls) return NO;

    NSMutableArray *filters = [NSMutableArray array];

    SEL filterWithType = GG_Sel("filterWithType:");
    if (![filterCls respondsToSelector:filterWithType]) return NO;

    if (blur > 0.01f) {
        id f = ((id (*)(Class, SEL, id))objc_msgSend)(filterCls, filterWithType, @"gaussianBlur");
        if (f) {
            GG_Call1v(f, "setValue:forKey:", @(blur));
            // set inputRadius via KVC
            @try { [f setValue:@(blur) forKey:@"inputRadius"]; } @catch (__unused NSException *e) {}
            [filters addObject:f];
        }
    }
    if (fabsf(saturate - 1.f) > 0.01f) {
        id f = ((id (*)(Class, SEL, id))objc_msgSend)(filterCls, filterWithType, @"colorSaturate");
        if (f) {
            @try { [f setValue:@(saturate) forKey:@"inputAmount"]; } @catch (__unused NSException *e) {}
            [filters addObject:f];
        }
    }
    if (fabsf(brightness) > 0.01f) {
        id f = ((id (*)(Class, SEL, id))objc_msgSend)(filterCls, filterWithType, @"colorBrightness");
        if (f) {
            @try { [f setValue:@(brightness) forKey:@"inputAmount"]; } @catch (__unused NSException *e) {}
            [filters addObject:f];
        }
    }

    if (filters.count == 0) return NO;
    @try {
        [layer setValue:filters forKey:@"filters"];
        return YES;
    } @catch (__unused NSException *e) {
        return NO;
    }
}

void GGPrivate_ClearLayerFilters(CALayer *layer) {
    if (!layer) return;
    @try { [layer setValue:nil forKey:@"filters"]; } @catch (__unused NSException *e) {}
}

/// UISheetPresentation / material variants
UIVisualEffect *GGPrivate_SystemChromeMaterial(BOOL dark, BOOL ultraThin) {
    if (GGPrivate_HasUIGlassEffect()) {
        UIVisualEffect *g = GGPrivate_MakeGlassEffect(ultraThin);
        if (g) return g;
    }
    UIBlurEffectStyle style;
    if (ultraThin) {
        style = dark ? UIBlurEffectStyleSystemUltraThinMaterialDark : UIBlurEffectStyleSystemUltraThinMaterialLight;
    } else {
        style = dark ? UIBlurEffectStyleSystemThinMaterialDark : UIBlurEffectStyleSystemThinMaterialLight;
    }
    return [UIBlurEffect effectWithStyle:style];
}

NSString *GGPrivate_CapabilityReport(void) {
    NSMutableString *s = [NSMutableString string];
    [s appendFormat:@"UIGlassEffect=%d\n", GGPrivate_HasUIGlassEffect()];
    [s appendFormat:@"_UIBackdropView=%d\n", GG_Cls("_UIBackdropView") != Nil];
    [s appendFormat:@"UIBackdropView=%d\n", GG_Cls("UIBackdropView") != Nil];
    [s appendFormat:@"_UIBackdropViewSettings=%d\n", GG_Cls("_UIBackdropViewSettings") != Nil];
    [s appendFormat:@"CAFilter=%d\n", GG_Cls("CAFilter") != Nil];
    [s appendFormat:@"UIGlassContainerEffect=%d\n", GG_Cls("UIGlassContainerEffect") != Nil];
    [s appendFormat:@"_UIVisualEffectBackdropView=%d\n", GG_Cls("_UIVisualEffectBackdropView") != Nil];
    [s appendFormat:@"UIVariableBlurEffect=%d\n", GG_Cls("UIVariableBlurEffect") != Nil];
    return s;
}

/// Hook-friendly: try to set continuous corner curve privately on layer.
void GGPrivate_SetContinuousCorners(UIView *view, CGFloat radius) {
    if (!view) return;
    view.layer.cornerRadius = radius;
    if (@available(iOS 13.0, *)) {
        view.layer.cornerCurve = kCACornerCurveContinuous;
    }
    // Private: continuousCorners BOOL on CALayer (older)
    @try {
        [view.layer setValue:@YES forKey:@"continuousCorners"];
    } @catch (__unused NSException *e) {}
}
