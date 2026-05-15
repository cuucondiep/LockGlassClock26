#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

static NSInteger const kHLGCGlassTag = 260026;

static void HLGC_CollectLabels(UIView *view, NSMutableArray<UILabel *> *labels) {
    if (!view || !labels) return;

    if ([view isKindOfClass:[UILabel class]]) {
        [labels addObject:(UILabel *)view];
    }

    for (UIView *subview in view.subviews) {
        HLGC_CollectLabels(subview, labels);
    }
}

static NSArray<UILabel *> *HLGC_FindLabels(UIView *root) {
    NSMutableArray<UILabel *> *labels = [NSMutableArray array];
    HLGC_CollectLabels(root, labels);
    return labels;
}

static UIVisualEffectView *HLGC_GlassViewForContainer(UIView *container) {
    for (UIView *subview in container.subviews) {
        if (subview.tag == kHLGCGlassTag &&
            [subview isKindOfClass:[UIVisualEffectView class]]) {
            return (UIVisualEffectView *)subview;
        }
    }

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight];
    UIVisualEffectView *glass = [[UIVisualEffectView alloc] initWithEffect:blur];

    glass.tag = kHLGCGlassTag;
    glass.userInteractionEnabled = NO;
    glass.clipsToBounds = YES;
    glass.alpha = 0.72;

    glass.layer.cornerRadius = 30.0;

    if (@available(iOS 13.0, *)) {
        glass.layer.cornerCurve = kCACornerCurveContinuous;
    }

    glass.layer.borderWidth = 1.0;
    glass.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.35].CGColor;

    glass.layer.shadowColor = [UIColor blackColor].CGColor;
    glass.layer.shadowOpacity = 0.25;
    glass.layer.shadowRadius = 18.0;
    glass.layer.shadowOffset = CGSizeMake(0, 8);

    CAGradientLayer *shine = [CAGradientLayer layer];
    shine.name = @"HLGCShineLayer";
    shine.colors = @[
        (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.55].CGColor,
        (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.14].CGColor,
        (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.04].CGColor
    ];
    shine.locations = @[@0.0, @0.42, @1.0];
    shine.startPoint = CGPointMake(0.0, 0.0);
    shine.endPoint = CGPointMake(1.0, 1.0);

    [glass.contentView.layer addSublayer:shine];
    [container insertSubview:glass atIndex:0];

    return glass;
}

static void HLGC_UpdateInnerStroke(UIVisualEffectView *glass) {
    if (!glass) return;

    CAShapeLayer *innerStroke = nil;

    for (CALayer *layer in glass.layer.sublayers) {
        if ([layer.name isEqualToString:@"HLGCInnerStroke"]) {
            innerStroke = (CAShapeLayer *)layer;
            break;
        }
    }

    if (!innerStroke) {
        innerStroke = [CAShapeLayer layer];
        innerStroke.name = @"HLGCInnerStroke";
        innerStroke.fillColor = UIColor.clearColor.CGColor;
        innerStroke.strokeColor = [UIColor colorWithWhite:1.0 alpha:0.42].CGColor;
        innerStroke.lineWidth = 1.2;
        [glass.layer addSublayer:innerStroke];
    }

    CGFloat radius = MAX(glass.layer.cornerRadius - 1.0, 1.0);

    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectInset(glass.bounds, 1.0, 1.0)
                                                    cornerRadius:radius];

    innerStroke.frame = glass.bounds;
    innerStroke.path = path.CGPath;
}

static void HLGC_UpdateShineLayer(UIVisualEffectView *glass) {
    if (!glass) return;

    for (CALayer *layer in glass.contentView.layer.sublayers) {
        if ([layer.name isEqualToString:@"HLGCShineLayer"]) {
            layer.frame = glass.bounds;
        }
    }
}

static void HLGC_ApplyClockStyle(UIView *dateView) {
    if (!dateView) return;
    if (CGRectIsEmpty(dateView.bounds)) return;

    NSArray<UILabel *> *labels = HLGC_FindLabels(dateView);

    for (UILabel *label in labels) {
        NSString *text = label.text ?: @"";
        if (text.length == 0) continue;

        CGFloat fontSize = label.font.pointSize;

        label.textColor = [UIColor colorWithWhite:1.0 alpha:0.94];

        label.layer.shadowColor = [UIColor blackColor].CGColor;
        label.layer.shadowOpacity = 0.32;
        label.layer.shadowRadius = 8.0;
        label.layer.shadowOffset = CGSizeMake(0, 2);

        if (fontSize >= 50.0) {
            UIFontDescriptor *descriptor = [UIFontDescriptor fontDescriptorWithName:@".SFUIRounded-Heavy"
                                                                               size:fontSize];

            UIFont *font = [UIFont fontWithDescriptor:descriptor size:fontSize];

            if (font) {
                label.font = font;
            }

            label.alpha = 0.98;
        } else {
            UIFontDescriptor *descriptor = [UIFontDescriptor fontDescriptorWithName:@".SFUIRounded-Semibold"
                                                                               size:fontSize];

            UIFont *font = [UIFont fontWithDescriptor:descriptor size:fontSize];

            if (font) {
                label.font = font;
            }

            label.alpha = 0.88;
        }
    }

    CGRect bounds = dateView.bounds;

    CGFloat glassWidth = MAX(bounds.size.width + 36.0, 235.0);
    CGFloat glassHeight = MAX(bounds.size.height + 24.0, 98.0);

    CGRect glassFrame = CGRectMake(
        (bounds.size.width - glassWidth) / 2.0,
        (bounds.size.height - glassHeight) / 2.0,
        glassWidth,
        glassHeight
    );

    UIVisualEffectView *glass = HLGC_GlassViewForContainer(dateView);

    glass.frame = glassFrame;
    glass.layer.cornerRadius = MIN(34.0, glassHeight / 2.6);

    HLGC_UpdateShineLayer(glass);
    HLGC_UpdateInnerStroke(glass);
}

%hook SBFLockScreenDateView

- (void)didMoveToWindow {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        HLGC_ApplyClockStyle((UIView *)self);
    });
}

- (void)layoutSubviews {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        HLGC_ApplyClockStyle((UIView *)self);
    });
}

%end

%ctor {
    NSLog(@"[HaiLockGlassClock] Loaded");
}
