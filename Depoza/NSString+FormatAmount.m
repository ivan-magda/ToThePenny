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
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    NSLocale *ruLocale = [NSLocale localeWithLocaleIdentifier:@"ru_RU"];
    formatter.locale = ruLocale;
    formatter.numberStyle = kCFNumberFormatterDecimalStyle;
    formatter.minimumFractionDigits = 2;
    formatter.maximumFractionDigits = 2;
    
    NSString *formattedString = [formatter stringFromNumber:amount];
    
    return [formattedString stringByReplacingOccurrencesOfString:@",00" withString:@""];
}

@end
