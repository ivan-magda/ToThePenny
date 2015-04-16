//
//  CategoryData+Fetch.h
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoryData.h"

@interface CategoryData (Fetch)

+ (CategoryData *)categoryDataWithTitle:(NSString *)title iconName:(NSString *)iconName andExpenses:(NSSet *)expenses inManagedObjectContext:(NSManagedObjectContext *)context;
+ (CategoryData *)categoryFromTitle:(NSString *)category context:(NSManagedObjectContext *)context;

+ (NSInteger)nextId;
+ (void)setNextIdValueToUserDefaults:(NSInteger)categories;
+ (NSInteger)countForCategoriesInContext:(NSManagedObjectContext *)context;


+ (NSArray *)getAllTitlesInContext:(NSManagedObjectContext *)context;
+ (NSDictionary *)getIconsNamesAllCategoriesInContext:(NSManagedObjectContext *)context;

+ (NSArray *)getCategoriesWithExpensesBetweenMonthOfDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context;

+ (NSArray *)getCategoryFromIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSInteger)countForIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context;

@end
