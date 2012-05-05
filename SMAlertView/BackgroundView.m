#import "BackgroundView.h"

@implementation BackgroundView

- (void)drawRect:(CGRect)rect {
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    float comps[8] = {0, 0, 0, .3, 0, 0, 0, 0.6};
    float locs[2] = {0, 1};
    CGGradientRef gradient = CGGradientCreateWithColorComponents(space, comps, locs, 2);
    float x = [self bounds].size.width / 2.0;
    float y = [self bounds].size.height / 2.0;
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextDrawRadialGradient(ctx, gradient, CGPointMake(x, y), 0, CGPointMake(x, y), 160, kCGGradientDrawsAfterEndLocation);
    CGColorSpaceRelease(space);
    CGGradientRelease(gradient);
}

@end
