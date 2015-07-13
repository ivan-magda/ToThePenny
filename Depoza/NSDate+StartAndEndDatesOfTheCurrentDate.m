//
//  NSDate+StartAndEndDatesOfTheCurrentDate.m
//  Depoza
//
//  Created by Ivan Magda on 08.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"

@implementation NSDate (StartAndEndDatesOfTheCurrentDate)

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

+ (NSArray *)getDatesFromDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDictionary *components = [date getComponents];
    NSInteger year = [components[@"year"]integerValue];
    NSInteger month = [components[@"month"]integerValue];
    NSInteger day = [components[@"day"]integerValue];
    
    NSDateComponents *startDateComponents = [NSDateComponents new];
    startDateComponents.year = year;
    startDateComponents.month = month;
    startDateComponents.day = day;
    startDateComponents.hour = 0;
    startDateComponents.minute = 0;
    startDateComponents.second = 0;
    
    NSDateComponents *endDateComponents = [NSDateComponents new];
    endDateComponents.year = year;
    endDateComponents.month = month;
    endDateComponents.day = day;
    endDateComponents.hour = 23;
    endDateComponents.minute = 59;
    endDateComponents.second = 59;
    
    NSDate *startDate = [calendar dateFromComponents:startDateComponents];
    NSDate *endDate = [calendar dateFromComponents:endDateComponents];
    
    NSAssert((startDate != nil) && (endDate != nil), @"Dates can't be nil!");
    
    /*
     NSLog(@"%@", [startDate descriptionWithLocale:[NSLocale currentLocale]]);
     NSLog(@"%@", [endDate descriptionWithLocale:[NSLocale currentLocale]]);
     */
    
    return @[startDate, endDate];
}

+ (NSArray *)getStartAndEndDatesOfTheCurrentDate {
    return [NSDate getDatesFromDate:[NSDate date]];
}

- (NSArray *)getStartAndEndDatesFromDate {
    return [NSDate getDatesFromDate:self];
}

@end
