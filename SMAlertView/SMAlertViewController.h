//
//  SMAlertViewController.h
//  SMAlertView
//
//  Created by Sirius Dely on 4/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

enum {
    SMAlertViewControllerButtonTagOk = 1000,
    SMAlertViewControllerTagCancel
};

@class SMAlertViewController;

@protocol SMAlertViewControllerDelegate

@required
- (void) alertViewController:(SMAlertViewController *)alert wasDismissedWithValue:(NSString *)value;

@optional
- (void) alertViewWasCancelled:(SMAlertViewController *)alert;

@end


@interface SMAlertViewController : UIViewController <UITextFieldDelegate> {
    UIView                                  *_alertView;
    UIView                                  *_backgroundView;
    UITextField                             *_textField;
    
    id <NSObject, SMAlertViewControllerDelegate>   _delegate;
}

@property (nonatomic, retain) IBOutlet  UIView *alertView;
@property (nonatomic, retain) IBOutlet  UIView *backgroundView;
@property (nonatomic, retain) IBOutlet  UITextField *textField;

@property (nonatomic, assign) IBOutlet id<SMAlertViewControllerDelegate, NSObject> delegate;

- (IBAction)show;
- (IBAction)dismiss:(id)sender;

@end