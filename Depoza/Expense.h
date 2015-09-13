#import <Foundation/Foundation.h>

@class ExpenseData;
@class CSSearchableItem;
@class CSSearchableItemAttributeSet;

@interface Expense : NSObject <NSCoding>

@property (nonatomic, strong) NSNumber *amount;
@property (nonatomic, copy) NSString *category;
@property (nonatomic, copy) NSString *descriptionOfExpense;
@property (nonatomic, strong) NSDate *dateOfExpense;
@property (nonatomic, assign) NSInteger idValue;

@property (nonatomic, strong) CSSearchableItem *searchableItem;
@property (nonatomic, strong) CSSearchableItemAttributeSet *searchableAttributeSet;

+ (Expense *)expenseWithAmount:(NSNumber *)amount categoryName:(NSString *)category description:(NSString *)description;

+ (Expense *)expenseFromExpenseData:(ExpenseData *)expenseData;

@end