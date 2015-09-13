//
//  SearchableExtensions.h
//  Depoza
//
//  Created by Ivan Magda on 11.09.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

@import UIKit;
@import CoreSpotlight;
@import MobileCoreServices;

extern NSString * const CategoryDomainID;
extern NSString * const ExpenseDomainID;

@class NSManagedObjectContext;

@interface SearchableExtension : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

- (void)indexCategories:(NSArray *)categoies;
- (void)removeCategoriesFromIndex:(NSArray *)categoies;

-(void)indexExpenses:(NSArray *)expenses;
- (void)removeExpensesFromIndex:(NSArray *)expenses;

@end
