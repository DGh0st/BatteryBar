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

-(void)dealloc {
	[self clearPreviousSpecifiers];

	[super dealloc];
}

- (void)reloadSpecifiers {
	[super reloadSpecifiers];

	[self removeSpecifiersIfNeededAnimated:[NSNumber numberWithBool:NO]];
}

- (void)clearPreviousSpecifiers {
	if (_bottomBarSpecifier != nil)
		[_bottomBarSpecifier release];
	_bottomBarSpecifier = nil;
	if (_barHeightSpecifier != nil)
		[_barHeightSpecifier release];
	_barHeightSpecifier = nil;
	if (_hideChargingIconSpecifier != nil)
		[_hideChargingIconSpecifier release];
	_hideChargingIconSpecifier = nil;
	if (_homescreenBackgroundSpecifier != nil)
		[_homescreenBackgroundSpecifier release];
	_homescreenBackgroundSpecifier = nil;
	if (_customSolidBatteryColor != nil)
		[_customSolidBatteryColor release];
	_customSolidBatteryColor = nil;
	if (_customGradientBatteryColor != nil)
		[_customGradientBatteryColor release];
	_customGradientBatteryColor = nil;
	if (_batteryBarOpacity != nil)
		[_batteryBarOpacity release];
	_batteryBarOpacity = nil;
}

