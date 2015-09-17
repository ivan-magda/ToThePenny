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
#import "CategoryData+Fetch.h"
#import "Expense.h"

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
            NSLog(@"Error indexing categories: %@", [error localizedDescription]);
        } else {
            NSLog(@"Indexing categories successful");
        }
    }];
}

- (void)removeCategoriesFromIndex:(NSArray *)anArrayOfCategoies {
    NSMutableArray *idsToDelete = [NSMutableArray arrayWithCapacity:anArrayOfCategoies.count];
    
    for (CategoriesInfo *category in anArrayOfCategoies) {
        [idsToDelete addObject:[NSString stringWithFormat:@"category.%@",category.idValue]];
    }
    
    [[CSSearchableIndex defaultSearchableIndex]deleteSearchableItemsWithIdentifiers:idsToDelete completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error deleting categories from index, %@", [error localizedDescription]);
        } else {
            NSLog(@"Successfully deleted categories from index");
        }
    }];
}

- (void)indexExpenses:(NSArray *)expenses {
    NSMutableArray *expensesItems = [NSMutableArray arrayWithCapacity:expenses.count];
    
    for (Expense *anExpense in expenses) {
        if (!anExpense.searchableItem) {
            continue;
        }
        
        if (self.managedObjectContext) {
            CSSearchableItem *item = anExpense.searchableItem;
            
            CategoryData *category = [CategoryData categoryFromTitle:anExpense.category context:_managedObjectContext];
            
            UIImage *thumbnail = [UIImage imageNamed:category.iconName];
            item.attributeSet.thumbnailData = UIImageJPEGRepresentation(thumbnail, 1.0);
            
            [expensesItems addObject:item];
        } else {
            [expensesItems addObject:anExpense.searchableItem];
        }
    }
    
    [[CSSearchableIndex defaultSearchableIndex]indexSearchableItems:expensesItems completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error indexing expenses: %@", [error localizedDescription]);
        } else {
            NSLog(@"Indexing expenses successful");
        }
    }];
}

- (void)removeExpensesFromIndex:(NSArray *)expenses {
    NSMutableArray *idsToDelete = [NSMutableArray arrayWithCapacity:expenses.count];
    
    for (Expense *anExpense in expenses) {
        [idsToDelete addObject:[NSString stringWithFormat:@"expense.%@",@(anExpense.idValue)]];
    }
    
    [[CSSearchableIndex defaultSearchableIndex]deleteSearchableItemsWithIdentifiers:idsToDelete completionHandler:^(NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error deleting expenses from index, %@", [error localizedDescription]);
        } else {
            NSLog(@"Successfully deleted expenses from index");
        }
    }];
}

@end
