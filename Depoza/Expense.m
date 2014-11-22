#import "Expense.h"

@implementation Expense

+ (Expense *)expenseWithSum:(NSNumber *)sumOfExpense category:(NSString *)category description:(NSString *)description {
    Expense *expense = [[Expense alloc]init];
    expense.sumOfExpense = sumOfExpense;
    expense.category = category;
    expense.descriptionOfExpense = description;
    expense.dateOfExpense = [NSDate date];

    return expense;
}

@end