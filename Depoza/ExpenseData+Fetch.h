//
//  ExpenseData+Fetch.h
//  Depoza
//
//  Created by Ivan Magda on 17.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "ExpenseData.h"

@class NSManagedObjectContext;

@interface ExpenseData (Fetch)

+ (NSInteger)nextId;
+ (void)setNextIdValueToUserDefaults:(NSInteger)expenses;

+ (NSInteger)countForExpensesInContext:(NSManagedObjectContext *)context;
+ (NSInteger)countForIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSArray *)getTodayExpensesInManagedObjectContext:(NSManagedObjectContext *)context;

+ (ExpenseData *)getExpenseFromIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSPredicate *)compoundPredicateBetweenDates:(NSArray *)dates;

+ (NSDate *)oldestDateExpenseInManagedObjectContext:(NSManagedObjectContext *)context;
+ (NSDate *)mostRecentDateExpenseInManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSArray *)getEachMonthWithSumExpensesInManagedObjectContext:(NSManagedObjectContext *)context;

@end
