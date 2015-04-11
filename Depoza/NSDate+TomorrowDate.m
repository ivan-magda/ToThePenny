//
//  NSDate+TomorrowDate.m
//  Depoza
//
//  Created by Ivan Magda on 11.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+TomorrowDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation NSDate (TomorrowDate)

- (NSDate *)tomorrowDate {
    NSDictionary *components = [self getComponents];

    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSInteger year = [components[@"year"]integerValue];
    NSInteger month = [components[@"month"]integerValue];
    NSInteger day = [components[@"day"]integerValue];

    NSDateComponents *tomorrowComponents = [[NSDateComponents alloc]init];
    tomorrowComponents.year = year;
    tomorrowComponents.month = month;
    tomorrowComponents.day = day + 1;
    tomorrowComponents.hour = 0;
    tomorrowComponents.minute = 0;
    tomorrowComponents.second = 0;

    NSDate *tomorrow = [calendar dateFromComponents:tomorrowComponents];
    NSParameterAssert(tomorrow);

    return tomorrow;
}

@end
