#include "DVirtualHome.h"

static void preferencesChanged() {
	CFPreferencesAppSynchronize((CFStringRef)kIdentifier);

	NSDictionary *prefs = nil;
	if ([NSHomeDirectory() isEqualToString:@"/var/mobile"]) {
		CFArrayRef keyList = CFPreferencesCopyKeyList((CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		if (keyList) {
			prefs = (NSDictionary *)CFPreferencesCopyMultiple(keyList, (CFStringRef)kIdentifier, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			if (!prefs) {
				prefs = [NSDictionary new];
			}
			CFRelease(keyList);
		}
	} else {
		prefs = [[NSDictionary alloc] initWithContentsOfFile:kSettingsPath];
	}

	if (prefs) {
		isEnabled = [prefs objectForKey:@"isEnabled"] ? [[prefs objectForKey:@"isEnabled"] boolValue] : YES;
		singleTapAction = [prefs objectForKey:@"singleTapAction"] ? (Action)[[prefs objectForKey:@"singleTapAction"] intValue] : home;
		doubleTapAction = [prefs objectForKey:@"doubleTapAction"] ? (Action)[[prefs objectForKey:@"doubleTapAction"] intValue] : switcher;
		longHoldAction =  [prefs objectForKey:@"longHoldAction"] ? (Action)[[prefs objectForKey:@"longHoldAction"] intValue] : reachability;
		tapAndHoldAction =  [prefs objectForKey:@"tapAndHoldAction"] ? (Action)[[prefs objectForKey:@"tapAndHoldAction"] intValue] : siri;
		isVibrationEnabled =  [prefs objectForKey:@"isVibrationEnabled"] ? [[prefs objectForKey:@"isVibrationEnabled"] boolValue] : YES;
		vibrationIntensity =  [prefs objectForKey:@"vibrationIntensity"] ? [[prefs objectForKey:@"vibrationIntensity"] floatValue] : 0.75;
		vibrationDuration =  [prefs objectForKey:@"vibrationDuration"] ? [[prefs objectForKey:@"vibrationDuration"] intValue] : 30;
	}
	[prefs release];

}

static void hapticVibe() {
	NSMutableDictionary *vibDict = [NSMutableDictionary dictionary];
	NSMutableArray *vibArr = [NSMutableArray array];
	[vibArr addObject:[NSNumber numberWithBool:YES]];
	[vibArr addObject:[NSNumber numberWithInt:vibrationDuration]]; // duration
	[vibDict setObject:vibArr forKey:@"VibePattern"];
	[vibDict setObject:[NSNumber numberWithFloat:vibrationIntensity] forKey:@"Intensity"];
	AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, vibDict);
}

// iOS 13+ doesn't currently support disableActions
static BOOL disableActions = NO;

%hook SBDashBoardViewController
-(void)handleBiometricEvent:(NSUInteger)arg1 {
	%orig(arg1);

	// Touch Up or Down
	disableActions = arg1 != 0 && arg1 != 1;

	/*if (isEnabled && arg1 == 1 && isVibrationEnabled) { // Down
		hapticVibe();
	}*/
}
%end

static inline void lockOrUnlockOrientation(UIInterfaceOrientation orientation) {
	SBOrientationLockManager *orientationLockManager = [%c(SBOrientationLockManager) sharedInstance];
	if ([orientationLockManager isUserLocked]) {
		[orientationLockManager unlock];
	} else {
		[orientationLockManager lock:orientation];
	}
}

static NSString *lastApplicationIdentifier = nil;
static NSString *currentApplicationIdentifier = nil;

// The last app feature was copied from LastApp (https://github.com/ashikase/LastApp/ and Tateu's fork)
%hook SpringBoard
%property (nonatomic, retain) NSString *lastApplicationIdentifier;
%property (nonatomic, retain) NSString *currentApplicationIdentifier;

-(void)frontDisplayDidChange:(id)arg1 {
	%orig;

	if (arg1 != nil && [arg1 isKindOfClass:%c(SBApplication)]) {
		NSString *newBundleIdentifier = [(SBApplication *)arg1 bundleIdentifier];
		if (![currentApplicationIdentifier isEqualToString:newBundleIdentifier]) {
			lastApplicationIdentifier = currentApplicationIdentifier;
			currentApplicationIdentifier = newBundleIdentifier;
		}
	}
}
%end

%hook SBHomeHardwareButtonGestureRecognizerConfiguration
%property(retain,nonatomic) UIHBClickGestureRecognizer *singleTapGestureRecognizer;
%property(retain,nonatomic) UILongPressGestureRecognizer *longTapGestureRecognizer;
%property(retain,nonatomic) UILongPressGestureRecognizer *tapAndHoldTapGestureRecognizer;
%property(retain,nonatomic) UILongPressGestureRecognizer *vibrationGestureRecognizer;

-(void)dealloc {
	[self.singleTapGestureRecognizer release];
	self.singleTapGestureRecognizer = nil;
	[self.longTapGestureRecognizer release];
	self.longTapGestureRecognizer = nil;
	[self.tapAndHoldTapGestureRecognizer release];
	self.tapAndHoldTapGestureRecognizer = nil;
	[self.vibrationGestureRecognizer release];
	self.vibrationGestureRecognizer = nil;
	%orig;
}
%end

%hook SBHomeHardwareButton
%new
-(void)performAction:(Action)action {
	if (disableActions)
		return; // do nothing since we are in middle of authentication

	if (action == home || ![[%c(SBBacklightController) sharedInstance] screenIsOn]) {
		[(SpringBoard *)[UIApplication sharedApplication] _simulateHomeButtonPress];
	} else if (action == lock) {
		[(SpringBoard *)[UIApplication sharedApplication] _simulateLockButtonPress];
	} else if (action == switcher) {
		id topDisplay = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityTopDisplay];
		if (![topDisplay isKindOfClass:%c(SBPowerDownController)] && ![topDisplay isKindOfClass:%c(SBPowerDownViewController)] && ![topDisplay isKindOfClass:%c(SBDashBoardViewController)] && ![topDisplay isKindOfClass:%c(CSCoverSheetViewController)] && (%c(SBCoverSheetPresentationManager) == nil || [[%c(SBCoverSheetPresentationManager) sharedInstance] hasBeenDismissedSinceKeybagLock])) {
			SBMainSwitcherViewController *mainSwitcherViewController = [%c(SBMainSwitcherViewController) sharedInstance];
			if ([mainSwitcherViewController respondsToSelector:@selector(toggleSwitcherNoninteractively)])
				[mainSwitcherViewController toggleSwitcherNoninteractively];
			else if ([mainSwitcherViewController respondsToSelector:@selector(toggleSwitcherNoninteractivelyWithSource:)])
				[mainSwitcherViewController toggleSwitcherNoninteractivelyWithSource:1];
			else if ([mainSwitcherViewController respondsToSelector:@selector(toggleMainSwitcherNoninteractivelyWithSource:animated:)])
				[mainSwitcherViewController toggleMainSwitcherNoninteractivelyWithSource:1 animated:YES];
		}
	} else if (action == reachability) {
		[[%c(SBReachabilityManager) sharedInstance] toggleReachability];
	} else if (action == siri) {
		SBAssistantController *_assistantController = [%c(SBAssistantController) sharedInstance];
		if ([%c(SBAssistantController) respondsToSelector:@selector(isAssistantVisible)]) {
			if ([%c(SBAssistantController) isAssistantVisible]) {
				[_assistantController dismissPluginForEvent:1];
			} else {
				[_assistantController handleSiriButtonDownEventFromSource:1 activationEvent:1];
				[_assistantController handleSiriButtonUpEventFromSource:1];
			}
		} else if ([%c(SBAssistantController) respondsToSelector:@selector(isVisible)]) {
			if ([%c(SBAssistantController) isVisible]) {
				[_assistantController dismissAssistantViewIfNecessary];
			} else {
				SiriPresentationSpringBoardMainScreenViewController *presentation = MSHookIvar<SiriPresentationSpringBoardMainScreenViewController *>(_assistantController, "_mainScreenSiriPresentation");

				SiriPresentationOptions *presentationOptions = [[%c(SiriPresentationOptions) alloc] init];
				presentationOptions.wakeScreen = YES;
				presentationOptions.hideOtherWindowsDuringAppearance = NO;

				SASRequestOptions *requestOptions = [[%c(SASRequestOptions) alloc] initWithRequestSource:1 uiPresentationIdentifier:@"com.apple.siri.Siriland"];
				requestOptions.buttonDownTimestamp = requestOptions.timestamp;

				AFApplicationInfo *applicationInfo = [[%c(AFApplicationInfo) alloc] initWithCoder:nil];
				applicationInfo.pid = [NSProcessInfo processInfo].processIdentifier;
				applicationInfo.identifier = [NSBundle mainBundle].bundleIdentifier;
				requestOptions.contextAppInfosForSiriViewController = @[applicationInfo];

				[presentation presentationRequestedWithPresentationOptions:presentationOptions requestOptions:requestOptions];

				[presentationOptions release];
				[requestOptions release];
				[applicationInfo release];
			}
		}
	} else if (action == screenshot) {
		SpringBoard *_springboard = (SpringBoard *)[UIApplication sharedApplication];
		if ([_springboard respondsToSelector:@selector(takeScreenshot)])
			[_springboard takeScreenshot];
		else
			[[_springboard screenshotManager] saveScreenshotsWithCompletion:nil];
	} else if (action == cc) {
		id topDisplay = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityTopDisplay];
		if (![topDisplay isKindOfClass:%c(SBPowerDownController)] && ![topDisplay isKindOfClass:%c(SBPowerDownViewController)]) {
			SBControlCenterController *_ccController = [%c(SBControlCenterController) sharedInstance];
			if ([_ccController isVisible])
				[_ccController dismissAnimated:YES];
			else
				[_ccController presentAnimated:YES];
		}
	} else if (action == nc) {
		if (![[(SpringBoard *)[UIApplication sharedApplication] _accessibilityTopDisplay] isKindOfClass:%c(SBPowerDownController)]) {
			id topDisplay = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityTopDisplay];
			if (![topDisplay isKindOfClass:%c(SBPowerDownController)] && ![topDisplay isKindOfClass:%c(SBPowerDownViewController)]) {
				SBCoverSheetPresentationManager *_csController = [%c(SBCoverSheetPresentationManager) sharedInstance];
				if (_csController != nil) {
					SBCoverSheetSlidingViewController *currentSlidingViewController = nil;
					if ([_csController isInSecureApp] && _csController.secureAppSlidingViewController != nil)
						currentSlidingViewController = _csController.secureAppSlidingViewController;
					else if (_csController.coverSheetSlidingViewController != nil)
						currentSlidingViewController = _csController.coverSheetSlidingViewController;

					if (currentSlidingViewController != nil) {
						if ([_csController isVisible])
							[currentSlidingViewController _dismissCoverSheetAnimated:YES withCompletion:nil];
						else
							[currentSlidingViewController _presentCoverSheetAnimated:YES withCompletion:nil];
					}
				}
			} else if (%c(SBNotificationCenterController) && [%c(SBNotificationCenterController) respondsToSelector:@selector(sharedInstance)]) {
				SBNotificationCenterController *_ncController = [%c(SBNotificationCenterController) sharedInstance];
				if (_ncController != nil) {
					if ([_ncController isVisible])
						[_ncController dismissAnimated:YES];
					else
						[_ncController presentAnimated:YES];
				}
			}
		}
	} else if (action == lastApp) {
		id topDisplay = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityTopDisplay];
		if (![topDisplay isKindOfClass:%c(SBPowerDownController)] && ![topDisplay isKindOfClass:%c(SBPowerDownViewController)] && ![topDisplay isKindOfClass:%c(SBDashBoardViewController)] && ![topDisplay isKindOfClass:%c(CSCoverSheetViewController)] && (%c(SBCoverSheetPresentationManager) == nil || [[%c(SBCoverSheetPresentationManager) sharedInstance] hasBeenDismissedSinceKeybagLock])) {
			// BOOL isApplication = [topDisplay isKindOfClass:%c(SBApplication)];
			BOOL isApplication = [(SpringBoard *)[UIApplication sharedApplication] _accessibilityFrontMostApplication] != nil;
			SBApplication *toApplication = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:isApplication ? lastApplicationIdentifier : currentApplicationIdentifier];
			if (toApplication != nil) {
				SBMainWorkspace *workspace = [%c(SBMainWorkspace) sharedInstance];
				SBWorkspaceTransitionRequest *request = nil;
				if (%c(SBWorkspaceApplication)) {
					request = [workspace createRequestForApplicationActivation:[%c(SBWorkspaceApplication) entityForApplication:toApplication] options:0];
				} else {
					SBDeviceApplicationSceneEntity *deviceApplicationSceneEntity = [[%c(SBDeviceApplicationSceneEntity) alloc] initWithApplicationForMainDisplay:toApplication];
					request = [workspace createRequestForApplicationActivation:deviceApplicationSceneEntity options:0];
					[deviceApplicationSceneEntity release];
				}
				[workspace executeTransitionRequest:request];
			}
		}
	} else if (action == rotationLock) {
		lockOrUnlockOrientation([(SpringBoard *)[UIApplication sharedApplication] _frontMostAppOrientation]);
	} else if (action == rotatePortraitAndLock) {
		lockOrUnlockOrientation(UIInterfaceOrientationPortrait);
	}
}

