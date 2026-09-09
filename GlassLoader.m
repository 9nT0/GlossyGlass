#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>

// Swift exports these (GlassLoader.swift) — do not redefine here
extern void GlassLoaderEntry(void) __attribute__((weak));
extern void glossyglass_init(void) __attribute__((weak));

static void GGCallSwift(void) {
    if (GlassLoaderEntry) {
        GlassLoaderEntry();
        return;
    }
    if (glossyglass_init) {
        glossyglass_init();
        return;
    }
    void *sym = dlsym(RTLD_DEFAULT, "GlassLoaderEntry");
    if (!sym) sym = dlsym(RTLD_DEFAULT, "glossyglass_init");
    if (!sym) sym = dlsym(RTLD_DEFAULT, "TweakInitialize");
    if (!sym) sym = dlsym(RTLD_DEFAULT, "Initialize");
    if (sym) {
        ((void (*)(void))sym)();
    }
}

static void GGSchedule(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSLog(@"[GlossyGlass] ObjC loader constructor armed");
        dispatch_async(dispatch_get_main_queue(), ^{ GGCallSwift(); });
        for (NSNumber *n in @[@0.25, @0.75, @1.5, @3.0, @6.0, @12.0, @20.0]) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(n.doubleValue * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{ GGCallSwift(); });
        }
        NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
        id block = ^(NSNotification *note) { GGCallSwift(); };
        [nc addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:block];
        [nc addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:block];
        if (@available(iOS 13.0, *)) {
            [nc addObserverForName:UISceneDidActivateNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:block];
            [nc addObserverForName:UISceneWillEnterForegroundNotification object:nil queue:NSOperationQueue.mainQueue usingBlock:block];
        }
    });
}

__attribute__((constructor))
static void GlossyGlassConstructor(void) {
    GGSchedule();
}

@interface GlossyGlassLoadProbe : NSObject
@end
@implementation GlossyGlassLoadProbe
+ (void)load {
    GGSchedule();
}
@end
