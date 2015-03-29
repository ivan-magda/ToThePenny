#import "MIAExpense.h"
#import "ExpenseData+Fetch.h"
#import "CategoryData.h"

@implementation MIAExpense

+ (MIAExpense *)expenseWithAmount:(NSNumber *)amount categoryName:(NSString *)category description:(NSString *)description {
    MIAExpense *expense = [[MIAExpense alloc]init];
    expense.amount = amount;
    expense.category = category;
    expense.descriptionOfExpense = description;
    expense.dateOfExpense = [NSDate date];
    expense.idValue = [ExpenseData nextId];

    return expense;
}

+ (MIAExpense *)expenseFromExpenseData:(ExpenseData *)expenseData {
    MIAExpense *expense = [MIAExpense new];
    expense.amount = expenseData.amount;
    expense.category = expenseData.category.title;
    expense.descriptionOfExpense = expenseData.descriptionOfExpense;
    expense.dateOfExpense = expenseData.dateOfExpense;
    expense.idValue = expenseData.idValue.intValue;

    return expense;
}

@end