-(void)doubleTapUp:(id)arg1 {
	if (isEnabled) {
		[self performAction:doubleTapAction];
	} else {
		%orig(arg1);
	}
}

%new
-(void)singleTapUp:(id)arg1 {
	if (isEnabled) {
		[self performAction:singleTapAction];
	}
}

%new
-(void)longTap:(UILongPressGestureRecognizer *)arg1 {
	if (isEnabled && arg1.state == UIGestureRecognizerStateBegan) {
		[self performAction:longHoldAction];
	}
}

%new
-(void)tapAndHold:(UILongPressGestureRecognizer *)arg1 {
	if (isEnabled && arg1.state == UIGestureRecognizerStateBegan) {
		[self performAction:tapAndHoldAction];
	}
}

%new
-(void)vibrationTap:(UILongPressGestureRecognizer *)arg1 {
	if (isEnabled && isVibrationEnabled && arg1.state == UIGestureRecognizerStateBegan) {
		hapticVibe();
	}
}

%new
-(void)createSingleTapGestureRecognizerWithConfiguration:(SBHomeHardwareButtonGestureRecognizerConfiguration *)arg1 {
	SBHBDoubleTapUpGestureRecognizer *_doubleTapUpGestureRecognizer = [arg1 doubleTapUpGestureRecognizer];
	SBSystemGestureManager *_systemGestureManager = [arg1 systemGestureManager];

	SBHBDoubleTapUpGestureRecognizer *_singleTapGestureRecognizer = [[%c(SBHBDoubleTapUpGestureRecognizer) alloc] initWithTarget:self action:@selector(singleTapUp:)];
	[_singleTapGestureRecognizer setDelegate:self];
	[_singleTapGestureRecognizer requireGestureRecognizerToFail:arg1.longTapGestureRecognizer];
	[_singleTapGestureRecognizer requireGestureRecognizerToFail:arg1.tapAndHoldTapGestureRecognizer];
	[_singleTapGestureRecognizer requireGestureRecognizerToFail:_doubleTapUpGestureRecognizer];
	[_singleTapGestureRecognizer setAllowedPressTypes:[_doubleTapUpGestureRecognizer allowedPressTypes]];
	[_singleTapGestureRecognizer setClickCount:1];

	if (%c(FBSystemGestureManager)) {
		FBSystemGestureManager *_fbSystemGestureManager = [%c(FBSystemGestureManager) sharedInstance];
		if ([_fbSystemGestureManager respondsToSelector:@selector(addGestureRecognizer:toDisplayWithIdentity:)])
			[_fbSystemGestureManager addGestureRecognizer:_singleTapGestureRecognizer toDisplayWithIdentity:MSHookIvar<id>(_systemGestureManager, "_displayIdentity")];
		else if ([_fbSystemGestureManager respondsToSelector:@selector(addGestureRecognizer:toDisplay:)])
			[_fbSystemGestureManager addGestureRecognizer:_singleTapGestureRecognizer toDisplay:[_systemGestureManager display]];
	} else {
		[[%c(_UISystemGestureManager) sharedInstance] addGestureRecognizer:_singleTapGestureRecognizer toDisplayWithIdentity:MSHookIvar<id>(_systemGestureManager, "_displayIdentity")];
	}

	if (arg1.singleTapGestureRecognizer != nil)
		[arg1.singleTapGestureRecognizer release];
	arg1.singleTapGestureRecognizer = _singleTapGestureRecognizer;
}

