//
//  NSDate+EndOfDay.m
//  Depoza
//
//  Created by Ivan Magda on 15.07.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+EndOfDay.h"
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"

@implementation NSDate (EndOfDay)

+ (NSDate *)getEndOfDayDateFromDate:(NSDate *)date {
    return [date getStartAndEndDatesFromDate].lastObject;
}

@end
