#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface PSListController (BBRPrivate)
-(BOOL)containsSpecifier:(id)arg1;
@end

@interface BBRootListController : PSListController <MFMailComposeViewControllerDelegate> {
	BOOL _isCurrentlyDisablingSpecifiers;
	PSSpecifier *_bottomBarSpecifier;
	PSSpecifier *_hideChargingIconSpecifier;
	PSSpecifier *_homescreenBackgroundSpecifier;
	PSSpecifier *_customSolidBatteryColor;
	PSSpecifier *_customGradientBatteryColor;
	PSSpecifier *_batteryBarOpacity;
}
@end
