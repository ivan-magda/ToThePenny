//
//  ExpenseData+Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 17.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "ExpenseData+Fetch.h"
#import "Persistence.h"
    //Categories
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"
#import "NSDate+NextMonthFirstDate.h"
#import "NSDate+IsDatesWithEqualMonth.h"

@implementation ExpenseData (Fetch)

+ (NSInteger)nextId {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger idValue = [defaults integerForKey:@"idValue"];
    [defaults setInteger:idValue + 1 forKey:@"idValue"];
    [defaults synchronize];

    Persistence *persistence = [Persistence sharedInstance];
    NSInteger count = [ExpenseData countForIdValue:idValue inManagedObjectContext:persistence.managedObjectContext];
    if (count == 0) {
        return idValue;
    } else {
        return [self nextId];
    }
}

+ (void)setNextIdValueToUserDefaults:(NSInteger)expenses {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:expenses forKey:@"idValue"];
    [defaults synchronize];
}

+ (NSPredicate *)compoundPredicateBetweenDates:(NSArray *)dates {
    NSAssert(dates.count == 2, @"Maximum 2 days.");

    NSExpression *dateExp    = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(dateOfExpense))];
    NSExpression *dateStart  = [NSExpression expressionForConstantValue:[dates firstObject]];
    NSExpression *dateEnd    = [NSExpression expressionForConstantValue:[dates lastObject]];
    NSExpression *expression = [NSExpression expressionForAggregate:@[dateStart, dateEnd]];

    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:dateExp
                                                                rightExpression:expression
                                                                       modifier:NSDirectPredicateModifier
                                                                           type:NSBetweenPredicateOperatorType
                                                                        options:0];
    return predicate;
}

+ (NSArray *)getTodayExpensesInManagedObjectContext:(NSManagedObjectContext *)context {
    NSArray *dates = [NSDate getStartAndEndDatesOfTheCurrentDate];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO]];
    request.fetchBatchSize = 10;

    NSPredicate *predicate = [ExpenseData compoundPredicateBetweenDates:dates];
    request.predicate = predicate;

    NSError *error;
    NSArray *expenses = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error %@", [error localizedDescription]);
        NSParameterAssert(NO);
    }
    return (expenses.count > 0 ? expenses : nil);
}

+ (ExpenseData *)getExpenseFromIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:NSStringFromClass([ExpenseData class])];

    NSExpression *idKeyPath = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(idValue))];
    NSExpression *idToFind  = [NSExpression expressionForConstantValue:@(idValue)];
    NSPredicate *predicate  = [NSComparisonPredicate predicateWithLeftExpression:idKeyPath
                                                                 rightExpression:idToFind
                                                                        modifier:NSDirectPredicateModifier
                                                                            type:NSEqualToPredicateOperatorType
                                                                         options:0];
    request.predicate = predicate;

    NSError *error = nil;
    NSArray *expense = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"%@", [error localizedDescription]);
    }
    NSParameterAssert(expense.count == 1);
    NSParameterAssert(expense.firstObject != nil);

    return [expense firstObject];
}

+ (NSInteger)countForExpensesInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:fetch error:&error];
    if (error) {
        NSLog(@"Could't fetc for count number of categories: %@", [error localizedDescription]);
    }
    return count;
}

+ (NSDate *)oldestDateExpenseInManagedObjectContext:(NSManagedObjectContext *)context andCategoryId:(NSNumber *)categoryId {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

    if (categoryId) {
        request.predicate = [ExpenseData categoryIdPredicateFromCategoryIdValue:categoryId];
    }

    [request setResultType:NSDictionaryResultType];

        // Create an expression for the key path.
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(dateOfExpense))];

        // Create an expression to represent the minimum value at the key path 'creationDate'
    NSExpression *minExpression = [NSExpression expressionForFunction:@"min:" arguments:@[keyPathExpression]];

        // Create an expression description using the maxExpression and returning a date.
    NSExpressionDescription *expressionDescription = [NSExpressionDescription new];

        // The name is the key that will be used in the dictionary for the return value.
    [expressionDescription setName:@"minDate"];
    [expressionDescription setExpression:minExpression];
    [expressionDescription setExpressionResultType:NSDateAttributeType];

        // Set the request's properties to fetch just the property represented by the expressions.
    [request setPropertiesToFetch:@[expressionDescription]];

        // Execute the fetch.
    NSDate *minDate = nil;
    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSAssert(NO, @"Must be at least one object");
    } else {
        minDate = [[objects objectAtIndex:0] valueForKey:@"minDate"];
    }
    return minDate;
}

