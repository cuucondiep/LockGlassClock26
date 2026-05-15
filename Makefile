ARCHS = arm64 arm64e
TARGET = iphone:clang:latest:16.0
THEOS_PACKAGE_SCHEME = roothide

export GO_EASY_ON_ME = 1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HaiLockGlassClock

HaiLockGlassClock_FILES = Tweak.x
HaiLockGlassClock_CFLAGS = -fobjc-arc
HaiLockGlassClock_FRAMEWORKS = UIKit QuartzCore

include $(THEOS_MAKE_PATH)/tweak.mk

SUBPROJECTS += HaiLockGlassClockPrefs

include $(THEOS_MAKE_PATH)/aggregate.mk
