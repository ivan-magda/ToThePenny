//
//  EditExpenseTableViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 20.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ExpenseData;
@class DetailExpenseTableViewController;

@protocol DetailExpenseTableViewControllerDelegate <NSObject>

- (void)detailExpenseTableViewControllerDelegate:(DetailExpenseTableViewController *)controller didFinishUpdateExpense:(ExpenseData *)expense;

@end