%new
-(void)createLongTapGestureRecognizerWithConfiguration:(SBHomeHardwareButtonGestureRecognizerConfiguration *)arg1 {
	SBHBDoubleTapUpGestureRecognizer *_doubleTapUpGestureRecognizer = [arg1 doubleTapUpGestureRecognizer];
	SBSystemGestureManager *_systemGestureManager = [arg1 systemGestureManager];

	UILongPressGestureRecognizer *_longTapGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longTap:)];
	[_longTapGestureRecognizer setDelegate:self];
	[_longTapGestureRecognizer setNumberOfTapsRequired:0];
	[_longTapGestureRecognizer setMinimumPressDuration:0.4];
	[_longTapGestureRecognizer setAllowedPressTypes:[_doubleTapUpGestureRecognizer allowedPressTypes]];

	if (%c(FBSystemGestureManager)) {
		FBSystemGestureManager *_fbSystemGestureManager = [%c(FBSystemGestureManager) sharedInstance];
		if ([_fbSystemGestureManager respondsToSelector:@selector(addGestureRecognizer:toDisplayWithIdentity:)])
			[_fbSystemGestureManager addGestureRecognizer:_longTapGestureRecognizer toDisplayWithIdentity:MSHookIvar<id>(_systemGestureManager, "_displayIdentity")];
		else if ([_fbSystemGestureManager respondsToSelector:@selector(addGestureRecognizer:toDisplay:)])
			[_fbSystemGestureManager addGestureRecognizer:_longTapGestureRecognizer toDisplay:[_systemGestureManager display]];
	} else {
		[[%c(_UISystemGestureManager) sharedInstance] addGestureRecognizer:_longTapGestureRecognizer toDisplayWithIdentity:MSHookIvar<id>(_systemGestureManager, "_displayIdentity")];
	}

	if (arg1.longTapGestureRecognizer != nil)
		[arg1.longTapGestureRecognizer release];
	arg1.longTapGestureRecognizer = _longTapGestureRecognizer;
}

