export TARGET = iphone:clang:8.1:latest

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = BatteryBar
BatteryBar_FILES = BBRootListController.m BBSolidColorListController.m BBGradientListController.m BBSliderCell.m
BatteryBar_INSTALL_PATH = /Library/PreferenceBundles
BatteryBar_FRAMEWORKS = UIKit MessageUI
BatteryBar_PRIVATE_FRAMEWORKS = Preferences
SwitcherControls_LIBRARIES = colorpicker

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/BatteryBar.plist$(ECHO_END)
