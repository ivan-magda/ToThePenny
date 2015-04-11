//
//  NSDate+NextMonthFirstDate.m
//  Depoza
//
//  Created by Ivan Magda on 11.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+NextMonthFirstDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation NSDate (NextMonthFirstDate)

- (NSDate *)nextMonthFirstDate {
    NSDictionary *components = [self getComponents];

    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSRange days = [calendar rangeOfUnit:NSCalendarUnitDay
                                  inUnit:NSCalendarUnitMonth
                                 forDate:self];

    NSInteger year = [components[@"year"]integerValue];
    NSInteger month = [components[@"month"]integerValue];

    NSDateComponents *nextMonthComponents = [[NSDateComponents alloc]init];
    nextMonthComponents.year = year;
    nextMonthComponents.month = month;
    nextMonthComponents.day = days.length + 1;
    nextMonthComponents.hour = 0;
    nextMonthComponents.minute = 0;
    nextMonthComponents.second = 0;

    NSDate *nextMonthDate = [calendar dateFromComponents:nextMonthComponents];
    NSParameterAssert(nextMonthDate);

    return nextMonthDate;
}

@end