- (void)removeSpecifiersIfNeededAnimated:(NSNumber *)animatedObject {
	BOOL animated = [animatedObject boolValue];

	_isCurrentlyDisablingSpecifiers = YES;

	PSSpecifier *bottomBarSpecifier = [self specifierForID:@"BottomBar"];
	PSSpecifier *barHeightSpecifier = [self specifierForID:@"BarHeight"];
	PSSpecifier *hideChargingIconSpecifier = [self specifierForID:@"HideChargingIcon"];
	PSSpecifier *homescreenBackgroundSpecifier = [self specifierForID:@"HomescreenBackground"];
	PSSpecifier *customSolidBatteryColor = [self specifierForID:@"CustomSolidBatteryColor"];
	PSSpecifier *customGradientBatteryColor = [self specifierForID:@"CustomGradientBatteryColor"];
	PSSpecifier *batteryBarOpacity = [self specifierForID:@"BarOpacity"];

	// Add/Remove the bottom bar switch and bar height slider
	PSSpecifier *batteryBarTypeSpecifier = [self specifierForID:@"BarType"];
	PSSpecifier *type = [self specifierForID:@"Type"];
	id batteryBarTypeValue = [self readPreferenceValue:batteryBarTypeSpecifier];
	if ([batteryBarTypeValue intValue] == 2) {
		if (bottomBarSpecifier != nil && [self containsSpecifier:bottomBarSpecifier]) {
			[self setPreferenceValue:@NO specifier:bottomBarSpecifier];
			_bottomBarSpecifier = [bottomBarSpecifier retain];
			[self removeSpecifier:_bottomBarSpecifier animated:animated];
		}
		if (barHeightSpecifier != nil && [self containsSpecifier:barHeightSpecifier]) {
			_barHeightSpecifier = [barHeightSpecifier retain];
			[self removeSpecifier:_barHeightSpecifier animated:animated];
		}
		[type setProperty:@"" forKey:@"footerText"];
		[self reloadSpecifier:type animated:animated];
	} else {
		if (_barHeightSpecifier != nil && ![self containsSpecifier:_barHeightSpecifier]) {
			[self insertSpecifier:_barHeightSpecifier afterSpecifier:batteryBarTypeSpecifier];
			[_barHeightSpecifier release];
			_barHeightSpecifier = nil;
		}
		if (_bottomBarSpecifier != nil && ![self containsSpecifier:_bottomBarSpecifier]) {
			[self insertSpecifier:_bottomBarSpecifier afterSpecifier:batteryBarTypeSpecifier];
			[_bottomBarSpecifier release];
			_bottomBarSpecifier = nil;
		}

		if ([batteryBarTypeValue intValue] == 0) // skinny
			[type setProperty:@"Set the height of the bar" forKey:@"footerText"];
		else if ([batteryBarTypeValue intValue] == 1) // thick
			[type setProperty:@"Set the height of the bar (Thick type will make the bar twice as big and move down the status bar by the height)" forKey:@"footerText"];
		else
			[type setProperty:@"" forKey:@"footerText"];
		[self reloadSpecifier:type animated:animated];
	}


	// Add/Remove the battery/charging icon switches
	PSSpecifier *hideBatteryIconSpecifier = [self specifierForID:@"HideBatteryIcon"];
	id batteryIconValue = [self readPreferenceValue:hideBatteryIconSpecifier];
	if (![batteryIconValue boolValue]) {
		if (hideChargingIconSpecifier != nil && [self containsSpecifier:hideChargingIconSpecifier]) {
			[self setPreferenceValue:@NO specifier:hideChargingIconSpecifier];
			_hideChargingIconSpecifier = [hideChargingIconSpecifier retain];
			[self removeSpecifier:_hideChargingIconSpecifier animated:animated];
		}
	} else if (_hideChargingIconSpecifier != nil && ![self containsSpecifier:_hideChargingIconSpecifier]) {
		[self insertSpecifier:_hideChargingIconSpecifier afterSpecifier:hideBatteryIconSpecifier animated:animated];
		[_hideChargingIconSpecifier release];
		_hideChargingIconSpecifier = nil;
	}

	// Add/Remove the status bar color and homescreen background specifiers
	PSSpecifier *colorStatusBarSpecifier = [self specifierForID:@"ColorStatusBar"];
	id statusBarStyleValue = [self readPreferenceValue:colorStatusBarSpecifier];
	if ([statusBarStyleValue intValue] == 0) { // Default Status Bar Style
		if (homescreenBackgroundSpecifier != nil && [self containsSpecifier:homescreenBackgroundSpecifier]) {
			[self setPreferenceValue:@NO specifier:homescreenBackgroundSpecifier];
			_homescreenBackgroundSpecifier = [homescreenBackgroundSpecifier retain];
			[self removeSpecifier:_homescreenBackgroundSpecifier animated:animated];
		}
	} else if (_homescreenBackgroundSpecifier != nil && ![self containsSpecifier:_homescreenBackgroundSpecifier]) {
		[self insertSpecifier:_homescreenBackgroundSpecifier afterSpecifier:colorStatusBarSpecifier animated:animated];
		[_homescreenBackgroundSpecifier release];
		_homescreenBackgroundSpecifier = nil;
	}

	// Add/Remove the colors sub-preferences
	PSSpecifier *batteryColorSpecifier = [self specifierForID:@"BatteryColor"];
	PSSpecifier *barColor = [self specifierForID:@"BarColor"];
	id batteryColorStyleValue = [self readPreferenceValue:batteryColorSpecifier];
	if ([batteryColorStyleValue intValue] == 0) {
		if (_batteryBarOpacity != nil && ![self containsSpecifier:_batteryBarOpacity]) {
			if (animated) {
				if (customSolidBatteryColor != nil && [self containsSpecifier:customSolidBatteryColor]) {
					_customSolidBatteryColor = [customSolidBatteryColor retain];
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:_customSolidBatteryColor, nil] withSpecifiers:[NSArray arrayWithObjects:_batteryBarOpacity, nil] animated:YES];
				} else if (customGradientBatteryColor != nil && [self containsSpecifier:customGradientBatteryColor]) {
					_customGradientBatteryColor = [customGradientBatteryColor retain];
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:_customGradientBatteryColor, nil] withSpecifiers:[NSArray arrayWithObjects:_batteryBarOpacity, nil] animated:YES];
				}
			} else {
				[self insertSpecifier:_batteryBarOpacity afterSpecifier:batteryColorSpecifier animated:animated];
			}
			[_batteryBarOpacity release];
			_batteryBarOpacity = nil;
		} else {
			if (customSolidBatteryColor != nil && [self containsSpecifier:customSolidBatteryColor]) {
				_customSolidBatteryColor = [customSolidBatteryColor retain];
				[self removeSpecifier:_customSolidBatteryColor animated:animated];
			}
			if (customGradientBatteryColor != nil && [self containsSpecifier:customGradientBatteryColor]) {
				_customGradientBatteryColor = [customGradientBatteryColor retain];
				[self removeSpecifier:_customGradientBatteryColor animated:animated];
			}
		}
		[barColor setProperty:@"Set the opacity of the batter bar" forKey:@"footerText"];
		[self reloadSpecifier:barColor animated:animated];
	} else if ([batteryColorStyleValue intValue] == 1) {
		if (_customSolidBatteryColor != nil && ![self containsSpecifier:_customSolidBatteryColor]) {
			if (animated) {
				if (batteryBarOpacity != nil && [self containsSpecifier:batteryBarOpacity]) {
					_batteryBarOpacity = [batteryBarOpacity retain];
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:_batteryBarOpacity, nil] withSpecifiers:[NSArray arrayWithObjects:_customSolidBatteryColor, nil] animated:YES];
				} else if (customGradientBatteryColor != nil && [self containsSpecifier:customGradientBatteryColor]) {
					_customGradientBatteryColor = [customGradientBatteryColor retain];
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:_customGradientBatteryColor, nil] withSpecifiers:[NSArray arrayWithObjects:_customSolidBatteryColor, nil] animated:YES];
				}
			} else {
				[self insertSpecifier:_customSolidBatteryColor afterSpecifier:batteryColorSpecifier animated:animated];
			}
			[_customSolidBatteryColor release];
			_customSolidBatteryColor = nil;
		} else {
			if (batteryBarOpacity != nil && [self containsSpecifier:batteryBarOpacity]) {
				_batteryBarOpacity = [batteryBarOpacity retain];
				[self removeSpecifier:_batteryBarOpacity animated:animated];
			}
			if (customGradientBatteryColor != nil && [self containsSpecifier:customGradientBatteryColor]) {
				_customGradientBatteryColor = [customGradientBatteryColor retain];
				[self removeSpecifier:_customGradientBatteryColor animated:animated];
			}
		}
		[barColor setProperty:@"Set the custom solid color for the battery icon and the bar" forKey:@"footerText"];
		[self reloadSpecifier:barColor animated:animated];
	} else if ([batteryColorStyleValue intValue] == 2) {
		if (_customGradientBatteryColor != nil && ![self containsSpecifier:_customGradientBatteryColor]) {
			if (animated) {
				if (batteryBarOpacity != nil && [self containsSpecifier:batteryBarOpacity]) {
					_batteryBarOpacity = [batteryBarOpacity retain];
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:_batteryBarOpacity, nil] withSpecifiers:[NSArray arrayWithObjects:_customGradientBatteryColor, nil] animated:YES];
				} else if (customSolidBatteryColor != nil && [self containsSpecifier:customSolidBatteryColor]) {
					_customSolidBatteryColor = [customSolidBatteryColor retain];
					[self replaceContiguousSpecifiers:[NSArray arrayWithObjects:_customSolidBatteryColor, nil] withSpecifiers:[NSArray arrayWithObjects:_customGradientBatteryColor, nil] animated:YES];
				}
			} else {
				[self insertSpecifier:_customGradientBatteryColor afterSpecifier:batteryColorSpecifier animated:animated];
			}
			[_customGradientBatteryColor release];
			_customGradientBatteryColor = nil;
		} else {
			if (batteryBarOpacity != nil && [self containsSpecifier:batteryBarOpacity]) {
				_batteryBarOpacity = [batteryBarOpacity retain];
				[self removeSpecifier:_batteryBarOpacity animated:animated];
			}
			if (customSolidBatteryColor != nil && [self containsSpecifier:customSolidBatteryColor]) {
				_customSolidBatteryColor = [customSolidBatteryColor retain];
				[self removeSpecifier:_customSolidBatteryColor animated:animated];
			}
		}
		[barColor setProperty:@"Set the custom gradient color for the battery icon and the bar" forKey:@"footerText"];
		[self reloadSpecifier:barColor animated:animated];
	}

	_isCurrentlyDisablingSpecifiers = NO;
}

@end
