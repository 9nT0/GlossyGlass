
#import <Foundation/Foundation.h>
#import <zlib.h>
#import <stdlib.h>
#import <string.h>

extern const uint8_t kGlassLUTCompressed[];
extern const size_t kGlassLUTCompressedSize;
extern const size_t kGlassLUTRawSize;

static uint8_t *GG_LUT = NULL;
static size_t GG_LUTSize = 0;

BOOL GGEmbedded_EnsureLUT(void) {
    if (GG_LUT) return YES;
    GG_LUT = (uint8_t *)malloc(kGlassLUTRawSize);
    if (!GG_LUT) return NO;
    uLongf dest = (uLongf)kGlassLUTRawSize;
    int err = uncompress(GG_LUT, &dest, kGlassLUTCompressed, (uLong)kGlassLUTCompressedSize);
    if (err != Z_OK) {
        free(GG_LUT); GG_LUT = NULL; return NO;
    }
    GG_LUTSize = dest;
    return YES;
}

NSData *GGEmbedded_LUTData(void) {
    if (!GGEmbedded_EnsureLUT()) return nil;
    return [NSData dataWithBytesNoCopy:GG_LUT length:GG_LUTSize freeWhenDone:NO];
}

NSUInteger GGEmbedded_LUTByteCount(void) {
    GGEmbedded_EnsureLUT();
    return (NSUInteger)GG_LUTSize;
}

float GGEmbedded_Sample(NSUInteger index) {
    if (!GGEmbedded_EnsureLUT()) return 0;
    NSUInteger count = GG_LUTSize / sizeof(float);
    if (index >= count) return 0;
    float *f = (float *)GG_LUT;
    return f[index];
}
