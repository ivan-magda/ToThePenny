//
//  NSDate+IsDateBetweenCurrentMonth.m
//  Depoza
//
//  Created by Ivan Magda on 27.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+IsDateBetweenCurrentMonth.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation NSDate (IsDateBetweenCurrentMonth)

+ (BOOL)isDateBetweenCurrentMonth:(NSDate *)dateToCompare {
    NSArray *dates = [NSDate getFirstAndLastDatesFromCurrentMonth];
    NSDate *startDate = dates.firstObject;
    NSDate *endDate = dates.lastObject;

        //dateToCompare >= startDate && dateToCompare <= endDate
    BOOL isBetween = ([dateToCompare compare:startDate] == NSOrderedSame ||
                      [dateToCompare compare:startDate] == NSOrderedDescending) &&
                     ([dateToCompare compare:endDate]   == NSOrderedSame ||
                      [dateToCompare compare:endDate]   == NSOrderedAscending);

    return isBetween;
}

- (BOOL)isDateBetweenMonth:(NSDate *)dateToCompare {
    NSArray *dates = [self getFirstAndLastDatesFromMonth];
    NSDate *startDate = dates.firstObject;
    NSDate *endDate = dates.lastObject;
    
    //dateToCompare >= startDate && dateToCompare <= endDate
    BOOL isBetween = ([dateToCompare compare:startDate] == NSOrderedSame ||
                      [dateToCompare compare:startDate] == NSOrderedDescending) &&
    ([dateToCompare compare:endDate]   == NSOrderedSame ||
     [dateToCompare compare:endDate]   == NSOrderedAscending);
    
    return isBetween;
}

@end
