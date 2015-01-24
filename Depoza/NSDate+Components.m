//
//  NSDate+Components.m
//  Depoza
//
//  Created by Ivan Magda on 23.01.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+Components.h"

@implementation NSDate (Components)

+ (NSDictionary *)getComponentsFromDate:(NSDate *)date {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *components = [calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:date];

    NSDictionary *dictComponents = @{
                                     @"year"  : @([components year]),
                                     @"month" : @([components month]),
                                     @"day"   : @([components day])
                                     };
    return dictComponents;
}

@end
