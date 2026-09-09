#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>

/*
 * ObjC bootstrap — runs before/without relying on Swift static init.
 * Critical for Live Container + DylibLoader + many sideload injectors.
 */

static void GGInvoke(const char *name) {
    dlerror();
    void *sym = dlsym(RTLD_DEFAULT, name);
    if (!sym) return;
    NSLog(@"[GlossyGlass] ObjC invoking %s", name);
    @try {
        ((void (*)(void))sym)();
    } @catch (NSException *ex) {
        NSLog(@"[GlossyGlass] ObjC invoke exception %s: %@", name, ex);
    }
}

static void GGCallSwift(void) {
    extern void GlassLoaderEntry(void) __attribute__((weak));
    extern void glossyglass_init(void) __attribute__((weak));

    if (GlassLoaderEntry) {
        GlassLoaderEntry();
        return;
    }
    if (glossyglass_init) {
        glossyglass_init();
        return;
    }
    GGInvoke("GlassLoaderEntry");
    GGInvoke("glossyglass_init");
    GGInvoke("TweakInitialize");
    GGInvoke("Initialize");
}

static void GGSchedule(void) {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        NSLog(@"[GlossyGlass] ObjC loader constructor armed");

        dispatch_async(dispatch_get_main_queue(), ^{ GGCallSwift(); });

        NSArray<NSNumber *> *delays = @[
            @0.15, @0.4, @0.8, @1.2, @2.0, @3.0, @5.0,
            @8.0, @12.0, @18.0, @25.0, @35.0, @50.0
        ];
        for (NSNumber *n in delays) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(n.doubleValue * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                GGCallSwift();
            });
        }

        NSNotificationCenter *nc = NSNotificationCenter.defaultCenter;
        void (^kick)(NSNotification *) = ^(NSNotification *note) { GGCallSwift(); };
        [nc addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil queue:NSOperationQueue.mainQueue usingBlock:kick];
        [nc addObserverForName:UIApplicationDidFinishLaunchingNotification
                        object:nil queue:NSOperationQueue.mainQueue usingBlock:kick];
        if (@available(iOS 13.0, *)) {
            [nc addObserverForName:UISceneDidActivateNotification
                            object:nil queue:NSOperationQueue.mainQueue usingBlock:kick];
            [nc addObserverForName:UISceneWillEnterForegroundNotification
                            object:nil queue:NSOperationQueue.mainQueue usingBlock:kick];
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
