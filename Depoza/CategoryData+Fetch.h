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

+ (CategoryData *)categoryFromTitle:(NSString *)category context:(NSManagedObjectContext *)context;
+ (CategoryData *)categoryDataWithName:(NSString *)name managedObjectContext:(NSManagedObjectContext *)context;

+ (NSArray *)getAllTitlesInContext:(NSManagedObjectContext *)context;
+ (NSArray *)getCategoriesWithExpensesBetweenMonthOfDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context;

@end
