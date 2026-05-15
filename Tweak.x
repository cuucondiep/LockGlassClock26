#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

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

    // Clock label trên lockscreen thường có font lớn nhất
    if (fontSize >= 45.0) return YES;

    // Dự phòng: text có dấu ":" và ít ký tự, ví dụ 9:41 / 09:41
    if ([text containsString:@":"] && text.length <= 5) return YES;

    return NO;
}

static void HLGC_StyleClockLabel(UILabel *label) {
    if (!label) return;

    NSString *text = label.text ?: @"";
    if (text.length == 0) return;

    CGFloat screenWidth = UIScreen.mainScreen.bounds.size.width;

    /*
     Kiểu giống ảnh:
     - Font lớn
     - Mảnh
     - Rất trong suốt
     */
    CGFloat newSize = screenWidth * 0.37;

    if (newSize < 132.0) newSize = 132.0;
    if (newSize > 165.0) newSize = 165.0;

    UIFont *font = nil;

    // Font mảnh giống iOS lockscreen hiện đại
    font = [UIFont systemFontOfSize:newSize weight:UIFontWeightThin];

    if (font) {
        label.font = font;
    }

    label.textColor = [UIColor colorWithWhite:1.0 alpha:0.50];
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

    // Tạo cảm giác “glass”: viền trong nhẹ + chữ trong suốt
    NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:text];

    if (attr.length > 0) {
        [attr addAttribute:NSForegroundColorAttributeName
                     value:[UIColor colorWithWhite:1.0 alpha:0.52]
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

        // Đẩy đồng hồ lên cao giống ảnh
        frame.origin.y = -10.0;

        label.frame = frame;
    }
}

static void HLGC_StyleDateLabel(UILabel *label) {
    if (!label) return;

    NSString *text = label.text ?: @"";
    if (text.length == 0) return;

    CGFloat fontSize = 13.0;

    UIFont *font = [UIFont systemFontOfSize:fontSize weight:UIFontWeightSemibold];
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

        // Ngày nằm trên đồng hồ
        frame.origin.y = -4.0;

        label.frame = frame;
    }
}

static void HLGC_ApplyClockStyle(UIView *dateView) {
    if (!dateView) return;

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

    // Đẩy toàn bộ cụm ngày/giờ lên cao gần Dynamic Island
    CGRect frame = dateView.frame;

    frame.origin.y = 52.0;

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
    NSLog(@"[HaiLockGlassClock] Loaded - iOS26 large clock style");
}
