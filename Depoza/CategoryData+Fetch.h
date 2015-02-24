//
//  CategoryData+Fetch.h
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoryData.h"

@interface CategoryData (Fetch)

+ (NSInteger)nextId;

+ (NSInteger)countForCategoriesInContext:(NSManagedObjectContext *)context;
+ (CategoryData *)categoryFromTitle:(NSString *)category context:(NSManagedObjectContext *)context;
+ (CategoryData *)categoryDataWithName:(NSString *)name managedObjectContext:(NSManagedObjectContext *)context;
+ (void)synchronizeUserDefaultsWithNumberCategories:(NSInteger)categories;

+ (NSArray *)getAllTitlesInContext:(NSManagedObjectContext *)context;
+ (NSArray *)getCategoriesWithExpensesBetweenMonthOfDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context;

@end
