export ARCHS = armv7 arm64
export TARGET = iphone:clang:9.3:latest

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = BatteryBar
BatteryBar_FILES = Tweak.xm BatteryColorPrefs.m
BatteryBar_FRAMEWORKS = UIKit CoreGraphics
BatteryBar_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += batterybar
include $(THEOS_MAKE_PATH)/aggregate.mk
