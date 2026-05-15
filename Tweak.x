#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreFoundation/CoreFoundation.h>

static CFStringRef const kHLGCPrefsDomain = CFSTR("com.hai.hailockglassclockprefs");
static CFStringRef const kHLGCPrefsChangedNotification = CFSTR("com.hai.hailockglassclockprefs/Reload");

static BOOL gHLGCEnabled = YES;
static CGFloat gHLGCClockY = 45.0;
static CGFloat gHLGCClockScale = 0.39;
static CGFloat gHLGCClockAlpha = 0.48;

static BOOL HLGC_ReadBool(NSString *key, BOOL fallback) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, kHLGCPrefsDomain);
    id obj = CFBridgingRelease(value);

    if ([obj isKindOfClass:[NSNumber class]]) {
        return [obj boolValue];
    }

    return fallback;
}

static CGFloat HLGC_ReadFloat(NSString *key, CGFloat fallback) {
    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key, kHLGCPrefsDomain);
    id obj = CFBridgingRelease(value);

    if ([obj isKindOfClass:[NSNumber class]]) {
        return (CGFloat)[obj doubleValue];
    }

    return fallback;
}

static void HLGC_LoadPrefs(void) {
    CFPreferencesAppSynchronize(kHLGCPrefsDomain);

    gHLGCEnabled = HLGC_ReadBool(@"Enabled", YES);
    gHLGCClockY = HLGC_ReadFloat(@"ClockY", 45.0);
    gHLGCClockScale = HLGC_ReadFloat(@"ClockScale", 0.39);
    gHLGCClockAlpha = HLGC_ReadFloat(@"ClockAlpha", 0.48);

    if (gHLGCClockY < 0.0) gHLGCClockY = 0.0;
    if (gHLGCClockY > 160.0) gHLGCClockY = 160.0;

    if (gHLGCClockScale < 0.25) gHLGCClockScale = 0.25;
    if (gHLGCClockScale > 0.50) gHLGCClockScale = 0.50;

    if (gHLGCClockAlpha < 0.10) gHLGCClockAlpha = 0.10;
    if (gHLGCClockAlpha > 1.00) gHLGCClockAlpha = 1.00;

    NSLog(@"[HaiLockGlassClock] prefs loaded enabled=%d y=%.2f scale=%.2f alpha=%.2f",
          gHLGCEnabled,
          gHLGCClockY,
          gHLGCClockScale,
          gHLGCClockAlpha);
}

static void HLGC_PrefsChanged(CFNotificationCenterRef center,
                              void *observer,
                              CFStringRef name,
                              const void *object,
                              CFDictionaryRef userInfo) {
    HLGC_LoadPrefs();
}

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

static BOOL HLGC_IsClockLabel(UILabel *label) {
    if (!label) return NO;

    NSString *text = label.text ?: @"";
    CGFloat fontSize = label.font.pointSize;

    if (text.length == 0) return NO;

    if (fontSize >= 45.0) return YES;

    if ([text containsString:@":"] && text.length <= 5) return YES;

    return NO;
}

static void HLGC_StyleClockLabel(UILabel *label) {
    if (!label) return;

    NSString *text = label.text ?: @"";
    if (text.length == 0) return;

    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;

    CGFloat newSize = screenWidth * gHLGCClockScale;

    if (newSize < 110.0) newSize = 110.0;
    if (newSize > 180.0) newSize = 180.0;

    UIFont *font = [UIFont systemFontOfSize:newSize weight:UIFontWeightThin];

    if (font) {
        label.font = font;
    }

    label.textColor = [UIColor colorWithWhite:1.0 alpha:gHLGCClockAlpha];
    label.alpha = 1.0;

    label.textAlignment = NSTextAlignmentCenter;
    label.adjustsFontSizeToFitWidth = YES;
    label.minimumScaleFactor = 0.65;
    label.numberOfLines = 1;

    label.layer.shadowColor = [UIColor whiteColor].CGColor;
    label.layer.shadowOpacity = 0.12;
    label.layer.shadowRadius = 2.0;
    label.layer.shadowOffset = CGSizeMake(0, 0);

    label.layer.masksToBounds = NO;

    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];

    if (attr.length > 0) {
        [attr addAttribute:NSForegroundColorAttributeName
                     value:[UIColor colorWithWhite:1.0 alpha:gHLGCClockAlpha]
                     range:NSMakeRange(0, attr.length)];

        [attr addAttribute:NSStrokeColorAttributeName
                     value:[UIColor colorWithWhite:1.0 alpha:0.18]
                     range:NSMakeRange(0, attr.length)];

        [attr addAttribute:NSStrokeWidthAttributeName
                     value:@(-1.0)
                     range:NSMakeRange(0, attr.length)];

        [attr addAttribute:NSKernAttributeName
                     value:@(-6.0)
                     range:NSMakeRange(0, attr.length)];

        label.attributedText = attr;
    }

    UIView *superview = label.superview;

    if (superview) {
        CGRect frame = label.frame;

        frame.size.width = screenWidth;
        frame.size.height = newSize * 1.05;
        frame.origin.x = -superview.frame.origin.x;
        frame.origin.y = -10.0;

        label.frame = frame;
    }
}

static void HLGC_StyleDateLabel(UILabel *label) {
    if (!label) return;

    NSString *text = label.text ?: @"";
    if (text.length == 0) return;

    UIFont *font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightSemibold];

    if (font) {
        label.font = font;
    }

    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.82];
    label.alpha = 1.0;
    label.textAlignment = NSTextAlignmentCenter;

    label.layer.shadowColor = [UIColor blackColor].CGColor;
    label.layer.shadowOpacity = 0.18;
    label.layer.shadowRadius = 2.0;
    label.layer.shadowOffset = CGSizeMake(0, 1);

    UIView *superview = label.superview;

    if (superview) {
        CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;
        CGRect frame = label.frame;

        frame.size.width = screenWidth;
        frame.size.height = 22.0;
        frame.origin.x = -superview.frame.origin.x;
        frame.origin.y = -4.0;

        label.frame = frame;
    }
}

static void HLGC_ApplyClockStyle(UIView *dateView) {
    if (!dateView) return;

    if (!gHLGCEnabled) return;

    NSArray<UILabel *> *labels = HLGC_FindLabels(dateView);

    UILabel *clockLabel = nil;

    for (UILabel *label in labels) {
        if (HLGC_IsClockLabel(label)) {
            if (!clockLabel || label.font.pointSize > clockLabel.font.pointSize) {
                clockLabel = label;
            }
        }
    }

    for (UILabel *label in labels) {
        if (label == clockLabel) {
            HLGC_StyleClockLabel(label);
        } else {
            HLGC_StyleDateLabel(label);
        }
    }

    CGRect frame = dateView.frame;

    frame.origin.y = gHLGCClockY;

    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;

    frame.origin.x = 0.0;
    frame.size.width = screenWidth;
    frame.size.height = 190.0;

    dateView.frame = frame;
    dateView.clipsToBounds = NO;
    dateView.layer.masksToBounds = NO;

    for (UIView *subview in dateView.subviews) {
        subview.clipsToBounds = NO;
        subview.layer.masksToBounds = NO;
    }
}

%hook SBFLockScreenDateView

- (void)didMoveToWindow {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        HLGC_LoadPrefs();
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
    HLGC_LoadPrefs();

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    HLGC_PrefsChanged,
                                    kHLGCPrefsChangedNotification,
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);

    NSLog(@"[HaiLockGlassClock] Loaded with preferences");
}
