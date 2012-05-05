//
//  SMAlertViewViewController.h
//  SMAlertView
//
//  Created by Sirius Dely on 4/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SMAlertViewController.h"

@interface SMAlertViewViewController : UIViewController <SMAlertViewControllerDelegate> {

}

- (IBAction)showCustomAlert;
- (IBAction)showDefaultAlert;
- (IBAction)showAlertView;

@end

