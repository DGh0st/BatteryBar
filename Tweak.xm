#import "BatteryColorPrefs.h"
#import <libcolorpicker.h>

@interface UIStatusBarNewUIStyleAttributes : NSObject
@property (nonatomic, assign) BOOL doesRequireStatusBarBackground;
@end

@interface UIStatusBarForegroundStyleAttributes : NSObject
-(id)_batteryColorForCapacity:(NSInteger)arg1 lowCapacity:(NSInteger)arg2 style:(NSUInteger)arg3; // iOS 9 - 10
-(id)_batteryColorForCapacity:(NSInteger)arg1 lowCapacity:(NSInteger)arg2 style:(NSUInteger)arg3 usingTintColor:(BOOL)arg4; // iOS 11
@end

@interface UIStatusBarNewUIForegroundStyleAttributes : UIStatusBarForegroundStyleAttributes // iOS 7 - 8
-(id)_batteryColorForCapacity:(CGFloat)arg1 lowCapacity:(CGFloat)arg2 charging:(BOOL)arg3; // iOS 7 - 8
@end

@interface UIStatusBarForegroundView : UIView
@end

@interface UIStatusBarItemView : UIView
-(UIStatusBarForegroundStyleAttributes *)foregroundStyle; // iOS 7 - 11
@end

@interface UIStatusBarBatteryItemView : UIStatusBarItemView {
	NSInteger _capacity; // iOS 4 - 11
	NSInteger _state; // iOS 4 - 11
	BOOL _batterySaverModeActive; // iOS 9 - 11
}
@property (nonatomic, retain) UIView *batteryPercentBarView;
@property (nonatomic, retain) UIView *statusBarBackgroundView;
@property (nonatomic, assign) BOOL isAnimatingCharging;
-(void)resetupBatteryPercentBarViewAnimated:(BOOL)animated;
-(void)doChargingAnimation;
-(void)updateStatusBarBackgroundViewBarHiddenAnimated:(BOOL)animated;
-(BOOL)_needsAccessoryImage; // iOS 7 - 11
-(UIImage *)_accessoryImage; // iOS 7 - 11
-(NSUInteger)cachedBatteryStyle; // iOS 10 - 11
-(NSInteger)cachedCapacity; // iOS 10 - 11
@end

@interface UIStatusBar : UIView {
	UIInterfaceOrientation _orientation; // iOS 7 - 10 (iOS 11 inherited)
}
+(NSInteger)lowBatteryLevel; // iOS 5 - 11
-(id)_currentStyleAttributes; // iOS 7 - 11
-(CGFloat)heightForOrientation:(UIInterfaceOrientation)arg1; // iOS 3 - 11
@end

@interface UIApplication (Private)
+(id)sharedApplication; // iOS 4 - 11
@end

@interface FBSystemService
+(id)sharedInstance; // iOS 8 - 11
-(void)exitAndRelaunch:(BOOL)arg1; // iOS 8 - 11
@end

@interface SpringBoard : UIApplication
-(void)_relaunchSpringBoardNow; // iOS 3 - 9
@end

// battery styles used by apple
#define kNormalBatteryStyle 0
#define kChargingBatteryStyle 1
#define kLowPowerModeBatteryStyle 2
#define kLowPowerModeAndChargingStyle 3

#define kIdentifier @"com.dgh0st.batterybar"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.batterybar.plist"
#define kSettingsChangedNotification (CFStringRef)@"com.dgh0st.batterybar/settingschanged"
#define kColorChangedNotification (CFStringRef)@"com.dgh0st.batterybar/colorchanged"
#define kRespringNotification (CFStringRef)@"com.dgh0st.batterybar/respring"

typedef enum StatusBarColorType : NSInteger {
	kDefaultStatusColor = 0,
	kAlwaysWhite,
	kAlwaysBlack
} StatusBarColorType;

typedef enum BarType : NSInteger {
	kSkinny = 0,
	kThick,
	kBackground
} BarType;

