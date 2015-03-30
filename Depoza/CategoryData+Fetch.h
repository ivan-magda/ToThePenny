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

+ (NSInteger)countForCategoriesInContext:(NSManagedObjectContext *)context;
+ (void)synchronizeUserDefaultsWithNumberCategories:(NSInteger)categories;

+ (NSArray *)getAllTitlesInContext:(NSManagedObjectContext *)context;
+ (NSArray *)getCategoriesWithExpensesBetweenMonthOfDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context;

@end
