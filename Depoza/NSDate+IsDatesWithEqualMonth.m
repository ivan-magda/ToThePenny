//
//  NSDate+IsDatesWithEqualMonth.m
//  Depoza
//
//  Created by Ivan Magda on 19.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+IsDatesWithEqualMonth.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation NSDate (IsDatesWithEqualMonth)

- (BOOL)isDatesWithEqualMonth:(NSDate *)otherDate {
    NSDictionary *selfComponents = [self getComponents];
    NSInteger selfYear = [selfComponents[@"year"]integerValue];
    NSInteger selfMonth = [selfComponents[@"month"]integerValue];

    NSDictionary *otherComponents = [otherDate getComponents];
    NSInteger otherYear = [otherComponents[@"year"]integerValue];
    NSInteger otherMonth = [otherComponents[@"month"]integerValue];

    return (selfYear == otherYear && selfMonth == otherMonth);
}

@end
