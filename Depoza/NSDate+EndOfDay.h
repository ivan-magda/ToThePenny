//
//  NSDate+EndOfDay.h
//  Depoza
//
//  Created by Ivan Magda on 15.07.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (EndOfDay)

+ (NSDate *)getEndOfDayDateFromDate:(NSDate *)date;

@end
