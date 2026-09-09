#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

/// Deep UIKit + Instagram lifecycle hooks for GlossyGlass.
/// Swizzles appear/layout so glass materials re-apply as IG builds screens.

@class GlassStyleApplicator;
@class GlassInjector;
@class GlassAppSupport;
@class GlassPreferences;
@class GlassLoader;

@interface GlassStyleApplicator : NSObject
+ (void)applyAll;
+ (void)applyToView:(UIView *)view;
+ (void)applyToViewController:(UIViewController *)vc;
@end

@interface GlassInjector : NSObject
+ (void)start;
+ (void)attemptInjection;
+ (void)forceRedetect;
@end

static BOOL GG_HooksInstalled = NO;
static void GG_InstallHooks(void);

#pragma mark - Swizzle helper

static void GG_SwizzleInstance(Class cls, SEL original, SEL replacement) {
    if (!cls) return;
    Method m1 = class_getInstanceMethod(cls, original);
    Method m2 = class_getInstanceMethod(cls, replacement);
    if (!m1 || !m2) return;
    method_exchangeImplementations(m1, m2);
}

static void GG_AddAndSwizzle(Class cls, SEL original, SEL replacement, IMP imp, const char *types) {
    if (!cls || !imp) return;
    class_addMethod(cls, replacement, imp, types);
    Method m1 = class_getInstanceMethod(cls, original);
    Method m2 = class_getInstanceMethod(cls, replacement);
    if (m1 && m2) method_exchangeImplementations(m1, m2);
}

static void GG_SafeApply(void) {
    @try {
        Class app = NSClassFromString(@"GlassStyleApplicator");
        if (app && [app respondsToSelector:@selector(applyAll)]) {
            ((void (*)(id, SEL))objc_msgSend)(app, @selector(applyAll));
        }
    } @catch (__unused NSException *e) {}
}

static void GG_SafeApplyVC(UIViewController *vc) {
    if (!vc) return;
    @try {
        Class app = NSClassFromString(@"GlassStyleApplicator");
        if (app && [app respondsToSelector:@selector(applyToViewController:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(app, @selector(applyToViewController:), vc);
        } else {
            GG_SafeApply();
        }
    } @catch (__unused NSException *e) {}
}

static void GG_SafeInject(void) {
    @try {
        Class inj = NSClassFromString(@"GlassInjector");
        if (inj && [inj respondsToSelector:@selector(attemptInjection)]) {
            ((void (*)(id, SEL))objc_msgSend)(inj, @selector(attemptInjection));
        }
    } @catch (__unused NSException *e) {}
}

#pragma mark - UIViewController hooks

@interface UIViewController (GlossyGlassHooks)
- (void)gg_viewDidAppear:(BOOL)animated;
- (void)gg_viewWillAppear:(BOOL)animated;
- (void)gg_viewDidLayoutSubviews;
@end

@implementation UIViewController (GlossyGlassHooks)

- (void)gg_viewDidAppear:(BOOL)animated {
    [self gg_viewDidAppear:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        GG_SafeApplyVC(self);
        GG_SafeInject();
    });
}

- (void)gg_viewWillAppear:(BOOL)animated {
    [self gg_viewWillAppear:animated];
    // Light touch — full apply on didAppear
}

- (void)gg_viewDidLayoutSubviews {
    [self gg_viewDidLayoutSubviews];
    // Throttle via associated flag
    NSNumber *last = objc_getAssociatedObject(self, "gg_lastLayout");
    NSTimeInterval now = CFAbsoluteTimeGetCurrent();
    if (last && (now - last.doubleValue) < 0.35) return;
    objc_setAssociatedObject(self, "gg_lastLayout", @(now), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dispatch_async(dispatch_get_main_queue(), ^{
        GG_SafeApplyVC(self);
    });
}

@end

#pragma mark - UINavigationBar

@interface UINavigationBar (GlossyGlassHooks)
- (void)gg_layoutSubviews;
- (void)gg_didMoveToWindow;
@end

@implementation UINavigationBar (GlossyGlassHooks)

- (void)gg_layoutSubviews {
    [self gg_layoutSubviews];
    @try {
        Class helper = NSClassFromString(@"GlassNavigationHelper");
        if (helper && [helper respondsToSelector:@selector(applyNavigationBarStyle:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(helper, @selector(applyNavigationBarStyle:), self);
        }
    } @catch (__unused NSException *e) {}
}

- (void)gg_didMoveToWindow {
    [self gg_didMoveToWindow];
    if (self.window) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                Class helper = NSClassFromString(@"GlassNavigationHelper");
                if (helper && [helper respondsToSelector:@selector(applyNavigationBarStyle:)]) {
                    ((void (*)(id, SEL, id))objc_msgSend)(helper, @selector(applyNavigationBarStyle:), self);
                }
            } @catch (__unused NSException *e) {}
        });
    }
}

