#include <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>

extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);

typedef enum Action : NSInteger {
	home,
	lock,
	switcher,
	reachability,
	siri,
	nothing
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

@interface SBMainSwitcherViewController : NSObject
+(id)sharedInstance;
-(BOOL)toggleSwitcherNoninteractively;
@end

@interface SBReachabilityManager : NSObject
+(id)sharedInstance;
-(void)toggleReachability;
@end

@interface SpringBoard : UIApplication
-(void)_simulateHomeButtonPress;
-(void)_simulateLockButtonPress;
@end

@interface SBAssistantController
+(BOOL)isAssistantVisible;
+(id)sharedInstance;
-(BOOL)handleSiriButtonDownEventFromSource:(NSInteger)arg1 activationEvent:(NSInteger)arg2;
-(void)handleSiriButtonUpEventFromSource:(NSInteger)arg1;
-(void)dismissPluginForEvent:(NSInteger)arg1;
@end

@interface UIGestureRecognizer (DVirtualHome)
-(id)initWithTarget:(id)arg1 action:(SEL)arg2;
-(id)allowedPressTypes;
-(void)setAllowedPressTypes:(id)arg1;
-(void)requireGestureRecognizerToFail:(id)arg1;
-(void)setDelegate:(id)arg1;
-(void)_resetGestureRecognizer;
@end

@interface UIHBClickGestureRecognizer : UIGestureRecognizer
-(void)setClickCount:(NSInteger)arg1;
-(void)_resetGestureRecognizer;
@end

@interface SBHBDoubleTapUpGestureRecognizer : UIHBClickGestureRecognizer
@end

@interface SBSystemGestureManager
+(id)mainDisplayManager;
-(void)addGestureRecognizer:(id)arg1 withType:(NSInteger)arg2 ;
-(id)display;
@end

@interface SBHomeHardwareButtonGestureRecognizerConfiguration
-(void)setSingleTapGestureRecognizer:(id)arg1;
-(id)singleTapGestureRecognizer;
-(void)setLongTapGestureRecognizer:(id)arg1;
-(id)longTapGestureRecognizer;
-(void)setTapAndHoldTapGestureRecognizer:(id)arg1;
-(id)tapAndHoldTapGestureRecognizer;
-(id)doubleTapUpGestureRecognizer;
-(SBSystemGestureManager *)systemGestureManager;
@end

@interface SBHomeHardwareButton : NSObject <UIGestureRecognizerDelegate>
-(id)gestureRecognizerConfiguration;
-(void)createSingleTapGestureRecognizerWithConfiguration:(id)arg1;
-(void)createLongTapGestureRecognizerWithConfiguration:(id)arg1;
-(void)createTapAndHoldGestureRecognizerWithConfiguration:(id)arg1;
-(void)createTripleTapGestureRecognizerWithConfiguration:(id)arg1;
-(void)createDoubleTapAndHoldGestureRecognizerWithConfiguration:(id)arg1;
-(void)performAction:(Action)action;
-(void)resetGestures:(id)arg1;
@end

@interface FBSystemGestureManager
+(id)sharedInstance;
-(void)addGestureRecognizer:(id)arg1 toDisplay:(id)arg2;
@end