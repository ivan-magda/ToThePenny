//
//  CategoriesData.m
//  Depoza
//
//  Created by Ivan Magda on 26.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoriesInfo.h"

@implementation CategoriesInfo

- (instancetype)initWithTitle:(NSString *)title adValue:(NSNumber *)idValue amount:(NSNumber *)amount {
    if (self = [super init]) {
        _title = title;
        _idValue = idValue;
        _amount = amount;
    }
    return self;
}

@end
