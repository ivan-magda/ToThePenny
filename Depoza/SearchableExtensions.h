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

@class CategoriesInfo;

@interface SearchableExtensions : NSObject

@property (nonatomic, strong) CSSearchableItemAttributeSet *searchableAttributeSet;
@property (nonatomic, copy) NSArray *categoryKeywords;

+ (instancetype)searchableExtensionsWithCategory:(CategoriesInfo *)category;

@end
