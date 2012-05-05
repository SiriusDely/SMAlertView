//
//  SMAlertViewAppDelegate.h
//  SMAlertView
//
//  Created by Sirius Dely on 4/23/12.
//  Copyright 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SMAlertViewViewController;

@interface SMAlertViewAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    SMAlertViewViewController *viewController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet SMAlertViewViewController *viewController;

@end