typedef enum BarAlignment : NSInteger {
	kLeft = 0,
	kCenter,
	kRight
} BarAlignment;

typedef enum BatteryColorStyle : NSInteger {
	kDefaultBatteryColor = 0,
	kSolid,
	kGradient
} BatteryColorStyle;

typedef enum ChargingAnimationStyle : NSInteger {
	kNoChargingAnimation = 0,
	kPulse
} ChargingAnimationStyle;

static BOOL isEnabled = YES;
static StatusBarColorType statusBarForegroundColor = kDefaultStatusColor;
static BOOL isHomescreenBackgroundEnabled = NO;
static BOOL isBatteryIconHidden = YES;
static BOOL isChargingIconHidden = YES;
static BarType batteryBarType = kSkinny;
static BOOL isBottomBarEnabled = NO;
static BarAlignment batteryBarAlignment = kLeft;
static BatteryColorStyle batteryColorStyle = kDefaultBatteryColor;
static CGFloat batteryBarOpacity = 1.0;
static BOOL isGradientLowPowerEnabled = NO;
static BOOL isGradientChargingEnabled = NO;
static ChargingAnimationStyle chargingAnimationStyle = kNoChargingAnimation;

static CGFloat kAnimationSpeed = 0.5;
static CGFloat kNormalBarHeight = 3.0;

%group AlwaysWhiteOrBlack
%hook UIStatusBarNewUIStyleAttributes
%property (nonatomic, assign) BOOL doesRequireStatusBarBackground;

-(id)initWithRequest:(id)arg1 backgroundColor:(id)arg2 foregroundColor:(id)arg3 {
	// change status bar color for apps and figure out if background is needed or not
	BOOL isBackgroundRequired = NO;
	NSString *appIdentifier = [NSBundle mainBundle].bundleIdentifier;
	if (appIdentifier != nil && [appIdentifier isEqualToString:@"com.apple.springboard"]) {
		isBackgroundRequired = isHomescreenBackgroundEnabled;
	} else if (arg3 != nil) {
		if (statusBarForegroundColor == kAlwaysWhite && [arg3 isEqual:[UIColor blackColor]]) {
			arg3 = [UIColor whiteColor];
			isBackgroundRequired = YES;
		} else if (statusBarForegroundColor == kAlwaysBlack && [arg3 isEqual:[UIColor whiteColor]]) {
			arg3 = [UIColor blackColor];
			isBackgroundRequired = YES;
		}
	}

	// update the saved data for this instance
	self = %orig(arg1, arg2, arg3);
	if (self != nil)
		self.doesRequireStatusBarBackground = isBackgroundRequired;
	return self;
}
%end

%hook UIStatusBar
-(void)layoutSubviews {
	// fix status bar not displaying in fullscreen videos when foreground color is always white (for some reason the status bar height is set to 0 internally)
	if (self.superview != nil && ![self.superview isKindOfClass:%c(UIStatusBarWindow)] && statusBarForegroundColor == kAlwaysWhite) {
		CGRect frame = self.frame;
		UIInterfaceOrientation _orientation = MSHookIvar<UIInterfaceOrientation>(self, "_orientation");
		frame.size.height = [self heightForOrientation:_orientation];
		self.frame = frame;
	}

	%orig();
}

-(UIColor *)foregroundColor {
	// change homescreen/lockscreen color
	UIColor *result = %orig();
	NSString *appIdentifier = [NSBundle mainBundle].bundleIdentifier;
	if (appIdentifier != nil && [appIdentifier isEqualToString:@"com.apple.springboard"]) {
		if (statusBarForegroundColor == kAlwaysWhite)
			result = [UIColor whiteColor];
		else if (statusBarForegroundColor == kAlwaysBlack)
			result = [UIColor blackColor];
	}
	return result;
}
%end
%end

