#include "DVHRootListController.h"
#include <spawn.h>

@implementation DVHRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"DVirtualHome" target:self] retain];
	}

	return _specifiers;
}

-(void)email{
	if([MFMailComposeViewController canSendMail]){
		MFMailComposeViewController *email = [[MFMailComposeViewController alloc] initWithNibName:nil bundle:nil];
		[email setSubject:@"DVirtualHome Support"];
		[email setToRecipients:[NSArray arrayWithObjects:@"deeppwnage@yahoo.com", nil]];
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/var/mobile/Library/Preferences/com.dgh0st.dvirtualhome.plist"] mimeType:@"application/xml" fileName:@"Prefs.plist"];
		pid_t pid;
		const char *argv[] = { "/usr/bin/dpkg", "-l" ">" "/tmp/dpkgl.log" };
		extern char *const *environ;
		posix_spawn(&pid, argv[0], NULL, NULL, (char *const *)argv, environ);
		waitpid(pid, NULL, 0);
		[email addAttachmentData:[NSData dataWithContentsOfFile:@"/tmp/dpkgl.log"] mimeType:@"text/plain" fileName:@"dpkgl.txt"];
		[self.navigationController presentViewController:email animated:YES completion:nil];
		[email setMailComposeDelegate:self];
		[email release];
	}
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
    [self dismissViewControllerAnimated: YES completion: nil];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

-(void)donate{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://paypal.me/DGhost"]];
}

-(void)follow{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/D_Gh0st"]];
}

#pragma clang diagnostic pop

@end
