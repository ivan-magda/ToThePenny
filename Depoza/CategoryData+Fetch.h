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

+ (NSArray *)getAllCategoriesInContext:(NSManagedObjectContext *)context;
+ (NSArray *)getCategoriesInContext:(NSManagedObjectContext *)context usingPredicate:(NSPredicate *)predicate;

+ (NSArray *)getCategoriesTitleAndIconNameInContext:(NSManagedObjectContext *)context;
+ (NSArray *)getAllTitlesInContext:(NSManagedObjectContext *)context;
+ (NSDictionary *)getAllIconsNameInContext:(NSManagedObjectContext *)context;

+ (NSArray *)getCategoriesWithExpensesBetweenMonthOfDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context;

+ (CategoryData *)getCategoryFromIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSInteger)countForIdValue:(NSInteger)idValue inManagedObjectContext:(NSManagedObjectContext *)context;

+ (NSArray *)sumOfExpensesInManagedObjectContext:(NSManagedObjectContext *)context usingPredicate:(NSPredicate *)predicate;

+ (NSUInteger)countForFrequencyUseInManagedObjectContext:(NSManagedObjectContext *)context betweenDates:(NSArray *)dates andWithCategoryIdValue:(NSNumber *)categoryId;

+ (BOOL)checkForUniqueName:(NSString *)name managedObjectContext:(NSManagedObjectContext *)context;

@end
