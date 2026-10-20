#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GlassBootstrap : NSObject
+ (void)start;
@end

__attribute__((constructor))
static void GlossyGlassConstructor(void) {
    dispatch_async(dispatch_get_main_queue(), ^{ [GlassBootstrap start]; });
}

@interface GlassLoader : NSObject
@end
@implementation GlassLoader
+ (void)load {
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_async(dispatch_get_main_queue(), ^{ [GlassBootstrap start]; });
    });
}
@end
