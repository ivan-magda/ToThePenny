#import "Expense.h"
#import "ExpenseData+Fetch.h"
#import "CategoryData.h"

@implementation Expense

+ (Expense *)expenseWithAmount:(NSNumber *)amount categoryName:(NSString *)category description:(NSString *)description {
    Expense *expense = [[Expense alloc]init];
    expense.amount = amount;
    expense.category = category;
    expense.descriptionOfExpense = description;
    expense.dateOfExpense = [NSDate date];
    expense.idValue = [ExpenseData nextId];

    return expense;
}

+ (Expense *)expenseFromExpenseData:(ExpenseData *)expenseData {
    Expense *expense = [Expense new];
    expense.amount = expenseData.amount;
    expense.category = expenseData.category.title;
    expense.descriptionOfExpense = expenseData.descriptionOfExpense;
    expense.dateOfExpense = expenseData.dateOfExpense;
    expense.idValue = expenseData.idValue.intValue;

    return expense;
}

@end