    //CoreData
#import "Expense.h"
#import "ExpenseData+Fetch.h"
#import "CategoryData.h"
    //CoreSearch
#import "SearchableExtension.h"
@import CoreSpotlight;
    //Categories
#import "NSString+FormatAmount.h"

@implementation Expense

#pragma mark - Convenience -

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

#pragma mark - NSCoding -

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [aCoder encodeObject:_amount forKey:@"amount"];
    [aCoder encodeObject:_category forKey:@"category"];
    [aCoder encodeObject:_descriptionOfExpense forKey:@"description"];
    [aCoder encodeObject:_dateOfExpense forKey:@"date"];
    [aCoder encodeInteger:_idValue forKey:@"idValue"];
}
- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super init] ) {
        _amount = [aDecoder decodeObjectForKey:@"amount"];
        _category = [aDecoder decodeObjectForKey:@"category"];
        _descriptionOfExpense = [aDecoder decodeObjectForKey:@"description"];
        _dateOfExpense = [aDecoder decodeObjectForKey:@"date"];
        _idValue = [aDecoder decodeIntegerForKey:@"idValue"];
    }
    return self;
}

#pragma mark - NSObject Protocol -

- (BOOL)isEqual:(id)object {
    if (self == object) {
        return YES;
    }
    if ([self class] != [object class]) {
        return NO;
    }

    Expense *otherExpense = (Expense *)object;
    if (_idValue != otherExpense.idValue) {
        return NO;
    }
    if ([_amount floatValue] != [otherExpense.amount floatValue]) {
        return NO;
    }
    if (![_category isEqualToString:otherExpense.category]) {
        return NO;
    }
    if (![_descriptionOfExpense isEqualToString:otherExpense.descriptionOfExpense]) {
        return NO;
    }
    if ([_dateOfExpense compare:otherExpense.dateOfExpense] != NSOrderedSame) {
        return NO;
    }
    
    return YES;
}

- (NSUInteger)hash {
    NSString *stringToHash = [NSString stringWithFormat:@"%@:%@:%@:%@:%li", _amount, _category, _descriptionOfExpense, _dateOfExpense, (long)_idValue];
    return [stringToHash hash];
}

#pragma mark - CoreSearch -

- (CSSearchableItemAttributeSet *)searchableAttributeSet {
    if (_descriptionOfExpense.length < 1) {
        return nil;
    }
    
    if (!_searchableAttributeSet) {
        NSString *title = _category;
        
        _searchableAttributeSet = [[CSSearchableItemAttributeSet alloc]initWithItemContentType:(NSString *)kUTTypeContent];
        _searchableAttributeSet.contentDescription = _descriptionOfExpense;
        _searchableAttributeSet.title = title;
        _searchableAttributeSet.displayName = [NSString stringWithFormat:@"%@, %@", title, [NSString formatAmount:_amount]];;
        _searchableAttributeSet.contentCreationDate = _dateOfExpense;
        
        NSArray *keywords = [_descriptionOfExpense componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        keywords = [keywords filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
        _searchableAttributeSet.keywords = keywords;
    }
    return _searchableAttributeSet;
}

- (CSSearchableItem *)searchableItem {
    if (self.searchableAttributeSet == nil) {
        return nil;
    }
    
    if (!_searchableItem) {
        _searchableItem = [[CSSearchableItem alloc]initWithUniqueIdentifier:[NSString stringWithFormat:@"expense.%@",@(_idValue)] domainIdentifier:ExpenseDomainID attributeSet:self.searchableAttributeSet];
    }
    return _searchableItem;
}


@end