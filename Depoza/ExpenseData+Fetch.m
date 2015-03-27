//
//  ExpenseData+Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 17.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "ExpenseData+Fetch.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation ExpenseData (Fetch)

+ (NSInteger)nextId {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSInteger idValue = [userDefaults integerForKey:@"idValue"];
    [userDefaults setInteger:idValue + 1 forKey:@"idValue"];
    [userDefaults synchronize];

    return idValue;
}

+ (NSArray *)expensesWithEqualDayWithDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context {
    NSArray *dates = [NSDate getDatesFromDate:date sameDayOrFirstAndLastOfMonth:YES];

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO]];
    request.fetchBatchSize = 10;

    NSExpression *dateExp = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(dateOfExpense))];
    NSExpression *dateStart = [NSExpression expressionForConstantValue:[dates firstObject]];
    NSExpression *dateEnd = [NSExpression expressionForConstantValue:[dates lastObject]];
    NSExpression *expression = [NSExpression expressionForAggregate:@[dateStart, dateEnd]];
    NSPredicate *predicate = [NSComparisonPredicate predicateWithLeftExpression:dateExp
                                                                rightExpression:expression
                                                                       modifier:NSDirectPredicateModifier
                                                                           type:NSBetweenPredicateOperatorType
                                                                        options:0];
    request.predicate = predicate;

    NSError *error;
    NSArray *expenses = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"Error %@", [error localizedDescription]);
        NSParameterAssert(NO);
    }
    return (expenses.count > 0 ? expenses : nil);
}

+ (ExpenseData *)getExpenseFromIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context
{
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

@end
