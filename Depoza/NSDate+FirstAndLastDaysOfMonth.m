//
//  NSDate+FirstAndLastDaysOfMonth.m
//  Depoza
//
//  Created by Ivan Magda on 26.01.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation NSDate (FirstAndLastDaysOfMonth)

- (NSDictionary *)getComponents {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:self];

    NSDictionary *dictComponents = @{
                                     @"year"  : @([components year]),
                                     @"month" : @([components month]),
                                     @"day"   : @([components day])
                                     };
    return dictComponents;
}

+ (NSArray *)getDatesFromDate:(NSDate *)date sameDayOrFirstAndLastOfMonth:(BOOL)sameDay {
    NSDictionary *components = [date getComponents];

    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSRange days = [calendar rangeOfUnit:NSCalendarUnitDay
                                  inUnit:NSCalendarUnitMonth
                                 forDate:date];

    NSInteger year = [components[@"year"]integerValue];
    NSInteger month = [components[@"month"]integerValue];
    NSInteger day = [components[@"day"]integerValue];

    NSDateComponents *firstDayComponents = [[NSDateComponents alloc]init];
    firstDayComponents.year = year;
    firstDayComponents.month = month;
    firstDayComponents.day = (sameDay ? day : 1);
    firstDayComponents.hour = 0;
    firstDayComponents.minute = 0;
    firstDayComponents.second = 0;

    NSDateComponents *lastDayComponents = [[NSDateComponents alloc]init];
    lastDayComponents.year = year;
    lastDayComponents.month = month;
    lastDayComponents.day = (sameDay ? day : days.length);
    lastDayComponents.hour = 23;
    lastDayComponents.minute = 59;
    lastDayComponents.second = 59;

    NSDate *firstDay = [calendar dateFromComponents:firstDayComponents];
    NSDate *lastDay = [calendar dateFromComponents:lastDayComponents];

    NSAssert((firstDay != nil) && (lastDay != nil), @"Dates can't be nil!");

        //NSLog(@"%@", [firstDay descriptionWithLocale:[NSLocale currentLocale]]);
        //NSLog(@"%@", [lastDay descriptionWithLocale:[NSLocale currentLocale]]);

    return @[firstDay, lastDay];
}

+ (NSArray *)getFirstAndLastDatesFromCurrentMonth {
    return [NSDate getDatesFromDate:[NSDate date] sameDayOrFirstAndLastOfMonth:NO];
}

- (NSArray *)getFirstAndLastDatesFromMonth {
    NSArray *dates = [NSDate getDatesFromDate:self sameDayOrFirstAndLastOfMonth:NO];
    return dates;
}

@end
