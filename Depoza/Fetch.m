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

    //category
#import "NSDate+FirstAndLastDaysOfMonth.h"


@implementation Fetch

+ (NSArray *)getObjectsWithEntity:(NSString *)entityName predicate:(NSPredicate *)predicate context:(NSManagedObjectContext *)context sortKey:(NSString *)key
{
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

    *totalExpeditures = 0.0f;

    for (int i = 0; i < [categoriesData count]; ++i) {
        NSNumber *idValue = [categoriesData[i]objectForKey:@"id"];

        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((dateOfExpense >= %@) and (dateOfExpense <= %@)) and categoryId = %@", [days firstObject], [days lastObject], idValue];

        NSArray *fetchedExpenses = [self getObjectsWithEntity:NSStringFromClass([ExpenseData class]) predicate:predicate context:context sortKey:nil];

        if (fetchedExpenses && [fetchedExpenses count] > 0) {
            for (ExpenseData *aData in fetchedExpenses) {
                NSParameterAssert(aData.categoryId == categoriesData[i][@"id"]);

                [categoriesData[i] setObject:@([categoriesData[i][@"expenses"]floatValue] + [aData.amount floatValue]) forKey:@"expenses"];

                *totalExpeditures += [aData.amount floatValue];
            }
        }
    }
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
