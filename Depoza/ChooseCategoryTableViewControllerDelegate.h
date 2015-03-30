//
//  ChooseCategoryTableViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ChooseCategoryTableViewController;
@class NSString;

@protocol ChooseCategoryTableViewControllerDelegate <NSObject>

- (void)chooseCategoryTableViewController:(ChooseCategoryTableViewController *)controller didFinishChooseCategoryName:(NSString *)category andIconName:(NSString *)iconName;

@end
