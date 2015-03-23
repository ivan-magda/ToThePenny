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
#import "CategoryData.h"
#import "ExpenseData.h"

    //Categories
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation Fetch

+ (NSArray *)getObjectsWithEntity:(NSString *)entityName predicate:(NSPredicate *)predicate context:(NSManagedObjectContext *)context sortKey:(NSString *)key {
    NSAssert(entityName.length > 0, @"Entity must has a legal Name!");
    NSParameterAssert(context);

    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];

    if (key) {
        NSSortDescriptor *sort = [[NSSortDescriptor alloc]initWithKey:key ascending:NO];
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

+ (NSMutableArray *)loadCategoriesInfoInContext:(NSManagedObjectContext *)managedObjectContext totalExpeditures:(double *)totalExpeditures {
    NSArray *fetchedCategories = [self getObjectsWithEntity:NSStringFromClass([CategoryData class]) predicate:nil context:managedObjectContext sortKey:NSStringFromSelector(@selector(title))];

    NSMutableArray *categoriesInfo = [NSMutableArray arrayWithCapacity:[fetchedCategories count]];

    NSParameterAssert(fetchedCategories != nil && [fetchedCategories count] > 0);
    for (CategoryData *aData in fetchedCategories) {
        CategoriesInfo *info = [[CategoriesInfo alloc]initWithTitle:aData.title idValue:aData.idValue andAmount:@0];
        NSParameterAssert(info.title && info.idValue && info.amount);
        [categoriesInfo addObject:info];
    }
    NSArray *days = [NSDate getFirstAndLastDaysInTheCurrentMonth];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
    [fetchRequest setRelationshipKeyPathsForPrefetching:@[NSStringFromSelector(@selector(expense))]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(expense, $x, ($x.dateOfExpense >= %@) AND ($x.dateOfExpense <= %@)).@count > 0)", [days firstObject], [days lastObject]];

    NSDate *start = [NSDate date];

    NSArray *categories = [managedObjectContext executeFetchRequest:fetchRequest error:nil];

    float __block countForExpenditures = 0.0f;

    for (CategoryData *category in categories) {
        [categoriesInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CategoriesInfo *anInfo = obj;
            if (category.idValue == anInfo.idValue) {
                for (ExpenseData *expense in category.expense) {
                    anInfo.amount = @([anInfo.amount floatValue] + [expense.amount floatValue]);
                    countForExpenditures += [expense.amount floatValue];

                [managedObjectContext refreshObject:expense mergeChanges:NO];
                }
                *stop = YES;
            }
        }];
    }
    *totalExpeditures = countForExpenditures;

    NSDate *end = [NSDate date];
    NSLog(@"Second version with subquery and prefetching time execution: %f", [end timeIntervalSinceDate:start]);

    return categoriesInfo;
}

@end
