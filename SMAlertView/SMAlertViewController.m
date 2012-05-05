//
//  SMAlertViewController.m
//  SMAlertView
//
//  Created by Sirius Dely on 4/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "SMAlertViewController.h"
#import "UIView+AlertAnimations.h"

@interface SMAlertViewController()
- (void)alertDidFadeOut;
@end

@implementation SMAlertViewController
@synthesize alertView = _alertView;
@synthesize backgroundView = _backgroundView;
@synthesize textField = _textField;
@synthesize delegate = _delegate;

#pragma mark -
#pragma mark IBActions
- (IBAction)show {
	// Retaining self is odd, but we do it to make this "fire and forget"
	[self retain];
	
	// We need to add it to the window, which we can get from the delegate
	id appDelegate = [[UIApplication sharedApplication] delegate];
	UIWindow *window = [appDelegate window];
	[window addSubview:self.view];
	
	// Make sure the alert covers the whole window
	self.view.frame = window.frame;
	self.view.center = window.center;
	
	// "Pop in" animation for alert
	[_alertView doPopInAnimationWithDelegate:self];
	
	// "Fade in" animation for background
	[_backgroundView doFadeInAnimation];
}

- (IBAction)dismiss:(id)sender {
	[_textField resignFirstResponder];
	[UIView beginAnimations:nil context:nil];
	self.view.alpha = 0.0;
	[UIView commitAnimations];
	
	[self performSelector:@selector(alertDidFadeOut) withObject:nil afterDelay:0.5];
	
	if (sender == self || [sender tag] == SMAlertViewControllerButtonTagOk) {
		[self.delegate alertViewController:self wasDismissedWithValue:_textField.text];
	} else {
		if ([self.delegate respondsToSelector:@selector(alertViewWasCancelled:)]) {
			[self.delegate alertViewWasCancelled:self];
		}		
	} 
}

#pragma mark -
- (void)viewDidUnload {
	[super viewDidUnload];
	self.alertView = nil;
	self.backgroundView = nil;
	self.textField = nil;
}

- (void)dealloc {
	[_alertView release];
	[_backgroundView release];
	[_textField release];
	[super dealloc];
}

#pragma mark -
#pragma mark Private Methods
- (void)alertDidFadeOut {    
	[self.view removeFromSuperview];
	[self autorelease];
}

#pragma mark -
#pragma mark CAAnimation Delegate Methods
- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	[self.textField becomeFirstResponder];
}

#pragma mark -
#pragma mark Text Field Delegate Methods
- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self dismiss:self];
	return YES;
}

@end