%new
-(void)createTapAndHoldGestureRecognizerWithConfiguration:(SBHomeHardwareButtonGestureRecognizerConfiguration *)arg1 {
	SBHBDoubleTapUpGestureRecognizer *_doubleTapUpGestureRecognizer = [arg1 doubleTapUpGestureRecognizer];
	SBSystemGestureManager *_systemGestureManager = [arg1 systemGestureManager];

	UILongPressGestureRecognizer *_tapAndHoldTapGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(tapAndHold:)];
	[_tapAndHoldTapGestureRecognizer setDelegate:self];
	[_tapAndHoldTapGestureRecognizer setNumberOfTapsRequired:1];
	[_tapAndHoldTapGestureRecognizer setMinimumPressDuration:0.4];
	[_tapAndHoldTapGestureRecognizer setAllowedPressTypes:[_doubleTapUpGestureRecognizer allowedPressTypes]];

	if (%c(FBSystemGestureManager)) {
		FBSystemGestureManager *_fbSystemGestureManager = [%c(FBSystemGestureManager) sharedInstance];
		if ([_fbSystemGestureManager respondsToSelector:@selector(addGestureRecognizer:toDisplayWithIdentity:)])
			[_fbSystemGestureManager addGestureRecognizer:_tapAndHoldTapGestureRecognizer toDisplayWithIdentity:MSHookIvar<id>(_systemGestureManager, "_displayIdentity")];
		else if ([_fbSystemGestureManager respondsToSelector:@selector(addGestureRecognizer:toDisplay:)])
			[_fbSystemGestureManager addGestureRecognizer:_tapAndHoldTapGestureRecognizer toDisplay:[_systemGestureManager display]];
	} else {
		[[%c(_UISystemGestureManager) sharedInstance] addGestureRecognizer:_tapAndHoldTapGestureRecognizer toDisplayWithIdentity:MSHookIvar<id>(_systemGestureManager, "_displayIdentity")];
	}

	if (arg1.tapAndHoldTapGestureRecognizer != nil)
		[arg1.tapAndHoldTapGestureRecognizer release];
	arg1.tapAndHoldTapGestureRecognizer = _tapAndHoldTapGestureRecognizer;
}