@end

#pragma mark - UITabBar

@interface UITabBar (GlossyGlassHooks)
- (void)gg_layoutSubviews;
- (void)gg_didMoveToWindow;
@end

@implementation UITabBar (GlossyGlassHooks)

- (void)gg_layoutSubviews {
    [self gg_layoutSubviews];
    @try {
        Class helper = NSClassFromString(@"GlassNavigationHelper");
        if (helper && [helper respondsToSelector:@selector(applyTabBarStyle:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(helper, @selector(applyTabBarStyle:), self);
        }
    } @catch (__unused NSException *e) {}
}

- (void)gg_didMoveToWindow {
    [self gg_didMoveToWindow];
    if (self.window) {
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                Class helper = NSClassFromString(@"GlassNavigationHelper");
                if (helper && [helper respondsToSelector:@selector(applyTabBarStyle:)]) {
                    ((void (*)(id, SEL, id))objc_msgSend)(helper, @selector(applyTabBarStyle:), self);
                }
            } @catch (__unused NSException *e) {}
        });
    }
}

@end

#pragma mark - UIWindow

@interface UIWindow (GlossyGlassHooks)
- (void)gg_makeKeyAndVisible;
- (void)gg_didAddSubview:(UIView *)subview;
@end

@implementation UIWindow (GlossyGlassHooks)

- (void)gg_makeKeyAndVisible {
    [self gg_makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        GG_SafeApply();
        GG_SafeInject();
    });
}

- (void)gg_didAddSubview:(UIView *)subview {
    [self gg_didAddSubview:subview];
}

@end

#pragma mark - UINavigationController

@interface UINavigationController (GlossyGlassHooks)
- (void)gg_pushViewController:(UIViewController *)vc animated:(BOOL)animated;
- (UIViewController *)gg_popViewControllerAnimated:(BOOL)animated;
@end

@implementation UINavigationController (GlossyGlassHooks)

- (void)gg_pushViewController:(UIViewController *)vc animated:(BOOL)animated {
    [self gg_pushViewController:vc animated:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        GG_SafeApplyVC(vc);
        if (self.navigationBar) {
            @try {
                Class helper = NSClassFromString(@"GlassNavigationHelper");
                if (helper && [helper respondsToSelector:@selector(applyNavigationBarStyle:)]) {
                    ((void (*)(id, SEL, id))objc_msgSend)(helper, @selector(applyNavigationBarStyle:), self.navigationBar);
                }
            } @catch (__unused NSException *e) {}
        }
        GG_SafeInject();
    });
}

- (UIViewController *)gg_popViewControllerAnimated:(BOOL)animated {
    UIViewController *r = [self gg_popViewControllerAnimated:animated];
    dispatch_async(dispatch_get_main_queue(), ^{
        GG_SafeApply();
        GG_SafeInject();
    });
    return r;
}

@end

#pragma mark - Instagram-specific class hooks

