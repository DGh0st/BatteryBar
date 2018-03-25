#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface PSListController (BBGPrivate)
-(void)clearCache;
-(BOOL)containsSpecifier:(id)arg1;
@end

@interface BBGradientListController : PSListController {
	BOOL _isCurrentlyDisablingSpecifiers;
	PSSpecifier *_gradientLowPowerModeColorSpecifier;
	PSSpecifier *_gradientChargingColorSpecifier;
}
@end