%new
-(void)createVibrationGestureRecognizerWithConfiguration:(SBHomeHardwareButtonGestureRecognizerConfiguration *)arg1 {
	SBHBDoubleTapUpGestureRecognizer *_doubleTapUpGestureRecognizer = [arg1 doubleTapUpGestureRecognizer];
	SBSystemGestureManager *_systemGestureManager = [arg1 systemGestureManager];

	UILongPressGestureRecognizer *_vibrationGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(vibrationTap:)];
	[_vibrationGestureRecognizer setDelegate:self];
	[_vibrationGestureRecognizer setNumberOfTapsRequired:0];
	[_vibrationGestureRecognizer setMinimumPressDuration:0];
	[_vibrationGestureRecognizer setAllowedPressTypes:[_doubleTapUpGestureRecognizer allowedPressTypes]];

	if (%c(FBSystemGestureManager)) {
		FBSystemGestureManager *_fbSystemGestureManager = [%c(FBSystemGestureManager) sharedInstance];
		if ([_fbSystemGestureManager respondsToSelector:@selector(addGestureRecognizer:toDisplayWithIdentity:)])
			[_fbSystemGestureManager addGestureRecognizer:_vibrationGestureRecognizer toDisplayWithIdentity:MSHookIvar<id>(_systemGestureManager, "_displayIdentity")];
		else if ([_fbSystemGestureManager respondsToSelector:@selector(addGestureRecognizer:toDisplay:)])
			[_fbSystemGestureManager addGestureRecognizer:_vibrationGestureRecognizer toDisplay:[_systemGestureManager display]];
	} else {
		[[%c(_UISystemGestureManager) sharedInstance] addGestureRecognizer:_vibrationGestureRecognizer toDisplayWithIdentity:MSHookIvar<id>(_systemGestureManager, "_displayIdentity")];
	}

	if (arg1.vibrationGestureRecognizer != nil)
		[arg1.vibrationGestureRecognizer release];
	arg1.vibrationGestureRecognizer = _vibrationGestureRecognizer;
}

