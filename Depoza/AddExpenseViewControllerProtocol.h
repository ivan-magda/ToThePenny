#import <Foundation/Foundation.h>

@class AddExpenseViewController;
@class Expense;

@protocol AddExpenseViewControllerProtocol <NSObject>

- (void)addExpenseViewController:(AddExpenseViewController *)controller didFinishAddingExpense:(Expense *)expense;

@end