%hook UIStatusBarBatteryItemView
%property (nonatomic, retain) UIView *batteryPercentBarView; // bttery bar
%property (nonatomic, retain) UIView *statusBarBackgroundView; // status bar background (only added when needed)
%property (nonatomic, assign) BOOL isAnimatingCharging; // is charging animation current running or not

-(id)initWithItem:(id)arg1 data:(id)arg2 actions:(NSInteger)arg3 style:(id)arg4 {
	self = %orig(arg1, arg2, arg3, arg4);
	if (self != nil) { // setup bar on initialization
		[self resetupBatteryPercentBarViewAnimated:NO];

		self.isAnimatingCharging = NO;
	}
	return self;
}

-(CGRect)frame {
	CGRect result = %orig();

	// hide batter or charging icon
	if (isBatteryIconHidden) {
		if (isChargingIconHidden || ![self _needsAccessoryImage])
			result.size.width = 0;
		else
			result.size.width = [self _accessoryImage].size.width;
	}

	// move status bar down for Thick type bar
	if (self.superview != nil && batteryBarType == kThick && !isBottomBarEnabled) {
		UIStatusBarForegroundView *_foregroundView = (UIStatusBarForegroundView *)self.superview;
		CGRect foregroundFrame = _foregroundView.frame;
		foregroundFrame.origin.y = kNormalBarHeight;
		_foregroundView.frame = foregroundFrame;
	}

	// to correctly hide the battery/charing icons
	self.clipsToBounds = isBatteryIconHidden || isChargingIconHidden;
	return result;
}

-(BOOL)updateForNewData:(id)arg1 actions:(NSInteger)arg2 {
	NSInteger _previousState = MSHookIvar<NSInteger>(self, "_state");
	BOOL result = %orig(arg1, arg2);
	NSInteger _newState = MSHookIvar<NSInteger>(self, "_state");
	if ((_previousState == kChargingBatteryStyle || _previousState == kLowPowerModeAndChargingStyle) && (_newState == kNormalBatteryStyle || _newState == kLowPowerModeBatteryStyle) && self.batteryPercentBarView != nil && chargingAnimationStyle != kNoChargingAnimation) // Charging -> Not Charging
		[self.batteryPercentBarView.layer removeAllAnimations];
	if (result) // only resetup bar when needed
		[self resetupBatteryPercentBarViewAnimated:YES];
	return result;
}

-(CGFloat)extraRightPadding {
	// called on rotation and initial setup
	[self resetupBatteryPercentBarViewAnimated:YES];
	return %orig();
}

-(void)layoutSubviews {
	%orig();
	// fix issues in safari where background of the status bar would disappear
	if (statusBarForegroundColor != kDefaultStatusColor)
		[self updateStatusBarBackgroundViewBarHiddenAnimated:YES];
}

