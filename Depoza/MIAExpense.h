#import <Foundation/Foundation.h>

@class ExpenseData;

@interface MIAExpense : NSObject

@property (nonatomic, strong) NSNumber *amount;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *descriptionOfExpense;
@property (nonatomic, strong) NSDate *dateOfExpense;
@property (nonatomic, assign) NSInteger idValue;

+ (MIAExpense *)expenseWithAmount:(NSNumber *)amount categoryName:(NSString *)category description:(NSString *)description;

+ (MIAExpense *)expenseFromExpenseData:(ExpenseData *)expenseData;

@end