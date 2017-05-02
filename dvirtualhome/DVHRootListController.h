#import <Preferences/PSListController.h>
#import <Preferences/PSTableCell.h>
#import <MessageUI/MFMailComposeViewController.h>

@interface PSTableCell (UndoRotation)
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;
@end

@interface PSListController (UndoRotation)
- (void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag completion:(void (^)(void))completion;
- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion;
- (UINavigationController*)navigationController;
@end

@interface DVHRootListController : PSListController <MFMailComposeViewControllerDelegate>

@end
