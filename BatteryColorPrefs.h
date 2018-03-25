@interface BatteryColorPrefs : NSObject
@property (nonatomic, retain) NSString *solidLowPowerModeColor;
@property (nonatomic, retain) NSString *solidChargingColor;
@property (nonatomic, retain) NSString *solidLessThan20Color;
@property (nonatomic, retain) NSString *solidGreaterThan20Color;
@property (nonatomic, retain) NSString *gradientLowPowerModeColor;
@property (nonatomic, retain) NSString *gradientChargingColor;
@property (nonatomic, retain) NSArray *gradientColor;
@property (nonatomic, retain) NSArray *defaultGradientColor;
+(BatteryColorPrefs *)sharedInstance;
-(void)updatePreferences;
@end
