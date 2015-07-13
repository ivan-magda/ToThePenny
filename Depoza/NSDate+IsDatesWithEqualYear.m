//
//  NSDate+IsDatesWithEqualYear.m
//  Depoza
//
//  Created by Ivan Magda on 13.07.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "NSDate+IsDatesWithEqualYear.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@implementation NSDate (IsDatesWithEqualYear)

- (BOOL)isDatesWithEqualYear:(NSDate *)otherDate {
    NSDictionary *selfComponents = [self getComponents];
    NSInteger selfYear = [selfComponents[@"year"]integerValue];
    
    NSDictionary *otherComponents = [otherDate getComponents];
    NSInteger otherYear = [otherComponents[@"year"]integerValue];
    
    return (selfYear == otherYear);
}

@end
