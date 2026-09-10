#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

/// Deep UIKit + Instagram hooks — safe swizzling only.
/// NEVER exchange a method that only exists on a superclass (that corrupts UIView globally).

static BOOL GG_HooksInstalled = NO;

#pragma mark - Safe swizzle

/// Returns YES if `cls` has its own implementation of `sel` (not inherited).
static BOOL GG_ClassDirectlyImplements(Class cls, SEL sel) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    BOOL found = NO;
    for (unsigned int i = 0; i < count; i++) {
        if (method_getName(methods[i]) == sel) {
            found = YES;
            break;
        }
    }
    if (methods) free(methods);
    return found;
}

/// Safe instance swizzle:
/// - If the class already implements `original`, exchange with replacement.
/// - If not, add `original` pointing at replacement IMP, and store original superclass IMP under replacement.
/// Never mutates a superclass Method structure.
static void GG_SafeSwizzleInstance(Class cls, SEL original, SEL replacement) {
    if (!cls) return;
    Method replMethod = class_getInstanceMethod(cls, replacement);
    if (!replMethod) return;

    IMP replIMP = method_getImplementation(replMethod);
    const char *types = method_getTypeEncoding(replMethod);

    if (GG_ClassDirectlyImplements(cls, original)) {
        Method origMethod = class_getInstanceMethod(cls, original);
        if (origMethod) {
            method_exchangeImplementations(origMethod, replMethod);
        }
        return;
    }

    // Class does not implement original — inherit from super. Add our method as `original`
    // without touching the superclass Method.
    Method inherited = class_getInstanceMethod(cls, original);
    IMP inheritedIMP = inherited ? method_getImplementation(inherited) : NULL;
    if (!inheritedIMP) return;

    // Add original selector with our replacement body
    if (!class_addMethod(cls, original, replIMP, types)) {
        // Race / already added
        Method origMethod = class_getInstanceMethod(cls, original);
        if (origMethod && GG_ClassDirectlyImplements(cls, original)) {
            method_exchangeImplementations(origMethod, replMethod);
        }
        return;
    }
    // Point replacement selector at the inherited implementation so [self replacement] calls super path
    class_replaceMethod(cls, replacement, inheritedIMP, types);
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

static void GG_ApplyNavBar(UINavigationBar *bar) {
    if (!bar) return;
    @try {
        Class helper = NSClassFromString(@"GlassNavigationHelper");
        if (helper && [helper respondsToSelector:@selector(applyNavigationBarStyle:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(helper, @selector(applyNavigationBarStyle:), bar);
        }
    } @catch (__unused NSException *e) {}
}

static void GG_ApplyTabBar(UITabBar *bar) {
    if (!bar) return;
    @try {
        Class helper = NSClassFromString(@"GlassNavigationHelper");
        if (helper && [helper respondsToSelector:@selector(applyTabBarStyle:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(helper, @selector(applyTabBarStyle:), bar);
        }
    } @catch (__unused NSException *e) {}
}

#pragma mark - UIViewController

@interface UIViewController (GlossyGlassHooks)
- (void)gg_viewDidAppear:(BOOL)animated;
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

- (void)gg_viewDidLayoutSubviews {
    [self gg_viewDidLayoutSubviews];
    NSNumber *last = objc_getAssociatedObject(self, "gg_lastLayout");
    NSTimeInterval now = CFAbsoluteTimeGetCurrent();
    if (last && (now - last.doubleValue) < 0.40) return;
    objc_setAssociatedObject(self, "gg_lastLayout", @(now), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    dispatch_async(dispatch_get_main_queue(), ^{
        GG_SafeApplyVC(self);
    });
}

@end

#pragma mark - UINavigationBar (layout only — no didMoveToWindow)

@interface UINavigationBar (GlossyGlassHooks)
- (void)gg_layoutSubviews;
@end

@implementation UINavigationBar (GlossyGlassHooks)

- (void)gg_layoutSubviews {
    [self gg_layoutSubviews];
    GG_ApplyNavBar(self);
}

@end

#pragma mark - UITabBar (layout only — no didMoveToWindow)

@interface UITabBar (GlossyGlassHooks)
- (void)gg_layoutSubviews;
@end

@implementation UITabBar (GlossyGlassHooks)

- (void)gg_layoutSubviews {
    [self gg_layoutSubviews];
    GG_ApplyTabBar(self);
}

@end

#pragma mark - UIWindow

@interface UIWindow (GlossyGlassHooks)
- (void)gg_makeKeyAndVisible;
@end

@implementation UIWindow (GlossyGlassHooks)

- (void)gg_makeKeyAndVisible {
    [self gg_makeKeyAndVisible];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        GG_SafeApply();
        GG_SafeInject();
    });
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
        GG_ApplyNavBar(self.navigationBar);
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

#pragma mark - Instagram classes

static void GG_HookIGClass(const char *name) {
    Class cls = NSClassFromString([NSString stringWithUTF8String:name]);
    if (!cls) return;

    SEL orig = @selector(viewDidLoad);
    SEL repl = NSSelectorFromString([NSString stringWithFormat:@"gg_ig_viewDidLoad_%s", name]);

    if (class_getInstanceMethod(cls, repl)) return; // already
    Method m = class_getInstanceMethod(cls, orig);
    if (!m) return;

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

    // Prefer adding as a direct override without exchanging superclass Method objects
    if (GG_ClassDirectlyImplements(cls, orig)) {
        class_addMethod(cls, repl, newIMP, types);
        Method m2 = class_getInstanceMethod(cls, repl);
        Method m1 = class_getInstanceMethod(cls, orig);
        if (m1 && m2) method_exchangeImplementations(m1, m2);
    } else {
        // Add viewDidLoad on this class pointing at our block; keep super via origIMP already captured
        class_addMethod(cls, orig, newIMP, types);
    }
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
        "IGScopedViewController",
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

    // UIViewController — these are almost always overridden / safe with SafeSwizzle
    GG_SafeSwizzleInstance([UIViewController class],
                           @selector(viewDidAppear:),
                           @selector(gg_viewDidAppear:));
    // viewDidLayoutSubviews swizzle disabled for launch stability

    // Bars — layoutSubviews only (UITabBar/UINavigationBar implement it). NO didMoveToWindow.
    GG_SafeSwizzleInstance([UINavigationBar class],
                           @selector(layoutSubviews),
                           @selector(gg_layoutSubviews));
    GG_SafeSwizzleInstance([UITabBar class],
                           @selector(layoutSubviews),
                           @selector(gg_layoutSubviews));

    // makeKeyAndVisible swizzle disabled — caused launch instability under LC

    GG_SafeSwizzleInstance([UINavigationController class],
                           @selector(pushViewController:animated:),
                           @selector(gg_pushViewController:animated:));
    GG_SafeSwizzleInstance([UINavigationController class],
                           @selector(popViewControllerAnimated:),
                           @selector(gg_popViewControllerAnimated:));

    GG_HookAllIGClasses();
    NSLog(@"[GlossyGlass] Deep hooks installed (safe)");
}

__attribute__((constructor))
static void GG_HooksConstructor(void) {
    // Do NOT install hooks at image load — wait for GlassHooks_Install from safe loader.
    NSLog(@"[GlossyGlass] hooks ctor idle (wait for install)");
}

void GlassHooks_Install(void) {
    @try {
        GG_InstallHooks();
        GG_HookAllIGClasses();
        // Re-hook IG classes as they appear late in containers
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @try { GG_HookAllIGClasses(); } @catch (__unused NSException *e) {}
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(8.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @try { GG_HookAllIGClasses(); GG_SafeApply(); } @catch (__unused NSException *e) {}
        });
    } @catch (NSException *ex) {
        NSLog(@"[GlossyGlass] GlassHooks_Install exception: %@", ex);
    }
}
