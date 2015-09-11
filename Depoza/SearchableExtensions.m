//
//  SearchableExtensions.m
//  Depoza
//
//  Created by Ivan Magda on 11.09.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

#import "SearchableExtensions.h"
#import "CategoriesInfo.h"

@implementation SearchableExtensions

+ (instancetype)searchableExtensionsWithCategory:(CategoriesInfo *)category {
    SearchableExtensions *searchableExtensions = [SearchableExtensions new];
    
    [searchableExtensions prepareSearchableAttributeSetFromCategory:category];
    
    return searchableExtensions;
}

- (void)prepareSearchableAttributeSetFromCategory:(CategoriesInfo *)category {
    NSString *title = category.title;
    
    _searchableAttributeSet = [[CSSearchableItemAttributeSet alloc]initWithItemContentType:(NSString *)kUTTypeContent];
    //self.searchableAttributeSet.contentDescription = @"TEST";
    self.searchableAttributeSet.title = title;
    self.searchableAttributeSet.displayName = title;
    
    _categoryKeywords = @[title];
    self.searchableAttributeSet.keywords = _categoryKeywords;
    
    UIImage *thumbnail = [UIImage imageNamed:category.iconName];
    self.searchableAttributeSet.thumbnailData = UIImageJPEGRepresentation(thumbnail, 0.7);
}

@end
