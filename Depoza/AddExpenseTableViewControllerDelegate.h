#import <Foundation/Foundation.h>

@class AddExpenseTableViewController;
@class CategoryData;
@class Expense;

@protocol AddExpenseTableViewControllerDelegate <NSObject>

- (void)addExpenseTableViewController:(AddExpenseTableViewController *)controller didFinishAddingExpense:(Expense *)expense;

- (void)addExpenseTableViewControllerDidCancel:(AddExpenseTableViewController *)controller;

- (void)addExpenseTableViewController:(AddExpenseTableViewController *)controller didAddCategory:(CategoryData *)category;

@end