static void GG_HookIGClass(const char *name) {
    Class cls = NSClassFromString([NSString stringWithUTF8String:name]);
    if (!cls) return;

    // Reuse UIViewController swizzles if it's a subclass — already covered.
    // Also hook viewDidLoad if present for earlier glass.
    SEL orig = @selector(viewDidLoad);
    SEL repl = NSSelectorFromString(@"gg_ig_viewDidLoad");
    Method m = class_getInstanceMethod(cls, orig);
    if (!m) return;
    // Only add if not already
    if (class_getInstanceMethod(cls, repl)) return;

    IMP origIMP = method_getImplementation(m);
    const char *types = method_getTypeEncoding(m);

    IMP newIMP = imp_implementationWithBlock(^(id selfObj) {
        ((void (*)(id, SEL))origIMP)(selfObj, orig);
        if ([selfObj isKindOfClass:[UIViewController class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                GG_SafeApplyVC((UIViewController *)selfObj);
                GG_SafeInject();
            });
        }
    });
    class_addMethod(cls, repl, newIMP, types);
    Method m2 = class_getInstanceMethod(cls, repl);
    if (m2) method_exchangeImplementations(m, m2);
    NSLog(@"[GlossyGlass] Hooked IG class %s", name);
}

static void GG_HookAllIGClasses(void) {
    const char *names[] = {
        "IGViewController",
        "IGTabBarController",
        "IGNavigationController",
        "IGMainFeedViewController",
        "IGRootViewController",
        "IGHomeViewController",
        "IGProfileViewController",
        "IGDirectInboxViewController",
        "IGDirectThreadViewController",
        "IGFeedViewController",
        "IGStoryViewController",
        "IGExploreViewController",
        "IGSearchViewController",
        "IGActivityFeedViewController",
        "IGMediaViewerViewController",
        "IGShoppingViewController",
        "IGSettingsViewController",
        "IGAppDelegate",
        "IGScopedViewController",
        "IGViewControllerWithFeedItem",
        NULL
    };
    for (int i = 0; names[i]; i++) {
        GG_HookIGClass(names[i]);
    }
}

#pragma mark - Install

static void GG_InstallHooks(void) {
    if (GG_HooksInstalled) return;
    GG_HooksInstalled = YES;

    GG_SwizzleInstance([UIViewController class],
                       @selector(viewDidAppear:),
                       @selector(gg_viewDidAppear:));
    GG_SwizzleInstance([UIViewController class],
                       @selector(viewWillAppear:),
                       @selector(gg_viewWillAppear:));
    GG_SwizzleInstance([UIViewController class],
                       @selector(viewDidLayoutSubviews),
                       @selector(gg_viewDidLayoutSubviews));

    GG_SwizzleInstance([UINavigationBar class],
                       @selector(layoutSubviews),
                       @selector(gg_layoutSubviews));
    GG_SwizzleInstance([UINavigationBar class],
                       @selector(didMoveToWindow),
                       @selector(gg_didMoveToWindow));

    GG_SwizzleInstance([UITabBar class],
                       @selector(layoutSubviews),
                       @selector(gg_layoutSubviews));
    GG_SwizzleInstance([UITabBar class],
                       @selector(didMoveToWindow),
                       @selector(gg_didMoveToWindow));

    GG_SwizzleInstance([UIWindow class],
                       @selector(makeKeyAndVisible),
                       @selector(gg_makeKeyAndVisible));

    GG_SwizzleInstance([UINavigationController class],
                       @selector(pushViewController:animated:),
                       @selector(gg_pushViewController:animated:));
    GG_SwizzleInstance([UINavigationController class],
                       @selector(popViewControllerAnimated:),
                       @selector(gg_popViewControllerAnimated:));

    GG_HookAllIGClasses();

    NSLog(@"[GlossyGlass] Deep hooks installed");
}

__attribute__((constructor))
static void GG_HooksConstructor(void) {
    // Slight delay so UIKit classes are up; also re-hook IG classes later (load late)
    dispatch_async(dispatch_get_main_queue(), ^{
        GG_InstallHooks();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        GG_HookAllIGClasses();
        GG_SafeApply();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        GG_HookAllIGClasses();
        GG_SafeApply();
        GG_SafeInject();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        GG_HookAllIGClasses();
        GG_SafeApply();
    });
}

void GlassHooks_Install(void) {
    GG_InstallHooks();
    GG_HookAllIGClasses();
}
