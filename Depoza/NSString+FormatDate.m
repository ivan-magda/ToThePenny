//
//  NSString+FormatDate.m
//  Depoza
//
//  Created by Ivan Magda on 07.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSString+FormatDate.h"
#import "NSDate+IsDateBetweenCurrentYear.h"

@implementation NSString (FormatDate)

+ (instancetype)formatDate:(NSDate *)date {
    static NSDateFormatter *defaultFormatter = nil;
    static NSDateFormatter *currentYearFormatter = nil;

    if (defaultFormatter == nil || currentYearFormatter == nil) {
        defaultFormatter = [NSDateFormatter new];
        [defaultFormatter setDateFormat:@"d MMM. YYYY"];

        currentYearFormatter = [NSDateFormatter new];
        [currentYearFormatter setDateFormat:@"d MMM."];
    }

    NSString *formatDate = nil;
    if ([date isDateBetweenCurrentYear]) {
        formatDate = [currentYearFormatter stringFromDate:date];
    } else {
        formatDate = [defaultFormatter stringFromDate:date];
    }

    NSInteger countForDot = [[formatDate componentsSeparatedByString:@"."]count] - 1;
    if (countForDot > 1) {
        NSRange range = [formatDate rangeOfString:@"."];
        NSParameterAssert(range.location != NSNotFound);
        range.length = 1;

        formatDate = [formatDate stringByReplacingCharactersInRange:range withString:@""];
    }
    
    return formatDate;
}

@end
