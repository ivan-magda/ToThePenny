#import <Foundation/Foundation.h>

@class MIAAddExpenseViewController;
@class MIAExpense;

@protocol MIAAddExpenseViewControllerDelegate <NSObject>

- (void)addExpenseViewController:(MIAAddExpenseViewController *)controller didFinishAddingExpense:(MIAExpense *)expense;

@end