//
//  Fetch.h
//  Depoza
//
//  Created by Ivan Magda on 26.01.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NSManagedObjectContext;
@class CategoryData;

@interface Fetch : NSObject

+ (NSArray *)getObjectsWithEntity:(NSString *)entityName predicate:(NSPredicate *)predicate context:(NSManagedObjectContext *)context sortKey:(NSString *)key;

+ (NSMutableArray *)loadCategoriesDataInContext:(NSManagedObjectContext *)context totalExpeditures:(double *)totalExpeditures;

+ (CategoryData *)findCategoryFromTitle:(NSString *)category context:(NSManagedObjectContext *)context;

@end
