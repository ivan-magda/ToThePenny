//
//  CategoriesData.m
//  Depoza
//
//  Created by Ivan Magda on 26.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoriesInfo.h"
#import "CategoryData.h"
    //CoreSearch
#import "SearchableExtension.h"
@import CoreSpotlight;
    //Categories
#import "NSString+FormatAmount.h"

@implementation CategoriesInfo

- (instancetype)initWithTitle:(NSString *)title iconName:(NSString *)iconName idValue:(NSNumber *)idValue andAmount:(NSNumber *)amount {
    if (self = [super init]) {
        _title = title;
        _idValue = idValue;
        _amount = amount;
        _iconName = iconName;
    }
    return self;
}

+ (instancetype)categoryInfoFromCategoryData:(CategoryData *)category {
    return [[CategoriesInfo alloc]initWithTitle:category.title iconName:category.iconName idValue:category.idValue andAmount:@0];
}

- (CSSearchableItemAttributeSet *)searchableAttributeSet {
    if (!_searchableAttributeSet) {
        NSString *title = self.title;
        
        _searchableAttributeSet = [[CSSearchableItemAttributeSet alloc]initWithItemContentType:(NSString *)kUTTypeContent];
        
        NSString *contentDescription = nil;
        if ([self.amount floatValue] > 0.0f) {
            contentDescription = [NSString stringWithFormat:@"%@ %@.", NSLocalizedString(@"Spent this month", @"Category expenses amount this month for searcheble set"), [NSString formatAmount:self.amount]];
        } else {
            contentDescription = NSLocalizedString(@"No expenses this month.", @"No expenses message for searcheble set");
        }
        _searchableAttributeSet.contentDescription = contentDescription;
        _searchableAttributeSet.title = title;
        _searchableAttributeSet.displayName = title;
        _searchableAttributeSet.keywords = @[title];
        
        UIImage *thumbnail = [UIImage imageNamed:self.iconName];
        _searchableAttributeSet.thumbnailData = UIImageJPEGRepresentation(thumbnail, 1.0);
    }
    return _searchableAttributeSet;
}

- (CSSearchableItem *)searchableItem {
    if (!_searchableItem) {
        _searchableItem = [[CSSearchableItem alloc]initWithUniqueIdentifier:[NSString stringWithFormat:@"category.%@",_idValue] domainIdentifier:CategoryDomainID attributeSet:self.searchableAttributeSet];
    }
    return _searchableItem;
}

@end
