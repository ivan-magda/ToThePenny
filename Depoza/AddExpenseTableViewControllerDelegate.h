#import <Foundation/Foundation.h>

@class AddExpenseTableViewController;
@class Expense;

@protocol AddExpenseTableViewControllerDelegate <NSObject>

- (void)addExpenseTableViewController:(AddExpenseTableViewController *)controller didFinishAddingExpense:(Expense *)expense;

- (void)addExpenseTableViewControllerDidCancel:(AddExpenseTableViewController *)controller;

@end