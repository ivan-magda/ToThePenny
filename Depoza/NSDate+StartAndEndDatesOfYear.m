//
//  NSDate+StartAndEndDatesOfYear.m
//  Depoza
//
//  Created by Ivan Magda on 03.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+StartAndEndDatesOfYear.h"

@implementation NSDate (StartAndEndDatesOfYear)

- (NSArray *)startAndEndDatesOfYear {
    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSDateComponents * firstDayComponents = [calendar components: NSCalendarUnitYear fromDate:self];
    firstDayComponents.hour = 0;
    firstDayComponents.minute = 0;
    firstDayComponents.second = 0;
    NSDate *startOfYear = [calendar dateFromComponents:firstDayComponents];


    NSDateComponents *components = [NSDateComponents new];
    [components setMonth:12];

    NSRange range = [calendar rangeOfUnit:NSCalendarUnitDay
                              inUnit:NSCalendarUnitMonth
                             forDate:[calendar dateFromComponents:components]];

    NSDateComponents *endOfYearComponents = [calendar components:NSCalendarUnitYear fromDate:self];
    endOfYearComponents.month = 12;
    endOfYearComponents.day = range.length;
    endOfYearComponents.hour = 23;
    endOfYearComponents.minute = 59;
    endOfYearComponents.second = 59;
    NSDate *endOfYear = [calendar dateFromComponents:endOfYearComponents];

    NSAssert((startOfYear != nil) && (endOfYear != nil), @"Dates can't be nil!");

        //NSLog(@"%@", [startOfYear descriptionWithLocale:[NSLocale currentLocale]]);
        //NSLog(@"%@", [endOfYear descriptionWithLocale:[NSLocale currentLocale]]);

    return @[startOfYear, endOfYear];
}

@end
