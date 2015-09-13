//
//  SearchableExtensions.m
//  Depoza
//
//  Created by Ivan Magda on 11.09.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

#import "SearchableExtension.h"
    //DataModel
#import "CategoriesInfo.h"

NSString * const CategoryDomainID = @"com.vanyaland.ToThePenny.category";
NSString * const ExpenseDomainID  = @"com.vanyaland.ToThePenny.expense";

@implementation SearchableExtension

- (void)indexCategories:(NSArray *)anArrayOfCategoies {
    NSMutableArray *categoriesItems = [NSMutableArray arrayWithCapacity:anArrayOfCategoies.count];
    
    for (CategoriesInfo *category in anArrayOfCategoies) {
        [categoriesItems addObject:category.searchableItem];
    }
    
    [[CSSearchableIndex defaultSearchableIndex]indexSearchableItems:categoriesItems completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error indexing shopping categories: %@", [error localizedDescription]);
        } else {
            NSLog(@"Indexing categories successful");
        }
    }];
}

- (void)removeCategoriesFromIndex:(NSArray *)anArrayOfCategoies {
    NSMutableArray *idsToDelete = [NSMutableArray arrayWithCapacity:anArrayOfCategoies.count];
    
    for (CategoriesInfo *category in anArrayOfCategoies) {
        [idsToDelete addObject:[NSString stringWithFormat:@"%@",category.idValue]];
    }
    
    [[CSSearchableIndex defaultSearchableIndex]deleteSearchableItemsWithIdentifiers:idsToDelete completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error deleting categories from index, %@", [error localizedDescription]);
        } else {
            NSLog(@"Successfully deleted categories from index");
        }
    }];
}

@end
