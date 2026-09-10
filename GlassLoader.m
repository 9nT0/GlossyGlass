#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <objc/runtime.h>

/*
 * Ultra-safe bootstrap. Nothing runs until the app has finished launching.
 * Early Swift / UIKit / swizzle work at constructor time crashes IG under Live Container.
 */

static BOOL GG_Started = NO;
static BOOL GG_Observers = NO;

void GlassHooks_Install(void); // optional weak-ish via dlsym

static void GGSafeCall(const char *name) {
    @try {
        dlerror();
        void *sym = dlsym(RTLD_DEFAULT, name);
        if (!sym) return;
        NSLog(@"[GlossyGlass] invoke %s", name);
        ((void (*)(void))sym)();
    } @catch (NSException *ex) {
        NSLog(@"[GlossyGlass] exception in %s: %@", name, ex);
    }
}

static void GGStartOnce(void) {
    if (GG_Started) return;
    // UIApplication must exist
    UIApplication *app = nil;
    @try { app = UIApplication.sharedApplication; } @catch (__unused NSException *e) {}
    if (!app) {
        NSLog(@"[GlossyGlass] UIApplication not ready — skip");
        return;
    }

    GG_Started = YES;
    NSLog(@"[GlossyGlass] safe start");

    // Hooks first (ObjC only), then Swift entry
    @try {
        void *hooks = dlsym(RTLD_DEFAULT, "GlassHooks_Install");
        if (hooks) ((void (*)(void))hooks)();
    } @catch (__unused NSException *e) {}

    GGSafeCall("GlassLoaderEntry");
    GGSafeCall("glossyglass_init");
}

static void GGArmObservers(void) {
    if (GG_Observers) return;
    GG_Observers = YES;

    NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
    void (^kick)(NSNotification *) = ^(NSNotification *note) {
        dispatch_async(dispatch_get_main_queue(), ^{ GGStartOnce(); });
    };

    [nc addObserverForName:UIApplicationDidFinishLaunchingNotification
                    object:nil queue:nil usingBlock:kick];
    [nc addObserverForName:UIApplicationDidBecomeActiveNotification
                    object:nil queue:nil usingBlock:kick];
    if (@available(iOS 13.0, *)) {
        [nc addObserverForName:UISceneDidActivateNotification
                        object:nil queue:nil usingBlock:kick];
    }
}

__attribute__((constructor))
static void glossyglass_objc_ctor(void) {
    // Constructor must do almost NOTHING.
    // Only arm notifications. No Swift. No swizzle. No UIApplication.
    NSLog(@"[GlossyGlass] ctor — deferred start only");
    @try {
        GGArmObservers();
    } @catch (__unused NSException *e) {}

    // Fallback if launch notification already fired (late inject)
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        GGStartOnce();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        GGStartOnce();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        GGStartOnce();
    });
}
