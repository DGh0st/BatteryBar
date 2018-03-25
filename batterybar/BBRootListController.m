#include "BBRootListController.h"
#import "BBSolidColorListController.h"
#import "BBGradientListController.h"

@implementation BBRootListController 

- (id)initForContentSize:(CGSize)size {
	self = [super initForContentSize:size];
	if (self != nil) {
		UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon" inBundle:[self bundle] compatibleWithTraitCollection:nil]];
		iconView.contentMode = UIViewContentModeScaleAspectFit;
		iconView.frame = CGRectMake(0, 0, 29, 29);
		[self.navigationItem setTitleView:iconView];
		[iconView release];
		UIBarButtonItem *respringItem = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStyleDone target:self action:@selector(respring)];
		[self.navigationItem setRightBarButtonItem:respringItem animated:NO];
		self.navigationItem.rightBarButtonItem.enabled = NO;
		[respringItem release];

		_isCurrentlyDisablingSpecifiers = NO;
	}
	return self;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Root" target:self] retain];
	}
	return _specifiers;
}

- (void)email {
	if ([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *email = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
		[email setSubject:@"BatteryBar Support"];
		[email setToRecipients:[NSArray arrayWithObjects:@"deeppwnage@yahoo.com", nil]];
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/var/mobile/Library/Preferences/com.dgh0st.batterybar.plist"] mimeType:@"application/xml" fileName:@"Prefs.plist"];
		#pragma GCC diagnostic push
		#pragma GCC diagnostic ignored "-Wdeprecated-declarations"
		system("/usr/bin/dpkg -l > /tmp/dpkgl.log");
		#pragma GCC diagnostic pop
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/tmp/dpkgl.log"] mimeType:@"text/plain" fileName:@"dpkgl.txt"];
		[self.navigationController presentViewController:email animated:YES completion:nil];
		[email setMailComposeDelegate:self];
		[email release];
	}
}

- (void)mailComposeController:(id)controller didFinishWithResult:(MFMailComposeResult)result error:(id)error {
    [self dismissViewControllerAnimated:YES completion: nil];
}

- (void)donate {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/DGhost"]];
}

- (void)follow {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/D_Gh0st"]];
}

- (void)respring {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"BatteryBar" message:@"Are you sure you want to respring?" preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *respringAction = [UIAlertAction actionWithTitle:@"Yes, Respring" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.dgh0st.batterybar/respring"), NULL, NULL, YES);
	}];

	UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}];

	[alert addAction:respringAction];
	[alert addAction:cancelAction];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)setPreferenceValue:(id)value specifier:(id)specifier {
	[super setPreferenceValue:value specifier:specifier];

	if (!_isCurrentlyDisablingSpecifiers) {
		[self removeSpecifiersIfNeededAnimated:[NSNumber numberWithBool:YES]];
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}
}

- (void)viewDidLoad {
	[super viewDidLoad];

	[self removeSpecifiersIfNeededAnimated:[NSNumber numberWithBool:NO]];
}

- (void)reloadSpecifiers {
	[super reloadSpecifiers];

	[self removeSpecifiersIfNeededAnimated:[NSNumber numberWithBool:NO]];
}

