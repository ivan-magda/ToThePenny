//
//  NSDate+BeginningOfDay.m
//  Depoza
//
//  Created by Ivan Magda on 15.07.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+BeginningOfDay.h"
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"

@implementation NSDate (BeginningOfDay)

+ (NSDate *)getBeginningOfDayDateFromDate:(NSDate *)date {
    return [date getStartAndEndDatesFromDate].firstObject;
}

@end
