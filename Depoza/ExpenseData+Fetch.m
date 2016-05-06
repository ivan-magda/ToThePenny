//
//  ExpenseData+Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 17.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    // CoreData
#import "ExpenseData+Fetch.h"
#import "Persistence.h"
#import "Expense.h"
#import "CategoryData+Fetch.h"
    //Categories
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"
#import "NSDate+NextMonthFirstDate.h"
#import "NSDate+NextYearFirstDate.h"
#import "NSDate+IsDatesWithEqualMonth.h"
#import "NSDate+IsDatesWithEqualYear.h"
#import "NSDate+StartAndEndDatesOfYear.h"
    //CoreSearch
#import "SearchableExtension.h"

@implementation ExpenseData (Fetch)

#pragma mark - Managing Life Cycle -

- (void)didSave {
    if ([[NSProcessInfo processInfo]operatingSystemVersion].majorVersion >= 9) {
        SearchableExtension *searchableExtension = [SearchableExtension new];
        
        if ([self isDeleted]) {
            [searchableExtension removeExpensesFromIndex:@[[Expense expenseFromExpenseData:self]]];
        } else {
            [searchableExtension indexExpenses:@[[Expense expenseFromExpenseData:self]]];
        }
        
    }
}

#pragma mark - ID -

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

#pragma mark - Predicates -

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

+ (NSPredicate *)categoryIdPredicateFromCategoryIdValue:(NSNumber *)categoryId {
    NSExpression *categoryIdKeyPath = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(categoryId))];
    NSExpression *idValue = [NSExpression expressionForConstantValue:categoryId];
    return [NSComparisonPredicate predicateWithLeftExpression:categoryIdKeyPath rightExpression:idValue modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];
}

#pragma mark - Getting -

+ (NSArray *)getAllExpensesInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];
    
    NSError *error = nil;
    NSArray *foundExpenses = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"***Error: %@", [error localizedDescription]);
    }
    
    return foundExpenses;
}

+ (NSArray *)getExpensesInContext:(NSManagedObjectContext *)context usingPredicate:(NSPredicate *)predicate {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];
    fetchRequest.predicate = predicate;
    
    NSError *error = nil;
    NSArray *fetchedExpenses = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"Error fetching expenses: %@", [error localizedDescription]);
    }
    
    return fetchedExpenses;
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

#pragma mark - Getting Based on Dates

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


+ (NSDate *)oldestDateExpenseInManagedObjectContext:(NSManagedObjectContext *)context {
    return [ExpenseData oldestDateExpenseInManagedObjectContext:context andCategoryId:nil];
}

+ (NSDate *)mostRecentDateExpenseInManagedObjectContext:(NSManagedObjectContext *)context {
    return [ExpenseData mostRecentDateExpenseInManagedObjectContext:context andCategoryId:nil];
}

+ (NSArray *)getEachMonthWithSumExpensesInManagedObjectContext:(NSManagedObjectContext *)context {
    return [self countForExpensesInContext:context inEachMonth:YES orInEachYear:NO];
}

+ (NSArray *)getEachYearWithSumExpensesInManagedObjectContext:(NSManagedObjectContext *)context {
    return [self countForExpensesInContext:context inEachMonth:NO orInEachYear:YES];
}

+ (NSArray *)getOldestAndMostRecentDatesInContext:(NSManagedObjectContext *)context {
    NSDate *oldestDate     = [self oldestDateExpenseInManagedObjectContext:context];
    NSDate *mostRecentDate = [self mostRecentDateExpenseInManagedObjectContext:context];
    
    if (!oldestDate || !mostRecentDate) {
        return [NSArray array];
    }
    
    return @[oldestDate, mostRecentDate];
}

#pragma mark - Count -

+ (NSInteger)countForExpensesInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetch = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];
    
    NSError *error = nil;
    NSUInteger count = [context countForFetchRequest:fetch error:&error];
    if (error) {
        NSLog(@"Could't fetc for count number of categories: %@", [error localizedDescription]);
    }
    return count;
}

