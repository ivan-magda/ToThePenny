//
//  ExpenseData+Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 17.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "ExpenseData+Fetch.h"

@implementation ExpenseData (Fetch)

+ (NSInteger)nextId {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];

    NSInteger idValue = [userDefaults integerForKey:@"idValue"];
    [userDefaults setInteger:idValue + 1 forKey:@"idValue"];
    [userDefaults synchronize];

    return idValue;
}

@end
