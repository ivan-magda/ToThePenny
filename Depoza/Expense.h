#import <Foundation/Foundation.h>

@interface Expense : NSObject

@property (nonatomic, strong) NSNumber *sumOfExpense;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *descriptionOfExpense;
@property (nonatomic, strong) NSDate *dateOfExpense;

+ (Expense *)expenseWithSum:(NSNumber *)sumOfExpense category:(NSString *)category description:(NSString *)description;

@end