%new
-(void)resetupBatteryPercentBarViewAnimated:(BOOL)animated {
	if (self.superview != nil) {
		NSInteger _capacity = [self respondsToSelector:@selector(cachedCapacity)] ? [self cachedCapacity] : MSHookIvar<NSInteger>(self, "_capacity");
		if (_capacity > 100 || _capacity < 0) { // Getting some error sometime so just get another way of finding battery level (most likely not finding capacity)
			if (![UIDevice currentDevice].batteryMonitoringEnabled)
				[UIDevice currentDevice].batteryMonitoringEnabled = YES;
			_capacity = (NSInteger)([UIDevice currentDevice].batteryLevel * 100); // iOS 5 - 11
		}
		NSInteger _state = MSHookIvar<NSInteger>(self, "_state");
		if (_state != kNormalBatteryStyle || _state != kChargingBatteryStyle) { // back up when it can't find _state
			if (![UIDevice currentDevice].batteryMonitoringEnabled)
				[UIDevice currentDevice].batteryMonitoringEnabled = YES;
			if ([UIDevice currentDevice].batteryState == UIDeviceBatteryStateCharging || [UIDevice currentDevice].batteryState == UIDeviceBatteryStateFull)
				_state = kChargingBatteryStyle; // iOS 7 - 11
			else
				_state = kNormalBatteryStyle;
		}
		NSUInteger _cachedBatteryStyle;
		if ([self respondsToSelector:@selector(cachedBatteryStyle)]) {
			_cachedBatteryStyle = [self cachedBatteryStyle];
		} else {
			NSProcessInfo *processInfo = [NSProcessInfo processInfo];
			BOOL doesDeviceSupportLowPowerMode = [processInfo respondsToSelector:@selector(isLowPowerModeEnabled)];
			BOOL _batterySaverModeActive = doesDeviceSupportLowPowerMode ? (MSHookIvar<BOOL>(self, "_batterySaverModeActive") || [processInfo isLowPowerModeEnabled]) : NO;
			_cachedBatteryStyle = _batterySaverModeActive ? kLowPowerModeBatteryStyle : _state;
		}

		if (![self.superview isKindOfClass:%c(UIStatusBarForegroundView)])
			return; // battery icon isn't part of status bar's foreground view
		UIStatusBarForegroundView *_foregroundView = (UIStatusBarForegroundView *)self.superview;
		if (_foregroundView == nil || _foregroundView.superview == nil || ![_foregroundView.superview isKindOfClass:%c(UIStatusBar)])
			return; // foreground view isn't part of status bar
		UIStatusBar *_statusBar = (UIStatusBar *)_foregroundView.superview;
		UIInterfaceOrientation _orientation = MSHookIvar<UIInterfaceOrientation>(_statusBar, "_orientation");
		CGFloat statusBarHeight = [_statusBar heightForOrientation:_orientation];

		// calculate the frame for the bar and background
		CGRect foregroundFrame = _foregroundView.frame;
		if (foregroundFrame.size.width == 0)
			return; // fix animations issues on initial launch
		CGFloat percentage = _capacity / 100.0;
		CGFloat xPosition;
		if (batteryBarAlignment == kRight)
			xPosition = foregroundFrame.size.width * (1.0 - percentage);
		else if (batteryBarAlignment == kCenter)
			xPosition = foregroundFrame.size.width * (1.0 - percentage) / 2.0;
		else
			xPosition = 0;
		CGRect barFrame;
		CGRect backgroundViewFrame;
		if (batteryBarType == kThick) {
			if (isBottomBarEnabled) {
				barFrame = CGRectMake(xPosition, statusBarHeight - kNormalBarHeight, foregroundFrame.size.width * percentage, kNormalBarHeight * 2);
				backgroundViewFrame = CGRectMake(0, 0, foregroundFrame.size.width, statusBarHeight + kNormalBarHeight);
			} else {
				barFrame = CGRectMake(xPosition, -kNormalBarHeight, foregroundFrame.size.width * percentage, kNormalBarHeight * 2);
				backgroundViewFrame = CGRectMake(0, -kNormalBarHeight, foregroundFrame.size.width, statusBarHeight + kNormalBarHeight);
			}
		} else if (batteryBarType == kBackground) {
			barFrame = CGRectMake(xPosition, 0, foregroundFrame.size.width * percentage, statusBarHeight);
			backgroundViewFrame = CGRectMake(0, 0, foregroundFrame.size.width, statusBarHeight);
		} else {
			if (isBottomBarEnabled) 
				barFrame = CGRectMake(xPosition, statusBarHeight - kNormalBarHeight, foregroundFrame.size.width * percentage, kNormalBarHeight);
			else
				barFrame = CGRectMake(xPosition, 0, foregroundFrame.size.width * percentage, kNormalBarHeight);
			backgroundViewFrame = CGRectMake(0, 0, foregroundFrame.size.width, statusBarHeight);
		}

		// create a new bar if needed
		if (self.batteryPercentBarView == nil) {
			self.batteryPercentBarView = [[UIView alloc] initWithFrame:barFrame];
			[_foregroundView insertSubview:self.batteryPercentBarView atIndex:0];
		}

		// create a status bar background view if needed
		if (self.statusBarBackgroundView == nil && statusBarForegroundColor != kDefaultStatusColor) {
			if (%c(UIVisualEffectView)) // iOS 8 - 11
				self.statusBarBackgroundView = [[UIVisualEffectView alloc] initWithFrame:backgroundViewFrame];
			else
				self.statusBarBackgroundView = [[UIView alloc] initWithFrame:backgroundViewFrame];
			[_foregroundView insertSubview:self.statusBarBackgroundView atIndex:0];
		}

		// get the color of the bar
		UIStatusBarForegroundStyleAttributes *foregroundStyle = self.foregroundStyle;
		UIColor *barColor;
		if ([foregroundStyle isKindOfClass:%c(UIStatusBarNewUIForegroundStyleAttributes)] && [foregroundStyle respondsToSelector:@selector(_batteryColorForCapacity:lowCapacity:charging:)])
			barColor = [(UIStatusBarNewUIForegroundStyleAttributes *)foregroundStyle _batteryColorForCapacity:_capacity / 100.0 lowCapacity:[%c(UIStatusBar) lowBatteryLevel] charging:(_state == kChargingBatteryStyle)];
		else if ([foregroundStyle respondsToSelector:@selector(_batteryColorForCapacity:lowCapacity:style:usingTintColor:)])
			barColor = [foregroundStyle _batteryColorForCapacity:_capacity lowCapacity:[%c(UIStatusBar) lowBatteryLevel] style:_cachedBatteryStyle usingTintColor:YES];
		else
			barColor = [foregroundStyle _batteryColorForCapacity:_capacity lowCapacity:[%c(UIStatusBar) lowBatteryLevel] style:_cachedBatteryStyle];

		// set the blur effect or color of status bar background
		if (batteryBarType == kBackground) {
			if (%c(UIVisualEffectView) && [self.statusBarBackgroundView isKindOfClass:%c(UIVisualEffectView)]) {
				if (statusBarForegroundColor == kAlwaysWhite)
					((UIVisualEffectView *)self.statusBarBackgroundView).effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
				else if (statusBarForegroundColor == kAlwaysBlack)
					((UIVisualEffectView *)self.statusBarBackgroundView).effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
			} else {
				self.statusBarBackgroundView.backgroundColor = [UIColor grayColor];
			}

			// fix bar color since it is in the background
			if (batteryColorStyle == kDefaultBatteryColor) {
				if ([barColor isEqual:[UIColor whiteColor]])
					barColor = [UIColor blackColor];
				else if ([barColor isEqual:[UIColor blackColor]])
					barColor = [UIColor whiteColor];
			}
		} else if (statusBarForegroundColor == kAlwaysWhite) {
			if (%c(UIVisualEffectView) && [self.statusBarBackgroundView isKindOfClass:%c(UIVisualEffectView)])
				((UIVisualEffectView *)self.statusBarBackgroundView).effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
			else
				self.statusBarBackgroundView.backgroundColor = [UIColor blackColor];
		} else if (statusBarForegroundColor == kAlwaysBlack) {
			if (%c(UIVisualEffectView) && [self.statusBarBackgroundView isKindOfClass:%c(UIVisualEffectView)])
				((UIVisualEffectView *)self.statusBarBackgroundView).effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
			else
				self.statusBarBackgroundView.backgroundColor = [UIColor whiteColor];
		}
		if (statusBarForegroundColor != kDefaultStatusColor) {
			[self updateStatusBarBackgroundViewBarHiddenAnimated:YES];
			self.statusBarBackgroundView.frame = backgroundViewFrame;
		}

		// set battery bar opacity if it is default status color
		if (batteryColorStyle == kDefaultBatteryColor)
			barColor = [barColor colorWithAlphaComponent:batteryBarOpacity];

		// start/stop charging animation
		if (chargingAnimationStyle != kNoChargingAnimation)
			[self doChargingAnimation];

		// animate percent change
		[UIView animateWithDuration:(animated ? kAnimationSpeed : 0.0) animations:^{
			self.batteryPercentBarView.frame = barFrame;
			self.batteryPercentBarView.backgroundColor = barColor;
		} completion:nil];
	}
}

