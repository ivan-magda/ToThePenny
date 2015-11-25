//
//  CategoryData+Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //CoreData
#import "CategoryData+Fetch.h"
#import "Persistence.h"
#import "CategoriesInfo.h"
#import "ExpenseData+Fetch.h"
    //Categories
#import "NSDate+FirstAndLastDaysOfMonth.h"
    //CoreSearch
#import "SearchableExtension.h"

@implementation CategoryData (Fetch)

#pragma mark - Managing Life Cycle -

- (void)didSave {
    if ([[NSProcessInfo processInfo]operatingSystemVersion].majorVersion >= 9) {
        SearchableExtension *searchableExtension = [SearchableExtension new];
        if ([self isDeleted]) {
            [searchableExtension removeCategoriesFromIndex:@[[CategoriesInfo categoryInfoFromCategoryData:self]]];
        } else {
            [searchableExtension indexCategories:@[[CategoriesInfo categoryInfoFromCategoryData:self]]];
        }
    }
}

#pragma mark - Public -

+ (CategoryData *)categoryDataWithTitle:(NSString *)title iconName:(NSString *)iconName andExpenses:(NSSet *)expenses inManagedObjectContext:(NSManagedObjectContext *)context {
    CategoryData *category = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CategoryData class]) inManagedObjectContext:context];
    category.idValue = @([self nextId]);
    category.title = title;
    category.iconName = (iconName == nil ? @"Puzzle" : iconName);
    
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }

    return category;
}

+ (NSInteger)countForCategoriesInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:fetch error:&error];
    if (error) {
        NSLog(@"Could't fetc for count number of categories: %@", [error localizedDescription]);
    }
    return count;
}

+ (NSInteger)nextId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger idValue = [defaults integerForKey:@"categoryId"];
    [defaults setInteger:idValue + 1 forKey:@"categoryId"];
    [defaults synchronize];

    Persistence *persistence = [Persistence sharedInstance];
    NSInteger count = [CategoryData countForIdValue:idValue inManagedObjectContext:persistence.managedObjectContext];
    if (count == 0) {
        return idValue;
    } else {
        return [self nextId];
    }
}

+ (void)setNextIdValueToUserDefaults:(NSInteger)categories {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:categories forKey:@"categoryId"];
    [defaults synchronize];
}

+ (NSArray *)getAllCategoriesInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSError *error = nil;
    NSArray *foundCategories = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"***Error: %@", [error localizedDescription]);
    }
    NSParameterAssert(foundCategories.count > 0);

    return foundCategories;
}

+ (NSArray *)getCategoriesInContext:(NSManagedObjectContext *)context usingPredicate:(NSPredicate *)predicate {
    NSArray *categories = [CategoryData getAllCategoriesInContext:context];

    return [categories filteredArrayUsingPredicate:predicate];
}

+ (CategoryData *)categoryFromTitle:(NSString *)category context:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSExpression *title = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(title))];
    NSExpression *categoryName = [NSExpression expressionForConstantValue:category];
    NSPredicate *predicate = [NSComparisonPredicate
                              predicateWithLeftExpression:title
                              rightExpression:categoryName
                              modifier:NSDirectPredicateModifier
                              type:NSEqualToPredicateOperatorType
                              options:0];
    fetchRequest.predicate = predicate;
    fetchRequest.fetchLimit = 1;

    NSError *error;
    NSArray *foundCategory = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"***Error: %@", [error localizedDescription]);
    }

    return [foundCategory lastObject];
}

+ (NSArray *)getAllTitlesInContext:(NSManagedObjectContext *)context {
    NSArray *categories = [CategoryData getAllCategoriesInContext:context];
    NSMutableArray *titles = [NSMutableArray arrayWithCapacity:[categories count]];

    for (CategoryData *category in categories) {
        [titles addObject:category.title];
        [context refreshObject:category mergeChanges:NO];
    }
    return [NSArray arrayWithArray:titles];
}

+ (NSArray *)getCategoriesTitleAndIconNameInContext:(NSManagedObjectContext *)context {
    NSArray *categories = [CategoryData getAllCategoriesInContext:context];
    NSMutableArray *infos = [NSMutableArray arrayWithCapacity:[categories count]];

    for (CategoryData *category in categories) {
        CategoriesInfo *anInfo = [CategoriesInfo new];
        anInfo.title = category.title;
        anInfo.iconName = category.iconName;

        [infos addObject:anInfo];
        [context refreshObject:category mergeChanges:NO];
    }
    return [infos copy];
}

