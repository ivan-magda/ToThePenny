//
//  CategoriesData.h
//  Depoza
//
//  Created by Ivan Magda on 26.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CategoryData;
@class CSSearchableItem;
@class CSSearchableItemAttributeSet;

@interface CategoriesInfo : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *iconName;
@property (nonatomic, assign) NSNumber *idValue;
@property (nonatomic, strong) NSNumber *amount;

@property (nonatomic, strong) CSSearchableItem *searchableItem;
@property (nonatomic, strong) CSSearchableItemAttributeSet *searchableAttributeSet;

- (instancetype)initWithTitle:(NSString *)title iconName:(NSString *)iconName idValue:(NSNumber *)idValue andAmount:(NSNumber *)amount;

+ (instancetype)categoryInfoFromCategoryData:(CategoryData *)category;

@end
