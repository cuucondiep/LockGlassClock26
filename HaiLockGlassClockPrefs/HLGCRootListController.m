#import "HLGCRootListController.h"
#import <Preferences/PSSpecifier.h>
#import <CoreFoundation/CoreFoundation.h>
#import <spawn.h>

extern char **environ;

static NSString * const kHLGCPrefsDomain = @"com.hai.hailockglassclockprefs";
static CFStringRef const kHLGCPrefsChangedNotification = CFSTR("com.hai.hailockglassclockprefs/Reload");

@implementation HLGCRootListController

- (NSArray *)specifiers {
    if (!_specifiers) {
        _specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
    }

    return _specifiers;
}

- (id)readPreferenceValue:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];
    id defaultValue = [specifier propertyForKey:@"default"];

    if (!key) {
        return defaultValue;
    }

    CFPropertyListRef value = CFPreferencesCopyAppValue((__bridge CFStringRef)key,
                                                        (__bridge CFStringRef)kHLGCPrefsDomain);

    if (value) {
        return CFBridgingRelease(value);
    }

    return defaultValue;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    NSString *key = [specifier propertyForKey:@"key"];

    if (!key) return;

    CFPreferencesSetAppValue((__bridge CFStringRef)key,
                             (__bridge CFPropertyListRef)value,
                             (__bridge CFStringRef)kHLGCPrefsDomain);

    CFPreferencesAppSynchronize((__bridge CFStringRef)kHLGCPrefsDomain);

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(),
                                         kHLGCPrefsChangedNotification,
                                         NULL,
                                         NULL,
                                         YES);
}

- (void)respring {
    pid_t pid;
    const char *argv[] = {"killall", "SpringBoard", NULL};

    posix_spawn(&pid,
                "/usr/bin/killall",
                NULL,
                NULL,
                (char * const *)argv,
                environ);
}

@end
