#import <Foundation/Foundation.h>

@class AddExpenseViewController;
@class Expense;

@protocol AddExpenseViewControllerDelegate <NSObject>

- (void)addExpenseViewController:(AddExpenseViewController *)controller didFinishAddingExpense:(Expense *)expense;

@end