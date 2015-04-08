#import <Foundation/Foundation.h>

@class ExpenseData;

@interface Expense : NSObject <NSCoding>

@property (nonatomic, strong) NSNumber *amount;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *descriptionOfExpense;
@property (nonatomic, strong) NSDate *dateOfExpense;
@property (nonatomic, assign) NSInteger idValue;

+ (Expense *)expenseWithAmount:(NSNumber *)amount categoryName:(NSString *)category description:(NSString *)description;

+ (Expense *)expenseFromExpenseData:(ExpenseData *)expenseData;

@end