//
//  SelectMonthViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 18.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SelectTimePeriodViewController;
@class NSDictionary;

@protocol SelectTimePeriodViewControllerDelegate <NSObject>

- (void)selectTimePeriodViewController:(SelectTimePeriodViewController *)selectMonthViewController didSelectValue:(NSDictionary *)info;

@end
