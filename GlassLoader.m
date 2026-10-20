//
//  GlassLoader.m
//  GlossyGlass v5
//
//  Required for many dylib injectors. Calls into Swift bootstrap.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

// Forward declare the Swift entry point
@interface GlassBootstrap : NSObject
+ (void)start;
@end

__attribute__((constructor))
static void GlossyGlassConstructor(void) {
    // Delay slightly so the host process has a chance to set up
    dispatch_async(dispatch_get_main_queue(), ^{
        [GlassBootstrap start];
    });
}

// Also support +load for injectors that prefer it
@interface GlassLoader : NSObject
@end

@implementation GlassLoader

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [GlassBootstrap start];
        });
    });
}

@end
