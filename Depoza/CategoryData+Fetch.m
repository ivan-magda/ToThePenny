//
//  CategoryData+Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoryData+Fetch.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"
#import "Persistence.h"

@implementation CategoryData (Fetch)

+ (CategoryData *)categoryDataWithTitle:(NSString *)title iconName:(NSString *)iconName andExpenses:(NSSet *)expenses inManagedObjectContext:(NSManagedObjectContext *)context {
    CategoryData *category = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CategoryData class]) inManagedObjectContext:context];
    category.idValue = @([self nextId]);
    category.title = title;
    category.iconName = iconName;
    
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

+ (NSArray *)getCategoriesWithExpensesBetweenMonthOfDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context {
    NSArray *days = [date getFirstAndLastDaysInTheCurrentMonth];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(expense, $x, ($x.dateOfExpense >= %@) AND ($x.dateOfExpense <= %@)).@count > 0)", [days firstObject], [days lastObject]];

    NSError *error = nil;
    NSArray *categories = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"Error occured %@", [error localizedDescription]);
    }
    return categories;
}

+ (NSDictionary *)getIconsNamesAllCategoriesInContext:(NSManagedObjectContext *)context {
    NSArray *categories = [CategoryData getAllCategoriesInContext:context];
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:[categories count]];

    for (CategoryData *category in categories) {
        [dictionary setValue:category.iconName forKey:category.title];
        [context refreshObject:category mergeChanges:NO];
    }
    return [dictionary copy];
}

+ (NSArray *)getCategoryFromIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context {
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

    return category;
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

@end