%new
-(void)doChargingAnimation {
	if (MSHookIvar<NSInteger>(self, "_state") == kChargingBatteryStyle) {
		if (!self.isAnimatingCharging) {
			self.isAnimatingCharging = YES;
			if (chargingAnimationStyle == kPulse) {
				self.batteryPercentBarView.alpha = 1.0;
				[UIView animateWithDuration:kAnimationSpeed * 3 animations:^{
					self.batteryPercentBarView.alpha = 0.0;
				} completion:^(BOOL zeroFinished) {
					if (zeroFinished) {
						if (MSHookIvar<NSInteger>(self, "_state") == kChargingBatteryStyle) {
							[UIView animateWithDuration:kAnimationSpeed * 3 animations:^{
								self.batteryPercentBarView.alpha = 1.0;
							} completion:^(BOOL oneFinished) {
								if (!oneFinished)
									self.batteryPercentBarView.alpha = 1.0;
								self.isAnimatingCharging = NO;
								[self doChargingAnimation];
							}];
						} else {
							self.isAnimatingCharging = NO;
							self.batteryPercentBarView.alpha = 1.0;
						}
					} else {
						self.batteryPercentBarView.alpha = 1.0;
						self.isAnimatingCharging = NO;
						[self doChargingAnimation];
					}
				}];
			}
		}
	}
}

