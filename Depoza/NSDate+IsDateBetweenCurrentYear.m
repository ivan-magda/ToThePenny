//
//  NSDate+IsDateBetweenCurrentYear.m
//  Depoza
//
//  Created by Ivan Magda on 06.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+IsDateBetweenCurrentYear.h"
#import "NSDate+StartAndEndDatesOfYear.h"

@implementation NSDate (IsDateBetweenCurrentYear)

- (BOOL)isDateBetweenCurrentYear {
    NSArray *startAndEndDatesOfYear = [[NSDate date]startAndEndDatesOfYear];
    NSDate *startDate = [startAndEndDatesOfYear firstObject];
    NSDate *endDate = [startAndEndDatesOfYear lastObject];

        //dateToCompare >= startDate && dateToCompare <= endDate
    BOOL isBetween = ([self compare:startDate] == NSOrderedSame ||
                      [self compare:startDate] == NSOrderedDescending) &&
                     ([self compare:endDate]   == NSOrderedSame ||
                      [self compare:endDate]   == NSOrderedAscending);
    return isBetween;
}

@end
