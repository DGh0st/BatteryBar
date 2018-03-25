#include "BBGradientListController.h"

@implementation BBGradientListController

- (id)initForContentSize:(CGSize)size {
	self = [super initForContentSize:size];
	if (self != nil)
		_isCurrentlyDisablingSpecifiers = NO;
	return self;
}

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Gradient" target:self] retain];
	}
	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
	[self clearCache];
	[self reload];
	[super viewWillAppear:animated];
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

	if ([self specifierForID:@"LowPowerColor"] != nil)
		_gradientLowPowerModeColorSpecifier = [self specifierForID:@"LowPowerColor"];
	if ([self specifierForID:@"ChargingColor"] != nil)
		_gradientChargingColorSpecifier = [self specifierForID:@"ChargingColor"];

	// Add/Remove the low power mode color specifier
	if (_gradientLowPowerModeColorSpecifier != nil) {
		PSSpecifier *lowPowerSwitchSpecifier = [self specifierForID:@"LowPowerSwitch"];
		id lowPowerSwitchValue = [self readPreferenceValue:lowPowerSwitchSpecifier];
		if ([lowPowerSwitchValue boolValue]) {
			if (![self containsSpecifier:_gradientLowPowerModeColorSpecifier]) {
				[self insertSpecifier:_gradientLowPowerModeColorSpecifier afterSpecifier:lowPowerSwitchSpecifier animated:animated];
				[_gradientLowPowerModeColorSpecifier release];
			}
		} else {
			if ([self containsSpecifier:_gradientLowPowerModeColorSpecifier])
				[self removeSpecifier:[_gradientLowPowerModeColorSpecifier retain] animated:animated];
		}
	}

	// Add/Remove the charging color specifier
	if (_gradientChargingColorSpecifier != nil) {
		PSSpecifier *chargingSwitchSpecifier = [self specifierForID:@"ChargingSwitch"];
		id chargingSwitchValue = [self readPreferenceValue:chargingSwitchSpecifier];
		if ([chargingSwitchValue boolValue]) {
			if (![self containsSpecifier:_gradientChargingColorSpecifier]) {
				[self insertSpecifier:_gradientChargingColorSpecifier afterSpecifier:chargingSwitchSpecifier animated:animated];
				[_gradientChargingColorSpecifier release];
			}
		} else {
			if ([self containsSpecifier:_gradientChargingColorSpecifier])
				[self removeSpecifier:[_gradientChargingColorSpecifier retain] animated:animated];
		}
	}

	_isCurrentlyDisablingSpecifiers = NO;
}

@end