%new
-(void)updateStatusBarBackgroundViewBarHiddenAnimated:(BOOL)animated {
	UIStatusBarForegroundView *_foregroundView = (UIStatusBarForegroundView *)self.superview;
	if (_foregroundView == nil)
		return;
	UIStatusBar *_statusBar = (UIStatusBar *)_foregroundView.superview;
	if (_statusBar == nil)
		return;
	UIStatusBarNewUIStyleAttributes *_currentStyleAttributes = [_statusBar _currentStyleAttributes];
	BOOL shouldHideBackground = NO;
	if (_currentStyleAttributes != nil && [_currentStyleAttributes respondsToSelector:@selector(doesRequireStatusBarBackground)])
		shouldHideBackground = ![_currentStyleAttributes doesRequireStatusBarBackground];

	if (animated)
		[UIView animateWithDuration:kAnimationSpeed animations:^{
			self.statusBarBackgroundView.hidden = shouldHideBackground;
		} completion:nil];
	else
		self.statusBarBackgroundView.hidden = shouldHideBackground;
}

-(void)dealloc {
	if (self.batteryPercentBarView != nil) {
		[self.batteryPercentBarView release];
		self.batteryPercentBarView = nil;
	}

	if (self.statusBarBackgroundView != nil) {
		[self.statusBarBackgroundView release];
		self.statusBarBackgroundView = nil;
	}

	%orig();
}
%end

