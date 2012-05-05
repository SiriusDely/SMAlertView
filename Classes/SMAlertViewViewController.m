//
//  SMAlertViewViewController.m
//  SMAlertView
//
//  Created by Sirius Dely on 4/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import "SMAlertViewViewController.h"

@implementation SMAlertViewViewController



/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (IBAction)showCustomAlert
{
    SMAlertViewController *alert = [[SMAlertViewController alloc] init];
    alert.delegate = self;
    [alert show];
    [alert release];
}
- (IBAction)showDefaultAlert
{
	UIAlertView *alertView = [[UIAlertView alloc]
							  initWithTitle:@"Default Alert"
							  message:@"This is an Apple's alert."
							  delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil,
							  nil];
	[alertView show];
	[alertView release];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void) alertViewController:(SMAlertViewController *)alert wasDismissedWithValue:(NSString *)value {
	NSLog(@"wasDismissedWithValue: %@", value);
}

- (void) alertViewWasCancelled:(SMAlertViewController *)alert {
	NSLog(@"alertViewWasCancelled");
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end
