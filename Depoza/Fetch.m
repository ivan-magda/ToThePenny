//
//  Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 26.01.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//
#import "Fetch.h"
#import "CategoriesInfo.h"
    //CoreData
#import "CategoryData+Fetch.h"
#import "ExpenseData+Fetch.h"
#import "Persistence.h"
#import "Expense.h"
    //Categories
#import "NSDate+FirstAndLastDaysOfMonth.h"
    //CoreSearch
#import "SearchableExtension.h"

static NSString * const kAppGroupSharedContainer = @"group.com.vanyaland.depoza";
static NSString * const kTodayExpensesKey = @"todayExpenses";

@implementation Fetch

+ (NSArray *)getObjectsWithEntity:(NSString *)entityName predicate:(NSPredicate *)predicate context:(NSManagedObjectContext *)context sortKey:(NSString *)key {
    NSAssert(entityName.length > 0, @"Entity must has a legal Name!");
    NSParameterAssert(context);

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];
    request.returnsObjectsAsFaults = NO;

    if (key) {
        NSSortDescriptor *sort = [[NSSortDescriptor alloc]initWithKey:key ascending:YES];
        [request setSortDescriptors:@[sort]];
    }

    if (predicate) {
        [request setPredicate:predicate];
    }

    NSError *error;
    NSArray *fetchedCategories = [context executeFetchRequest:request error:&error];
    if (error) {
        NSLog(@"***Error: %@", [error localizedDescription]);
    }

    return fetchedCategories;
}

+ (NSMutableArray *)loadCategoriesInfoInContext:(NSManagedObjectContext *)managedObjectContext totalExpenses:(CGFloat *)totalExpeditures andBetweenMonthDate:(NSDate *)date {
    Persistence *persistence = [Persistence sharedInstance];
    [persistence deduplication];

    NSArray *fetchedCategories = [self getObjectsWithEntity:NSStringFromClass([CategoryData class]) predicate:nil context:managedObjectContext sortKey:NSStringFromSelector(@selector(idValue))];

    NSMutableArray *categoriesInfo = [NSMutableArray arrayWithCapacity:[fetchedCategories count]];

    NSMutableSet *categoriesIds = [NSMutableSet setWithCapacity:fetchedCategories.count];

        //Create array of categories infos
    for (CategoryData *aData in fetchedCategories) {
        CategoriesInfo *info = [[CategoriesInfo alloc]initWithTitle:aData.title iconName:aData.iconName idValue:aData.idValue andAmount:@0];
        NSParameterAssert(info.title && info.idValue && info.amount);
        [categoriesInfo addObject:info];

            //Check for unique id values
        if (![categoriesIds containsObject:aData.idValue]) {
            [categoriesIds addObject:aData.idValue];

            NSLog(@"%@ %@", aData.title, aData.idValue);
        } else {
            NSLog(@"Categories must have a unique id values!!!");

            NSInteger newId = [CategoryData nextId];
            aData.idValue = @(newId);
            for (ExpenseData *expense in aData.expense) {
                expense.categoryId = @(newId);
                [managedObjectContext refreshObject:expense mergeChanges:YES];
            }
            [managedObjectContext save:nil];
        }
    }
    categoriesIds = nil;
    
    NSArray *days = [date getFirstAndLastDatesFromMonth];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
    [fetchRequest setRelationshipKeyPathsForPrefetching:@[NSStringFromSelector(@selector(expense))]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(expense, $x, ($x.dateOfExpense >= %@) AND ($x.dateOfExpense <= %@)).@count > 0)", [days firstObject], [days lastObject]];

    NSDate *start = [NSDate date];
    
    NSArray *categories = [managedObjectContext executeFetchRequest:fetchRequest error:nil];
    float __block summaForMonth = 0.0f;
    
    for (CategoryData *category in categories) {
        
        [categoriesInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CategoriesInfo *anInfo = obj;
            if (category.idValue == anInfo.idValue) {
                
                for (ExpenseData *expense in category.expense) {
                    
                    if ([expense.dateOfExpense compare:[days firstObject]] != NSOrderedAscending &&
                        [expense.dateOfExpense compare:[days lastObject]]  != NSOrderedDescending) {
                        anInfo.amount = @([anInfo.amount floatValue] + [expense.amount floatValue]);
                        summaForMonth += [expense.amount floatValue];
                    }
                    [managedObjectContext refreshObject:expense mergeChanges:NO];
                }
                *stop = YES;
            }
        }];
    }
    *totalExpeditures = summaForMonth;

    NSDate *end = [NSDate date];
    NSLog(@"Load categories data time execution: %f", [end timeIntervalSinceDate:start]);

    return categoriesInfo;
}

