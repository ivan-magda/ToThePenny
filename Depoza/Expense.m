#import "Expense.h"
#import "ExpenseData+Fetch.h"

@implementation Expense

+ (Expense *)expenseWithAmount:(NSNumber *)amount category:(NSString *)category description:(NSString *)description {
    Expense *expense = [[Expense alloc]init];
    expense.amount = amount;
    expense.category = category;
    expense.descriptionOfExpense = description;
    expense.dateOfExpense = [NSDate date];
    expense.idValue = [ExpenseData nextId];

    return expense;
}

@end