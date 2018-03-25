#import <Preferences/PSSpecifier.h>
#import <Preferences/PSRootController.h>
#import <Preferences/PSSliderTableCell.h>

@interface PSRootController (BBPrivate)
+(void)setPreferenceValue:(id)arg1 specifier:(id)arg2;
@end

@interface BBSliderCell : PSSliderTableCell <UIAlertViewDelegate, UITextFieldDelegate> {
	CGFloat minValue;
	CGFloat maxValue;
}
-(void)presentAlert;
@end