//
//  NSDate+NextYearFirstDate.m
//  Depoza
//
//  Created by Ivan Magda on 13.07.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+NextYearFirstDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation NSDate (NextYearFirstDate)

- (NSDate *)nextYearFirstDate {
    NSDictionary *components = [self getComponents];
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSInteger year  = [components[@"year"]integerValue];
    
    NSDateComponents *nextYearComponents = [NSDateComponents new];
    nextYearComponents.year   = year + 1;
    nextYearComponents.month  = 1;
    nextYearComponents.day    = 1;
    nextYearComponents.hour   = 0;
    nextYearComponents.minute = 0;
    nextYearComponents.second = 0;
    
    NSDate *nextYearDate = [calendar dateFromComponents:nextYearComponents];
    NSParameterAssert(nextYearDate);
    
    return nextYearDate;
}

@end