-(void)_createGestureRecognizersWithConfiguration:(SBHomeHardwareButtonGestureRecognizerConfiguration *)arg1 {
	%orig(arg1);
	[self createVibrationGestureRecognizerWithConfiguration:arg1];
	[self createTapAndHoldGestureRecognizerWithConfiguration:arg1];
	[self createLongTapGestureRecognizerWithConfiguration:arg1];
	[self createSingleTapGestureRecognizerWithConfiguration:arg1];
}


-(void)setGestureRecognizerConfiguration:(SBHomeHardwareButtonGestureRecognizerConfiguration *)arg1 {
	%orig(arg1);
	if (!arg1.vibrationGestureRecognizer) {
		[self createVibrationGestureRecognizerWithConfiguration:arg1];
	}
	if (!arg1.tapAndHoldTapGestureRecognizer) {
		[self createTapAndHoldGestureRecognizerWithConfiguration:arg1];
	}
	if (!arg1.longTapGestureRecognizer) {
		[self createLongTapGestureRecognizerWithConfiguration:arg1];
	}
	if (!arg1.singleTapGestureRecognizer) {
		[self createSingleTapGestureRecognizerWithConfiguration:arg1];
	}
}

-(BOOL)gestureRecognizer:(id)arg1 shouldRecognizeSimultaneouslyWithGestureRecognizer:(id)arg2 {
	SBHomeHardwareButtonGestureRecognizerConfiguration *_configuration = [self gestureRecognizerConfiguration];
	UIHBClickGestureRecognizer *_singleTapGestureRecognizer = _configuration.singleTapGestureRecognizer;
	UILongPressGestureRecognizer *_longTapGestureRecognizer = _configuration.longTapGestureRecognizer;

	SBHBDoubleTapUpGestureRecognizer *_doubleTapUpGestureRecognizer = [_configuration doubleTapUpGestureRecognizer];
	UILongPressGestureRecognizer *_tapAndHoldTapGestureRecognizer = _configuration.tapAndHoldTapGestureRecognizer;

	if (arg1 == _configuration.vibrationGestureRecognizer || arg2 == _configuration.vibrationGestureRecognizer) {
		return YES;
	} else if ((arg1 == _singleTapGestureRecognizer && arg2 == _longTapGestureRecognizer) || (arg1 == _longTapGestureRecognizer && arg2 == _singleTapGestureRecognizer)) {
		return YES;
	} else if ((arg1 == _doubleTapUpGestureRecognizer && arg2 == _tapAndHoldTapGestureRecognizer) || (arg1 == _tapAndHoldTapGestureRecognizer && arg2 == _doubleTapUpGestureRecognizer)) {
		return YES;
	}
	return %orig(arg1, arg2);
}
%end

%hook SBReachabilityManager
+(BOOL)reachabilitySupported {
	return isEnabled ? YES : %orig();
}
%end

%dtor {
	CFNotificationCenterRemoveObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, kSettingsChangedNotification, NULL);
}

%ctor {
	preferencesChanged();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)preferencesChanged, kSettingsChangedNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}