//
//  NSDate+IsDatesWithEqualDate.m
//  Depoza
//
//  Created by Ivan Magda on 10.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+IsDatesWithEqualDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation NSDate (IsDatesWithEqualDate)

- (BOOL)isDatesWithEqualDates:(NSDate *)otherDate {
    NSDictionary *selfComponents = [self getComponents];
    NSInteger selfYear  = [selfComponents[@"year"]integerValue];
    NSInteger selfMonth = [selfComponents[@"month"]integerValue];
    NSInteger selfDay   = [selfComponents[@"day"]integerValue];

    NSDictionary *otherComponents = [otherDate getComponents];
    NSInteger otherYear  = [otherComponents[@"year"]integerValue];
    NSInteger otherMonth = [otherComponents[@"month"]integerValue];
    NSInteger otherDay   = [otherComponents[@"day"]integerValue];

    return (selfYear == otherYear && selfMonth == otherMonth && selfDay == otherDay);
}

@end
