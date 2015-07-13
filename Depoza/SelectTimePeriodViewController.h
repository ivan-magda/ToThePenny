//
//  SelectMonthViewController.h
//  Depoza
//
//  Created by Ivan Magda on 11.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectTimePeriodViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface SelectTimePeriodViewController : UIViewController

/*!
 * If isSelectMonthMode has value YES then SelectTimePeriodViewController will show
 * month mode. Month which has transactions will be displayed with description.
 * Otherwise the description will be displayed on year.
 */
@property (nonatomic, assign) BOOL isSelectMonthMode;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) id <SelectTimePeriodViewControllerDelegate>delegate;

- (void)presentInParentViewController:(UIViewController *)parentViewController;
- (void)dismissFromParentViewController;

@end
