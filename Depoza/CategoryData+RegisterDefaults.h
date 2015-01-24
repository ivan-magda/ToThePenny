//
//  CategoryData+RegisterDefaults.h
//  Depoza
//
//  Created by Ivan Magda on 24.01.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoryData.h"

@class SharedManagedObjectContext;

@interface CategoryData (RegisterDefaultsCategories)

+ (void)registerDefaultsCategoriesInSharedContext:(SharedManagedObjectContext *)context;

@end
