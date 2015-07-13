//
//  NSDate+StartAndEndDatesOfTheCurrentDate.h
//  Depoza
//
//  Created by Ivan Magda on 08.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (StartAndEndDatesOfTheCurrentDate)

+ (NSArray *)getStartAndEndDatesOfTheCurrentDate;

- (NSArray *)getStartAndEndDatesFromDate;

@end
