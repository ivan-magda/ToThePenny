//
//  SelectMonthViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 18.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class SelectMonthViewController;
@class NSDictionary;

@protocol SelectMonthViewControllerDelegate <NSObject>

- (void)selectMonthViewController:(SelectMonthViewController *)selectMonthViewController didSelectMonth:(NSDictionary *)monthInfo;

@end
