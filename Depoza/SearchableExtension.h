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

@interface SearchableExtension : NSObject

- (void)indexCategories:(NSArray *)anArrayOfCategoies;
- (void)removeCategoriesFromIndex:(NSArray *)anArrayOfCategoies;

@end
