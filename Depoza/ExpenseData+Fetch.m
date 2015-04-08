//
//  ExpenseData+Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 17.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "ExpenseData+Fetch.h"
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"

@implementation ExpenseData (Fetch)

+ (NSInteger)nextId {
    NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
    NSInteger idValue = [[kvStore objectForKey:@"idValue"]integerValue];
    [kvStore setObject:@(idValue + 1) forKey:@"idValue"];

    return idValue;
}

+ (void)setNextIdValueToUbiquitousKeyValueStore:(NSInteger)expenses {
    NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
    [kvStore setObject:@(expenses) forKey:@"idValue"];
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

@end