+ (NSArray *)getCategoriesWithExpensesBetweenMonthOfDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context {
    NSArray *days = [date getFirstAndLastDatesFromMonth];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(expense, $x, ($x.dateOfExpense >= %@) AND ($x.dateOfExpense <= %@)).@count > 0)", [days firstObject], [days lastObject]];

    NSError *error = nil;
    NSArray *categories = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"Error occured %@", [error localizedDescription]);
    }
    return categories;
}

+ (NSDictionary *)getAllIconsNameInContext:(NSManagedObjectContext *)context {
    NSArray *categories = [CategoryData getAllCategoriesInContext:context];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:[categories count]];

    for (CategoryData *category in categories) {
        [dictionary setValue:category.iconName forKey:category.title];
        [context refreshObject:category mergeChanges:NO];
    }
    return [dictionary copy];
}

+ (CategoryData *)getCategoryFromIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:NSStringFromClass([CategoryData class])];
    [request setRelationshipKeyPathsForPrefetching:@[NSStringFromSelector(@selector(expense))]];

    NSExpression *idKeyPath = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(idValue))];
    NSExpression *idToFind  = [NSExpression expressionForConstantValue:@(idValue)];
    NSPredicate *predicate  = [NSComparisonPredicate predicateWithLeftExpression:idKeyPath
                                                                 rightExpression:idToFind
                                                                        modifier:NSDirectPredicateModifier
                                                                            type:NSEqualToPredicateOperatorType
                                                                         options:0];
    request.predicate = predicate;

    NSError *error = nil;
    NSArray *category = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }

    NSParameterAssert(category.count == 1);

    return category.firstObject;
}

+ (NSInteger)countForIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:NSStringFromClass([CategoryData class])];

    NSExpression *idKeyPath = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(idValue))];
    NSExpression *idToFind  = [NSExpression expressionForConstantValue:@(idValue)];
    NSPredicate *predicate  = [NSComparisonPredicate predicateWithLeftExpression:idKeyPath
                                                                 rightExpression:idToFind
                                                                        modifier:NSDirectPredicateModifier
                                                                            type:NSEqualToPredicateOperatorType
                                                                         options:0];
    request.predicate = predicate;

    NSError *error = nil;
    NSInteger count = [context countForFetchRequest:request error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }

    return count;
}

+ (NSArray *)sumOfExpensesInManagedObjectContext:(NSManagedObjectContext *)context usingPredicate:(NSPredicate *)predicate {
    NSExpression *amount = [NSExpression expressionForKeyPath:@"expense.amount"];
    NSExpression *sum = [NSExpression expressionForFunction:@"sum:" arguments:@[amount]];

    NSExpressionDescription *sumDescription = [NSExpressionDescription new];
    sumDescription.name = @"sum";
    sumDescription.expression = sum;
    sumDescription.expressionResultType = NSFloatAttributeType;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
    fetchRequest.propertiesToFetch = @[sumDescription];
    fetchRequest.resultType = NSDictionaryResultType;
    fetchRequest.predicate = predicate;

    NSError *error = nil;
    NSArray *results = [context executeFetchRequest:fetchRequest error:nil];
    if (error) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, [error localizedDescription]);
    }

    return results;
}

+ (NSUInteger)countForFrequencyUseInManagedObjectContext:(NSManagedObjectContext *)context betweenDates:(NSArray *)dates andWithCategoryIdValue:(NSNumber *)categoryId {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

    NSPredicate *betweenDatesPredicate = [ExpenseData compoundPredicateBetweenDates:dates];

    NSExpression *idKeyPath = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(categoryId))];
    NSExpression *idValue = [NSExpression expressionForConstantValue:categoryId];
    NSPredicate *categoryIdPredicate = [NSComparisonPredicate predicateWithLeftExpression:idKeyPath rightExpression:idValue modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];

    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[categoryIdPredicate, betweenDatesPredicate]];
    fetchRequest.predicate = predicate;

    NSError *error = nil;
    NSUInteger result = [context countForFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, [error localizedDescription]);
    }

    return result;
}

+ (BOOL)checkForUniqueName:(NSString *)name managedObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSExpression *title = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(title))];
    NSExpression *categoryName = [NSExpression expressionForConstantValue:name];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:title rightExpression:categoryName modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:NSCaseInsensitivePredicateOption];

    fetchRequest.predicate = predicate;

    NSError *error = nil;
    NSUInteger countCategories = [context countForFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"%s %@", __PRETTY_FUNCTION__, [error localizedDescription]);
    }

    return (countCategories == 0);
}

@end