- (void)removeSpecifiersIfNeededAnimated:(NSNumber *)animatedObject {
	BOOL animated = [animatedObject boolValue];

	_isCurrentlyDisablingSpecifiers = YES;

	if ([self specifierForID:@"BottomBar"] != nil)
		_bottomBarSpecifier = [self specifierForID:@"BottomBar"];
	if ([self specifierForID:@"HideChargingIcon"] != nil)
		_hideChargingIconSpecifier = [self specifierForID:@"HideChargingIcon"];
	if ([self specifierForID:@"HomescreenBackground"] != nil)
		_homescreenBackgroundSpecifier = [self specifierForID:@"HomescreenBackground"];
	if ([self specifierForID:@"CustomSolidBatteryColor"] != nil)
		_customSolidBatteryColor = [self specifierForID:@"CustomSolidBatteryColor"];
	if ([self specifierForID:@"CustomGradientBatteryColor"] != nil)
		_customGradientBatteryColor = [self specifierForID:@"CustomGradientBatteryColor"];
	if ([self specifierForID:@"BarOpacity"] != nil)
		_batteryBarOpacity = [self specifierForID:@"BarOpacity"];

	// Add/Remove the bottom bar switch
	if (_bottomBarSpecifier != nil) {
		PSSpecifier *batteryBarTypeSpecifier = [self specifierForID:@"BarType"];
		id batteryBarTypeValue = [self readPreferenceValue:batteryBarTypeSpecifier];
		if ([batteryBarTypeValue intValue] == 2) {
			if ([self containsSpecifier:_bottomBarSpecifier]) {
				[self setPreferenceValue:@NO specifier:_bottomBarSpecifier];
				[self removeSpecifier:[_bottomBarSpecifier retain] animated:YES];
			}
		} else if (![self containsSpecifier:_bottomBarSpecifier]) {
			[self insertSpecifier:_bottomBarSpecifier afterSpecifier:batteryBarTypeSpecifier];
			[_bottomBarSpecifier release];
		}
	}

	// Add/Remove the battery/charging icon switches
	if (_hideChargingIconSpecifier != nil) {
		PSSpecifier *hideBatteryIconSpecifier = [self specifierForID:@"HideBatteryIcon"];
		id batteryIconValue = [self readPreferenceValue:hideBatteryIconSpecifier];
		if (![batteryIconValue boolValue]) {
			if ([self containsSpecifier:_hideChargingIconSpecifier]) {
				[self setPreferenceValue:@NO specifier:_hideChargingIconSpecifier];
				[self removeSpecifier:[_hideChargingIconSpecifier retain] animated:animated];
			}
		} else if (![self containsSpecifier:_hideChargingIconSpecifier]) {
			[self insertSpecifier:_hideChargingIconSpecifier afterSpecifier:hideBatteryIconSpecifier animated:animated];
			[_hideChargingIconSpecifier release];
		}
	}

	// Add/Remove the status bar color and homescreen background specifiers
	if (_homescreenBackgroundSpecifier != nil) {
		PSSpecifier *colorStatusBarSpecifier = [self specifierForID:@"ColorStatusBar"];
		id statusBarStyleValue = [self readPreferenceValue:colorStatusBarSpecifier];
		if ([statusBarStyleValue intValue] == 0) { // Default Status Bar Style
			if ([self containsSpecifier:_homescreenBackgroundSpecifier]) {
				[self setPreferenceValue:@NO specifier:_homescreenBackgroundSpecifier];
				[self removeSpecifier:[_homescreenBackgroundSpecifier retain] animated:animated];
			}
		} else if (![self containsSpecifier:_homescreenBackgroundSpecifier]) {
			[self insertSpecifier:_homescreenBackgroundSpecifier afterSpecifier:colorStatusBarSpecifier animated:animated];
			[_homescreenBackgroundSpecifier release];
		}
	}

	// Add/Remove the colors sub-preferences
	PSSpecifier *batteryColorSpecifier = [self specifierForID:@"BatteryColor"];
	PSSpecifier *barColor = [self specifierForID:@"BarColor"];
	id batteryColorStyleValue = [self readPreferenceValue:batteryColorSpecifier];
	if ([batteryColorStyleValue intValue] == 0) {
		if (_batteryBarOpacity != nil && ![self containsSpecifier:_batteryBarOpacity]) {
			if (animated) {
				if (_customSolidBatteryColor != nil && [self containsSpecifier:_customSolidBatteryColor])
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:[_customSolidBatteryColor retain], nil] withSpecifiers:[NSArray arrayWithObjects:_batteryBarOpacity, nil] animated:YES];
				else if (_customGradientBatteryColor != nil && [self containsSpecifier:_customGradientBatteryColor])
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:[_customGradientBatteryColor retain], nil] withSpecifiers:[NSArray arrayWithObjects:_batteryBarOpacity, nil] animated:YES];
			} else {
				[self insertSpecifier:_batteryBarOpacity afterSpecifier:batteryColorSpecifier animated:animated];
			}
			[_batteryBarOpacity release];
		} else {
			if (_customSolidBatteryColor != nil && [self containsSpecifier:_customSolidBatteryColor])
				[self removeSpecifier:[_customSolidBatteryColor retain] animated:animated];
			if (_customGradientBatteryColor != nil && [self containsSpecifier:_customGradientBatteryColor])
				[self removeSpecifier:[_customGradientBatteryColor retain] animated:animated];
		}
		[barColor setProperty:@"Set the opacity of the batter bar" forKey:@"footerText"];
		[self reloadSpecifier:barColor animated:YES];
	} else if ([batteryColorStyleValue intValue] == 1) {
		if (_customSolidBatteryColor != nil && ![self containsSpecifier:_customSolidBatteryColor]) {
			if (animated) {
				if (_batteryBarOpacity != nil && [self containsSpecifier:_batteryBarOpacity])
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:[_batteryBarOpacity retain], nil] withSpecifiers:[NSArray arrayWithObjects:_customSolidBatteryColor, nil] animated:YES];
				else if (_customGradientBatteryColor != nil && [self containsSpecifier:_customGradientBatteryColor])
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:[_customGradientBatteryColor retain], nil] withSpecifiers:[NSArray arrayWithObjects:_customSolidBatteryColor, nil] animated:YES];
			} else {
				[self insertSpecifier:_customSolidBatteryColor afterSpecifier:batteryColorSpecifier animated:animated];
			}
			[_customSolidBatteryColor release];
		} else {
			if (_batteryBarOpacity != nil && [self containsSpecifier:_batteryBarOpacity])
				[self removeSpecifier:[_batteryBarOpacity retain] animated:animated];
			if (_customGradientBatteryColor != nil && [self containsSpecifier:_customGradientBatteryColor])
				[self removeSpecifier:[_customGradientBatteryColor retain] animated:animated];
		}
		[barColor setProperty:@"Set the custom solid or gradient color for the battery icon and the bar" forKey:@"footerText"];
		[self reloadSpecifier:barColor animated:YES];
	} else if ([batteryColorStyleValue intValue] == 2) {
		if (_customGradientBatteryColor != nil && ![self containsSpecifier:_customGradientBatteryColor]) {
			if (animated) {
				if (_batteryBarOpacity != nil && [self containsSpecifier:_batteryBarOpacity])
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:[_batteryBarOpacity retain], nil] withSpecifiers:[NSArray arrayWithObjects:_customGradientBatteryColor, nil] animated:YES];
				if (_customSolidBatteryColor != nil && [self containsSpecifier:_customSolidBatteryColor])
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:[_customSolidBatteryColor retain], nil] withSpecifiers:[NSArray arrayWithObjects:_customGradientBatteryColor, nil] animated:YES];
			} else {
				[self insertSpecifier:_customGradientBatteryColor afterSpecifier:batteryColorSpecifier animated:animated];
			}
			[_customGradientBatteryColor release];
		} else {
			if (_batteryBarOpacity != nil && [self containsSpecifier:_batteryBarOpacity])
				[self removeSpecifier:[_batteryBarOpacity retain] animated:animated];
			if (_customSolidBatteryColor != nil && [self containsSpecifier:_customSolidBatteryColor])
				[self removeSpecifier:[_customSolidBatteryColor retain] animated:animated];
		}
		[barColor setProperty:@"Set the custom solid or gradient color for the battery icon and the bar" forKey:@"footerText"];
		[self reloadSpecifier:barColor animated:YES];
	}

	_isCurrentlyDisablingSpecifiers = NO;
}

@end
