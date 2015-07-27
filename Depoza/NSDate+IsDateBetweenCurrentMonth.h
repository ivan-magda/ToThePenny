//
//  NSDate+IsDateBetweenCurrentMonth.h
//  Depoza
//
//  Created by Ivan Magda on 27.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (IsDateBetweenCurrentMonth)

+ (BOOL)isDateBetweenCurrentMonth:(NSDate *)dateToCompare;
- (BOOL)isDateBetweenMonth:(NSDate *)dateToCompare;

@end