+ (void)updateTodayExpensesDictionaryInContext:(NSManagedObjectContext *)context {
        //Get info about todays expenses from user defaults
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc]initWithSuiteName:kAppGroupSharedContainer];

        //Get today components
    NSDictionary *dateComponents = [[NSDate date]getComponents];
    NSInteger year  = [dateComponents[@"year"]integerValue];
    NSInteger month = [dateComponents[@"month"]integerValue];
    NSInteger day   = [dateComponents[@"day"]integerValue];

    NSArray *expensesData = [ExpenseData getTodayExpensesInManagedObjectContext:context];
    NSMutableArray *expenses = [NSMutableArray arrayWithCapacity:expensesData.count];
    for (ExpenseData *expenseData in expensesData) {
        Expense *expense = [Expense expenseFromExpenseData:expenseData];
        [expenses addObject:expense];
    }
    [self updateTodayExpenses:[expenses copy] day:day month:month year:year userDefaults:userDefaults];
}

+ (NSDictionary *)setUpDictionaryWithYear:(NSInteger)year month:(NSInteger)month day:(NSInteger)day andExpenses:(NSArray *)expenses {
    NSDictionary *dictionary = @{
                                 @"year"     : @(year),
                                 @"month"    : @(month),
                                 @"day"      : @(day),
                                 @"expenses" : expenses
                                 };
    return dictionary;
}

+ (void)synchronizeUserDefaults:(NSUserDefaults *)userDefaults withDictionary:(NSDictionary *)dictionary {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:dictionary];
    [userDefaults setObject:data forKey:kTodayExpensesKey];
    [userDefaults synchronize];
}

+ (void)updateTodayExpenses:(NSArray *)expenses day:(NSInteger)day month:(NSInteger)month year:(NSInteger)year userDefaults:(NSUserDefaults *)userDefaults {
    NSDictionary *dictionaryInfo;
    dictionaryInfo = [self setUpDictionaryWithYear:year month:month day:day andExpenses:expenses];
    [self synchronizeUserDefaults:userDefaults withDictionary:dictionaryInfo];
}

+ (void)loadCategoriesInfoInContext:(NSManagedObjectContext *)managedObjectContext betweenDates:(NSArray *)dates withCompletionHandler:(FetchCompletionHandler)completionHandler {
    NSAssert(dates.count == 2, @"Number of dates must be 2");
    NSAssert(managedObjectContext != nil, @"NSManagedObjectContext must be not nil");

    NSArray *fetchedCategories = [self getObjectsWithEntity:NSStringFromClass([CategoryData class]) predicate:nil context:managedObjectContext sortKey:NSStringFromSelector(@selector(idValue))];

    NSMutableArray *categoriesInfo = [NSMutableArray arrayWithCapacity:[fetchedCategories count]];

        //Create array of categories infos
    for (CategoryData *category in fetchedCategories) {
        CategoriesInfo *info = [[CategoriesInfo alloc]initWithTitle:category.title iconName:category.iconName idValue:category.idValue andAmount:@0];

        [categoriesInfo addObject:info];
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
    [fetchRequest setRelationshipKeyPathsForPrefetching:@[NSStringFromSelector(@selector(expense))]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(expense, $x, ($x.dateOfExpense >= %@) AND ($x.dateOfExpense <= %@)).@count > 0)", [dates firstObject], [dates lastObject]];

    NSArray *categories = [managedObjectContext executeFetchRequest:fetchRequest error:nil];

    float __block countForTotalAmount = 0.0f;

    for (CategoryData *category in categories) {
        [categoriesInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CategoriesInfo *anInfo = obj;
            if (category.idValue == anInfo.idValue) {
                for (ExpenseData *expense in category.expense) {
                    if ([expense.dateOfExpense compare:[dates firstObject]] != NSOrderedAscending &&
                        [expense.dateOfExpense compare:[dates lastObject]]  != NSOrderedDescending) {
                        anInfo.amount = @([anInfo.amount floatValue] + [expense.amount floatValue]);
                        countForTotalAmount += [expense.amount floatValue];
                    }
                    [managedObjectContext refreshObject:expense mergeChanges:NO];
                }
                *stop = YES;
            }
        }];
    }

    if (completionHandler) {
        completionHandler([categoriesInfo copy], @(countForTotalAmount));
    }
}

@end
