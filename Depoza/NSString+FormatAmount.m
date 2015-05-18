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
        formatter.numberStyle = kCFNumberFormatterDecimalStyle;
        formatter.minimumFractionDigits = 2;
    }
    NSString *formattedString = [formatter stringFromNumber:amount];

    NSString *countryCode = [[NSLocale currentLocale]objectForKey:NSLocaleCountryCode];
    if ([countryCode isEqualToString:@"RU"]) {
        return [formattedString stringByReplacingOccurrencesOfString:@",00" withString:@""];
    } else {
        return [formattedString stringByReplacingOccurrencesOfString:@".00" withString:@""];
    }
}

@end
