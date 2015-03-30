//
//  CategoriesData.m
//  Depoza
//
//  Created by Ivan Magda on 26.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoriesInfo.h"

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

@end
