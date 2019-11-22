#include <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);

typedef enum Action : NSInteger {
	home,
	lock,
	switcher,
	reachability,
	siri,
	screenshot,
	cc,
	nc,
	nothing,
	lastApp,
	rotationLock,
	rotatePortraitAndLock
} Action;

#define kIdentifier @"com.dgh0st.dvirtualhome"
#define kSettingsPath @"/var/mobile/Library/Preferences/com.dgh0st.dvirtualhome.plist"
#define kSettingsChangedNotification (CFStringRef)@"com.dgh0st.dvirtualhome/settingschanged"

static BOOL isEnabled = YES;
static Action singleTapAction = home;
static Action doubleTapAction = switcher;
static Action longHoldAction = reachability;
static Action tapAndHoldAction = siri;
static BOOL isVibrationEnabled = YES;
static CGFloat vibrationIntensity = 0.75;
static NSInteger vibrationDuration = 30; 

@interface SBMainSwitcherViewController : UIViewController
+(id)sharedInstance;
-(BOOL)toggleSwitcherNoninteractively;
-(BOOL)toggleSwitcherNoninteractivelyWithSource:(NSInteger)arg1;
-(BOOL)toggleMainSwitcherNoninteractivelyWithSource:(NSInteger)arg1 animated:(BOOL)arg2;
@end

@interface SBReachabilityManager : NSObject
+(id)sharedInstance;
-(void)toggleReachability;
@end

@interface SBScreenshotManager
-(void)saveScreenshotsWithCompletion:(id)arg1;
@end

@interface SpringBoard : UIApplication
@property (nonatomic, retain) NSString *lastApplicationIdentifier;
@property (nonatomic, retain) NSString *currentApplicationIdentifier;
-(void)_simulateHomeButtonPress;
-(void)_simulateLockButtonPress;
-(SBScreenshotManager *)screenshotManager;
-(void)takeScreenshot;
-(id)_accessibilityTopDisplay;
-(id)_accessibilityFrontMostApplication;
-(UIInterfaceOrientation)_frontMostAppOrientation;
@end

@interface SiriPresentationOptions : NSObject
@property (assign, nonatomic) BOOL wakeScreen;
@property (assign, nonatomic) BOOL hideOtherWindowsDuringAppearance;
@end

@interface AFApplicationInfo : NSObject
@property (nonatomic, copy) NSString *identifier;
@property (assign, nonatomic) NSInteger pid;
-(id)initWithCoder:(id)arg1;
@end

@interface SASRequestOptions : NSObject
@property (assign, nonatomic) CGFloat timestamp;
@property (assign, nonatomic) CGFloat buttonDownTimestamp;
@property (nonatomic, retain) NSArray *contextAppInfosForSiriViewController;
-(id)initWithRequestSource:(NSInteger)arg1 uiPresentationIdentifier:(id)arg2;
@end

@interface SiriPresentationSpringBoardMainScreenViewController : UIViewController
-(oneway void)presentationRequestedWithPresentationOptions:(id)arg1 requestOptions:(id)arg2;
@end

@interface SBAssistantController {
	SiriPresentationSpringBoardMainScreenViewController* _mainScreenSiriPresentation;
}
+(BOOL)isAssistantVisible;
+(BOOL)isVisible;
+(id)sharedInstance;
-(BOOL)handleSiriButtonDownEventFromSource:(NSInteger)arg1 activationEvent:(NSInteger)arg2;
-(void)handleSiriButtonUpEventFromSource:(NSInteger)arg1;
-(void)dismissPluginForEvent:(NSInteger)arg1;
-(void)dismissAssistantViewIfNecessary;
@end

@interface SBControlCenterController
+(id)sharedInstance;
-(BOOL)isVisible;
-(void)dismissAnimated:(BOOL)arg1;
-(void)presentAnimated:(BOOL)arg1;
@end

@interface SBNotificationCenterController
+(id)sharedInstance;
-(BOOL)isVisible;
-(void)dismissAnimated:(BOOL)arg1;
-(void)presentAnimated:(BOOL)arg1;
@end

