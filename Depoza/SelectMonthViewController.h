//
//  SelectMonthViewController.h
//  Depoza
//
//  Created by Ivan Magda on 11.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SelectMonthViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface SelectMonthViewController : UIViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) id <SelectMonthViewControllerDelegate>delegate;

- (void)presentInParentViewController:(UIViewController *)parentViewController;
- (void)dismissFromParentViewController;

@end