+ (NSDate *)mostRecentDateExpenseInManagedObjectContext:(NSManagedObjectContext *)context andCategoryId:(NSNumber *)categoryId {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

    if (categoryId) {
        request.predicate = [ExpenseData categoryIdPredicateFromCategoryIdValue:categoryId];
    }

    [request setResultType:NSDictionaryResultType];

        // Create an expression for the key path.
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(dateOfExpense))];

        // Create an expression to represent the minimum value at the key path 'creationDate'
    NSExpression *maxExpression = [NSExpression expressionForFunction:@"max:" arguments:@[keyPathExpression]];

        // Create an expression description using the maxExpression and returning a date.
    NSExpressionDescription *expressionDescription = [NSExpressionDescription new];

        // The name is the key that will be used in the dictionary for the return value.
    [expressionDescription setName:@"maxDate"];
    [expressionDescription setExpression:maxExpression];
    [expressionDescription setExpressionResultType:NSDateAttributeType];

        // Set the request's properties to fetch just the property represented by the expressions.
    [request setPropertiesToFetch:@[expressionDescription]];

        // Execute the fetch.
    NSDate *maxDate = nil;
    NSError *error = nil;
    NSArray *objects = [context executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSAssert(NO, @"Must be at least one object");
    } else {
        maxDate = [[objects objectAtIndex:0] valueForKey:@"maxDate"];
    }
    return maxDate;
}

+ (NSPredicate *)categoryIdPredicateFromCategoryIdValue:(NSNumber *)categoryId {
    NSExpression *categoryIdKeyPath = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(categoryId))];
    NSExpression *idValue = [NSExpression expressionForConstantValue:categoryId];
    return [NSComparisonPredicate predicateWithLeftExpression:categoryIdKeyPath rightExpression:idValue modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
}


+ (NSDate *)oldestDateExpenseInManagedObjectContext:(NSManagedObjectContext *)context {
    return [ExpenseData oldestDateExpenseInManagedObjectContext:context andCategoryId:nil];
}

+ (NSDate *)mostRecentDateExpenseInManagedObjectContext:(NSManagedObjectContext *)context {
    return [ExpenseData mostRecentDateExpenseInManagedObjectContext:context andCategoryId:nil];
}

+ (NSArray *)getEachMonthWithSumExpensesInManagedObjectContext:(NSManagedObjectContext *)context {
    NSDate *oldestDate = [self oldestDateExpenseInManagedObjectContext:context];
    NSDate *mostRecentDate = [self mostRecentDateExpenseInManagedObjectContext:context];

    BOOL currentMonthAdded = NO;
    NSMutableArray *countOnMonth = [NSMutableArray new];

    if (oldestDate && mostRecentDate) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];
        [request setReturnsObjectsAsFaults:NO];

        while ([oldestDate compare:mostRecentDate] != NSOrderedDescending) {
            NSArray *dates = [oldestDate getFirstAndLastDatesFromMonth];

            NSPredicate *predicate = [ExpenseData compoundPredicateBetweenDates:dates];
            request.predicate = predicate;

            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (error) {
                NSLog(@"Error %s %@", __PRETTY_FUNCTION__, [error localizedDescription]);
                return nil;
            }

            if ([[NSDate date]isDatesWithEqualMonth:dates.firstObject]) {
                currentMonthAdded = YES;
            }

            if (objects.count > 0) {
                float amount = 0.0f;
                for (ExpenseData *expense in objects) {
                    amount += [expense.amount floatValue];
                    [context refreshObject:expense mergeChanges:NO];
                }

                NSDictionary *components = [oldestDate getComponents];

                NSDictionary *month = @{@"year"   : components[@"year"],
                                        @"month"  : components[@"month"],
                                        @"amount" : @(amount)};

                [countOnMonth addObject:month];
            }
            oldestDate = [oldestDate nextMonthFirstDate];
        }
    }

    if (!currentMonthAdded) {
        NSDictionary *components = [[NSDate date] getComponents];
        NSInteger currentYear = [components[@"year"]integerValue];
        NSInteger currentMonth = [components[@"month"]integerValue];
        
        NSDictionary *month = @{@"year"   : @(currentYear),
                                @"month"  : @(currentMonth),
                                @"amount" : @0};

        [countOnMonth addObject:month];
    }

    return [[countOnMonth reverseObjectEnumerator]allObjects];
}

+ (NSInteger)countForIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:NSStringFromClass([ExpenseData class])];

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
