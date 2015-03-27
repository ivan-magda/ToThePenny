//
//  NSString+FormatAmount.m
//  Depoza
//
//  Created by Ivan Magda on 27.03.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSString+FormatAmount.h"

@implementation NSString (FormatAmount)

+ (NSString *)formatAmount:(NSNumber *)amount {
    static NSNumberFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.currencyCode = [[NSLocale currentLocale]objectForKey:NSLocaleCurrencyCode];
    }
    return [formatter stringFromNumber:amount];
}

@end
