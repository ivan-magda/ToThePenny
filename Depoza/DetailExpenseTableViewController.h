//
//  EditExpenseTableViewController.h
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChooseCategoryTableViewControllerDelegate.h"

@class ExpenseData;

extern NSString * const DetailExpenseTableViewControllerDidUpdateNotification;

@interface DetailExpenseTableViewController : UITableViewController <ChooseCategoryTableViewControllerDelegate>

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) ExpenseData *expenseToShow;

@end