@interface SBCoverSheetSlidingViewController
-(void)_dismissCoverSheetAnimated:(BOOL)arg1 withCompletion:(id)arg2;
-(void)_presentCoverSheetAnimated:(BOOL)arg1 withCompletion:(id)arg2;
@end

@interface SBCoverSheetPresentationManager
@property (retain, nonatomic) SBCoverSheetSlidingViewController *coverSheetSlidingViewController;
@property (retain, nonatomic) SBCoverSheetSlidingViewController *secureAppSlidingViewController;
+(id)sharedInstance;
-(BOOL)hasBeenDismissedSinceKeybagLock;
-(BOOL)isVisible;
-(BOOL)isInSecureApp;
@end

@interface UIGestureRecognizer (DVirtualHome)
-(id)initWithTarget:(id)arg1 action:(SEL)arg2;
-(id)allowedPressTypes;
-(void)setAllowedPressTypes:(id)arg1;
-(void)requireGestureRecognizerToFail:(id)arg1;
-(void)setDelegate:(id)arg1;
@end

@interface UIHBClickGestureRecognizer : UIGestureRecognizer
-(void)setClickCount:(NSInteger)arg1;
-(void)_resetGestureRecognizer;
@end

@interface SBHBDoubleTapUpGestureRecognizer : UIHBClickGestureRecognizer
@end

@interface SBSystemGestureManager
+(id)mainDisplayManager;
-(id)display;
@end

@interface SBHomeHardwareButtonGestureRecognizerConfiguration
@property (retain, nonatomic) UIHBClickGestureRecognizer *singleTapGestureRecognizer;
@property (retain, nonatomic) UILongPressGestureRecognizer *longTapGestureRecognizer;
@property (retain, nonatomic) UILongPressGestureRecognizer *tapAndHoldTapGestureRecognizer;
@property (retain, nonatomic) UILongPressGestureRecognizer *vibrationGestureRecognizer;
-(id)doubleTapUpGestureRecognizer;
-(SBSystemGestureManager *)systemGestureManager;
@end

@interface SBHomeHardwareButton : NSObject <UIGestureRecognizerDelegate>
-(id)gestureRecognizerConfiguration;
-(void)createSingleTapGestureRecognizerWithConfiguration:(id)arg1;
-(void)createLongTapGestureRecognizerWithConfiguration:(id)arg1;
-(void)createTapAndHoldGestureRecognizerWithConfiguration:(id)arg1;
-(void)createVibrationGestureRecognizerWithConfiguration:(id)arg1;
-(void)performAction:(Action)action;
@end

@interface FBSystemGestureManager : NSObject
+(id)sharedInstance;
-(void)addGestureRecognizer:(id)arg1 toDisplay:(id)arg2;
-(void)addGestureRecognizer:(id)arg1 toDisplayWithIdentity:(id)arg2;
@end

@interface SBMainDisplaySystemGestureManager  : NSObject
+(id)sharedInstance;
-(void)addGestureRecognizer:(id)arg1 ttoDisplayWithIdentity:(id)arg2;
@end

@interface SBApplication : NSObject
-(NSString *)bundleIdentifier;
@end

@interface SBApplicationController : NSObject
+(id)sharedInstance;
-(id)applicationWithBundleIdentifier:(id)arg1;
@end

@interface SBMainWorkspace : NSObject
+(id)sharedInstance;
-(id)createRequestForApplicationActivation:(id)arg1 options:(NSUInteger)arg2;
-(BOOL)executeTransitionRequest:(id)arg1;
@end

@interface SBWorkspaceApplication : NSObject
+(id)entityForApplication:(id)arg1;
@end

@interface SBDeviceApplicationSceneEntity : NSObject
-(id)initWithApplicationForMainDisplay:(id)arg1;
@end

@interface SBWorkspaceTransitionRequest : NSObject
@end

@interface SBOrientationLockManager : NSObject
+(id)sharedInstance;
-(BOOL)isUserLocked;
-(void)lock:(UIInterfaceOrientation)arg1;
-(void)unlock;
@end

@interface UIDevice (DVirtualHome)
-(void)setOrientation:(NSInteger)arg1;
@end

@interface SBBacklightController
+(id)sharedInstance;
-(BOOL)screenIsOn;
@end
