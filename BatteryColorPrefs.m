#import "BatteryColorPrefs.h"

#define kColorPath @"/var/mobile/Library/Preferences/com.dgh0st.batterybar.color.plist"

@implementation BatteryColorPrefs
+(BatteryColorPrefs *)sharedInstance {
	static BatteryColorPrefs *sharedObject = nil;
	static dispatch_once_t token = 0;
	dispatch_once(&token, ^{
		sharedObject = [self new];
	});
	return sharedObject;
}

-(id)init {
	self = [super init];
	if (self != nil) {
		self.solidLowPowerModeColor = @"#FFD700";
		self.solidChargingColor = @"#00FF00";
		self.solidLessThan20Color = @"#FF0000";
		self.solidGreaterThan20Color = @"#808080";

		self.gradientLowPowerModeColor = @"#FFD700";
		self.gradientChargingColor = @"00FF00";
		self.defaultGradientColor = [NSArray arrayWithObjects:@"#FF0500", @"#FF1E00", @"#FF3700", @"#FF5000", @"#FF6900", @"#FF8200", @"#FF9B00", @"#FFB400", @"#FFCD00", @"#FFE600", @"#FFFF00", @"#E6FF00", @"#CDFF00", @"#B4FF00", @"#9BFF00", @"#82FF00", @"#69FF00", @"#50FF00", @"#37FF00", @"#1EFF00", @"#00FF00", nil];
		self.gradientColor = self.defaultGradientColor;

		[self updatePreferences];
	}
	return self;
}

-(void)updatePreferences {
	NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kColorPath];

	self.solidLowPowerModeColor = [preferences objectForKey:@"solidColorLowPower"] ?: @"#FFD700";
	self.solidChargingColor = [preferences objectForKey:@"solidColorCharging"] ?: @"#00FF00";
	self.solidLessThan20Color = [preferences objectForKey:@"solidColorLessThan20"] ?: @"#FF0000";
	self.solidGreaterThan20Color = [preferences objectForKey:@"solidColorGreaterThan20"] ?: @"#808080";

	self.gradientLowPowerModeColor = [preferences objectForKey:@"gradientColorLowPower"] ?: @"#FFD700";
	self.gradientChargingColor = [preferences objectForKey:@"gradientColorCharging"] ?: @"00FF00";
	self.gradientColor = [NSMutableArray arrayWithCapacity:[self.defaultGradientColor count]];
	for (NSUInteger i = 0; i < [self.defaultGradientColor count]; i++) {
		NSString *key = [NSString stringWithFormat:@"gradientColor%zd", i];
		NSString *currentGradientColor = [preferences objectForKey:key] ?: [self.defaultGradientColor objectAtIndex:i];
		[((NSMutableArray *)self.gradientColor) insertObject:currentGradientColor atIndex:i];
	}
}
@end