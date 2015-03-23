//
//  NSDate+FirstAndLastDaysOfMonth.h
//  Depoza
//
//  Created by Ivan Magda on 26.01.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (FirstAndLastDaysOfMonth)

- (NSDictionary *)getComponents;

+ (NSArray *)getDatesFromDate:(NSDate *)date sameDayOrFirstAndLastOfMonth:(BOOL)sameDay;

+ (NSArray *)getFirstAndLastDaysInTheCurrentMonth;

- (NSArray *)getFirstAndLastDaysInTheCurrentMonth;

@end
