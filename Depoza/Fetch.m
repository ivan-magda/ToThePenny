//
//  Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 26.01.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "Fetch.h"

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

+ (NSMutableArray *)loadCategoriesDataInContext:(NSManagedObjectContext *)context totalExpeditures:(double *)totalExpeditures {
    NSArray *fetchedCategories = [self getObjectsWithEntity:NSStringFromClass([CategoryData class]) predicate:nil context:context sortKey:NSStringFromSelector(@selector(title))];

    NSMutableArray *categoriesData = [NSMutableArray arrayWithCapacity:[fetchedCategories count]];

    NSParameterAssert(fetchedCategories != nil && [fetchedCategories count] > 0);
    for (CategoryData *aData in fetchedCategories) {
        NSMutableDictionary *category = [@{@"title"    : aData.title,
                                           @"id"       : aData.idValue,
                                           @"expenses" : @0
                                           }mutableCopy];
        [categoriesData addObject:category];
    }
    NSArray *days = [NSDate getFirstAndLastDaysInTheCurrentMonth];

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
    [fetchRequest setRelationshipKeyPathsForPrefetching:@[NSStringFromSelector(@selector(expense))]];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"(SUBQUERY(expense, $x, ($x.dateOfExpense >= %@) AND ($x.dateOfExpense <= %@)).@count > 0)", [days firstObject], [days lastObject]];

    NSDate *start = [NSDate date];

    NSArray *categories = [context executeFetchRequest:fetchRequest error:nil];

    float __block countForExpenditures = 0.0f;

    for (CategoryData *category in categories) {
        [categoriesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dictionary = (NSDictionary *)obj;
            if (category.idValue == dictionary[@"id"]) {
                for (ExpenseData *expense in category.expense) {
                    [categoriesData[idx] setObject:@([categoriesData[idx][@"expenses"]floatValue] + [expense.amount floatValue]) forKey:@"expenses"];

                    countForExpenditures += [expense.amount floatValue];

                    [context refreshObject:expense mergeChanges:NO];
                }
                *stop = YES;
            }
        }];
    }
    *totalExpeditures = countForExpenditures;

    NSDate *end = [NSDate date];
    NSLog(@"Second version with subquery and prefetching time execution: %f", [end timeIntervalSinceDate:start]);

    return categoriesData;
}

+ (CategoryData *)findCategoryFromTitle:(NSString *)category context:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title = %@", category];
    [fetchRequest setPredicate:predicate];

    NSError *error;
    NSArray *foundCategory = [context executeFetchRequest:fetchRequest error:&error];

    if (error) {
        NSLog(@"***Error: %@", [error localizedDescription]);
    }
    
    NSParameterAssert([foundCategory count] == 1);
    NSParameterAssert([[foundCategory firstObject]isKindOfClass:[CategoryData class]]);

    return [foundCategory firstObject];
}

@end