%group CustomBatteryColors
static UIColor *getColorForCapacity(NSInteger capacity, NSInteger lowCapacity, NSUInteger style) {
	UIColor *result = nil;
	BatteryColorPrefs *colorPrefs = [BatteryColorPrefs sharedInstance];
	if (batteryColorStyle == kSolid) {
		if (style == kLowPowerModeBatteryStyle || style == kLowPowerModeAndChargingStyle) { // yellow-orange battery (Low Power Mode)
			result = [LCPParseColorString(colorPrefs.solidLowPowerModeColor, colorPrefs.solidLowPowerModeColor) retain];
		} else if (style == kChargingBatteryStyle) { // green battery (Charging Mode)
			result = [LCPParseColorString(colorPrefs.solidChargingColor, colorPrefs.solidChargingColor) retain];
		} else if (style == kNormalBatteryStyle) { // Normal Mode
			if (capacity <= lowCapacity) // red battery
				result = [LCPParseColorString(colorPrefs.solidLessThan20Color, colorPrefs.solidLessThan20Color) retain];
			else // white or black battery
				result = [LCPParseColorString(colorPrefs.solidGreaterThan20Color, colorPrefs.solidGreaterThan20Color) retain];
		}
	} else if (batteryColorStyle == kGradient) {
		if (isGradientLowPowerEnabled && (style == kLowPowerModeBatteryStyle || style == kLowPowerModeAndChargingStyle)) {
			result = [LCPParseColorString(colorPrefs.gradientLowPowerModeColor, colorPrefs.gradientLowPowerModeColor) retain];
		} else if (isGradientChargingEnabled && (style == kChargingBatteryStyle || style == kLowPowerModeAndChargingStyle)) {
			result = [LCPParseColorString(colorPrefs.gradientChargingColor, colorPrefs.gradientChargingColor) retain];
		} else {
			NSInteger colorOffset = capacity / 5; // get color within 5% ranges
			if (colorOffset < 0)
				colorOffset = 0;
			else if (colorOffset > [colorPrefs.gradientColor count])
				colorOffset = [colorPrefs.gradientColor count] - 1;
			result = [LCPParseColorString([colorPrefs.gradientColor objectAtIndex:colorOffset], [colorPrefs.defaultGradientColor objectAtIndex:colorOffset]) retain];
		}
	}
	return result;
}

%hook UIStatusBarForegroundStyleAttributes
-(id)_batteryColorForCapacity:(NSInteger)arg1 lowCapacity:(NSInteger)arg2 style:(NSUInteger)arg3 {
	id result = %orig(arg1, arg2, arg3);
	UIColor *newColor = getColorForCapacity(arg1, arg2, arg3);
	if (newColor != nil)
		result = newColor;
	return result;
}

-(id)_batteryColorForCapacity:(NSInteger)arg1 lowCapacity:(NSInteger)arg2 style:(NSUInteger)arg3 usingTintColor:(BOOL)arg4 {
	id result = %orig(arg1, arg2, arg3, arg4);
	UIColor *newColor = getColorForCapacity(arg1, arg2, arg3);
	if (newColor != nil)
		result = newColor;
	return result;
}
%end

%hook UIStatusBarNewUIForegroundStyleAttributes
-(id)_batteryColorForCapacity:(CGFloat)arg1 lowCapacity:(CGFloat)arg2 charging:(BOOL)arg3 {
	id result = %orig(arg1, arg2, arg3);
	UIColor *newColor;
	if (arg1 <= 1.0 && arg2 < 1.0)
		newColor = getColorForCapacity(arg1 * 100, arg2 * 100, arg3 ? kChargingBatteryStyle : kNormalBatteryStyle);
	else
		newColor = getColorForCapacity(arg1, arg2, arg3 ? kChargingBatteryStyle : kNormalBatteryStyle);
	if (newColor != nil)
		result = newColor;
	return result;
}
%end
%end

