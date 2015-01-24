#import <Foundation/Foundation.h>

@interface Expense : NSObject

@property (nonatomic, strong) NSNumber *amount;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *descriptionOfExpense;
@property (nonatomic, strong) NSDate *dateOfExpense;
@property (nonatomic, assign) NSInteger idValue;

+ (Expense *)expenseWithAmount:(NSNumber *)amount category:(NSString *)category description:(NSString *)description;

@end