+ (NSArray *)countForExpensesInContext:(NSManagedObjectContext *)context inEachMonth:(BOOL)countForMonth orInEachYear:(BOOL)countForYear {
    NSArray *dates = [self getOldestAndMostRecentDatesInContext:context];
    NSDate *oldestDate     = dates.firstObject;
    NSDate *mostRecentDate = dates.lastObject;
    
    BOOL currentTimePeriodAdded = NO;
    NSMutableArray *countForTimePeriod = [NSMutableArray new];
    
    if (oldestDate && mostRecentDate) {
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];
        [request setReturnsObjectsAsFaults:NO];
        
        while ([oldestDate compare:mostRecentDate] != NSOrderedDescending) {
            NSArray *dates;
            
            if (countForYear) {
                dates = [oldestDate startAndEndDatesOfYear];
            } else {
                dates = [oldestDate getFirstAndLastDatesFromMonth];
            }
            
            NSPredicate *predicate = [ExpenseData compoundPredicateBetweenDates:dates];
            request.predicate = predicate;
            
            NSError *error = nil;
            NSArray *objects = [context executeFetchRequest:request error:&error];
            if (error) {
                NSLog(@"Error %s %@", __PRETTY_FUNCTION__, [error localizedDescription]);
                return nil;
            }
            
            if (countForYear) {
                if ([[NSDate date]isDatesWithEqualYear:dates.firstObject]) {
                    currentTimePeriodAdded = YES;
                }
            } else {
                if ([[NSDate date]isDatesWithEqualMonth:dates.firstObject]) {
                    currentTimePeriodAdded = YES;
                }
            }
            
            if (objects.count > 0) {
                float amount = 0.0f;
                for (ExpenseData *expense in objects) {
                    if ([expense.dateOfExpense compare:[dates firstObject]] != NSOrderedAscending &&
                        [expense.dateOfExpense compare:[dates lastObject]]  != NSOrderedDescending) {
                        amount += [expense.amount floatValue];
                    }
                    [context refreshObject:expense mergeChanges:NO];
                }
                
                NSDictionary *components = [oldestDate getComponents];
                NSDictionary *info = @{@"year"   : components[@"year"],
                                       @"month"  : components[@"month"],
                                       @"amount" : @(amount)};
                
                [countForTimePeriod addObject:info];
            }
            
            if (countForYear) {
                oldestDate = [oldestDate nextYearFirstDate];
            } else {
                oldestDate = [oldestDate nextMonthFirstDate];
            }
            
        }
    }
    
    if (!currentTimePeriodAdded) {
        NSDictionary *components = [[NSDate date] getComponents];
        NSInteger currentYear    = [components[@"year"]integerValue];
        NSInteger currentMonth   = [components[@"month"]integerValue];
        
        NSDictionary *month = @{@"year"   : @(currentYear),
                                @"month"  : @(currentMonth),
                                @"amount" : @0};
        
        [countForTimePeriod addObject:month];
    }
    
    return [[countForTimePeriod reverseObjectEnumerator]allObjects];
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

#pragma mark - Data correction -

+ (void)checkForDataCorrectionInContext:(NSManagedObjectContext *)context {
    NSFetchRequest *request = [[NSFetchRequest alloc]initWithEntityName:NSStringFromClass([ExpenseData class])];
    request.predicate = [NSPredicate predicateWithFormat:@"category == nil && categoryId != nil"];
    request.returnsObjectsAsFaults = NO;
    
    NSError *error = nil;
    NSArray *fetchedExpenses = [context executeFetchRequest:request error:&error];
    
    if (error != nil) {
        NSLog(@"Eror fetching: %@", error.localizedDescription);
        return;
    }
    
    if (fetchedExpenses.count > 0) {
        NSLog(@"Expense data correction is in progress.");
        
        for (ExpenseData *expense in fetchedExpenses) {
            CategoryData *category = [CategoryData getCategoryFromIdValue:expense.categoryId.integerValue inManagedObjectContext:context];
            
            ExpenseData *newExpense = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ExpenseData class]) inManagedObjectContext:context];
            newExpense.amount = expense.amount;
            newExpense.categoryId = category.idValue;
            newExpense.dateOfExpense = expense.dateOfExpense;
            newExpense.descriptionOfExpense = expense.descriptionOfExpense;
            newExpense.idValue = @([ExpenseData nextId]);
            newExpense.category = category;
            [category addExpenseObject:expense];
            
            [context deleteObject:expense];
            [[Persistence sharedInstance]saveContext];
        }
        NSLog(@"%ld expenses are corrected.", (unsigned long)fetchedExpenses.count);
    }
}


@end