static void reloadPrefs() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);

	NSDictionary *prefs = nil;
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList != nil) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (prefs == nil)
				prefs = [NSDictionary dictionary];
			CFRelease(keyList);
		}
	} else {
		prefs = [NSDictionary dictionaryWithContentsOfFile:kSettingsPath];
	}

	isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;

	statusBarForegroundColor = [prefs objectForKey:@"statusBarForegroundColor"] ? (StatusBarColorType)[[prefs objectForKey:@"statusBarForegroundColor"] intValue] : kDefaultStatusColor;
	isHomescreenBackgroundEnabled = [prefs objectForKey:@"isHomescreenBackgroundEnabled"] ? [[prefs objectForKey:@"isHomescreenBackgroundEnabled"] boolValue] : NO;
	isBatteryIconHidden = [prefs objectForKey:@"isBatteryIconHidden"] ? [[prefs objectForKey:@"isBatteryIconHidden"] boolValue] : YES;
	isChargingIconHidden = [prefs objectForKey:@"isChargingIconHidden"] ? [[prefs objectForKey:@"isChargingIconHidden"] boolValue] : YES;
	batteryBarType = [prefs objectForKey:@"batteryBarType"] ? (BarType)[[prefs objectForKey:@"batteryBarType"] intValue] : kSkinny;
	isBottomBarEnabled = [prefs objectForKey:@"isBottomBarEnabled"] ? [[prefs objectForKey:@"isBottomBarEnabled"] boolValue] : NO;
	batteryBarAlignment = [prefs objectForKey:@"batteryBarAlignment"] ? (BarAlignment)[[prefs objectForKey:@"batteryBarAlignment"] intValue] : kLeft;
	batteryColorStyle = [prefs objectForKey:@"batteryColorStyle"] ? (BatteryColorStyle)[[prefs objectForKey:@"batteryColorStyle"] intValue] : kDefaultBatteryColor;
	batteryBarOpacity = [prefs objectForKey:@"batteryBarOpacity"] ? (CGFloat)[[prefs objectForKey:@"batteryBarOpacity"] floatValue] : 1.0;
	isGradientLowPowerEnabled = [prefs objectForKey:@"isGradientLowPowerEnabled"] ? [[prefs objectForKey:@"isGradientLowPowerEnabled"] boolValue] : NO;
	isGradientChargingEnabled = [prefs objectForKey:@"isGradientChargingEnabled"] ? [[prefs objectForKey:@"isGradientChargingEnabled"] boolValue] : NO;
	chargingAnimationStyle = [prefs objectForKey:@"chargingAnimationStyle"] ? (ChargingAnimationStyle)[[prefs objectForKey:@"chargingAnimationStyle"] intValue] : kNoChargingAnimation;

	kAnimationSpeed = [prefs objectForKey:@"animationSpeed"] ? (CGFloat)[[prefs objectForKey:@"animationSpeed"] floatValue] : 0.5;
	kNormalBarHeight = [prefs objectForKey:@"barHeight"] ? (CGFloat)[[prefs objectForKey:@"barHeight"] floatValue] : 3.0;

	[[BatteryColorPrefs sharedInstance] updatePreferences]; // update color prefs
}

static void reloadColorPrefs() {
	[[BatteryColorPrefs sharedInstance] updatePreferences]; // update color prefs
}

static void respringDevice() {
	if (%c(FBSystemService))
		[[%c(FBSystemService) sharedInstance] exitAndRelaunch:YES];
	else if ([[%c(SpringBoard) sharedApplication] respondsToSelector:@selector(_relaunchSpringBoardNow)])
		[[%c(SpringBoard) sharedApplication] _relaunchSpringBoardNow];
}

/*%dtor {
	// causes crashes for some reason when launching some apps (i.e Amazon)
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kSettingsChangedNotification, NULL);
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kColorChangedNotification, NULL);
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kRespringNotification, NULL);
}*/

%ctor {
	reloadPrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadPrefs, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)reloadColorPrefs, kColorChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

	// Only initialize tweak if it is enabled and if the current process is homescreen or an app
	NSArray *args = [[NSProcessInfo processInfo] arguments];
	if (args != nil && args.count != 0) {
		NSString *execPath = args[0];
		if (execPath) {
			BOOL isSpringBoard = [[execPath lastPathComponent] isEqualToString:@"SpringBoard"];
			BOOL isApplication = [execPath rangeOfString:@"/Application"].location != NSNotFound;
			if ((isSpringBoard || isApplication) && isEnabled) {
				%init();

				// inject portions as needed (optomize performance slightly)
				if (statusBarForegroundColor != kDefaultStatusColor)
					%init(AlwaysWhiteOrBlack);

				if (batteryColorStyle != kDefaultBatteryColor)
					%init(CustomBatteryColors);
			}

			if (isSpringBoard)
				CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)respringDevice, kRespringNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		}
	}
}