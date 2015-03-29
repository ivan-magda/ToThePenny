//
//  MainViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 24.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIAMainViewController;
@class NSArray;

@protocol MIAMainViewControllerDelegate <NSObject>

- (void)mainViewController:(MIAMainViewController *)mainViewController didLoadCategoriesInfo:(NSArray *)categoriesData;
- (void)mainViewController:(MIAMainViewController *)mainViewController didUpdateCategoriesInfo:(NSArray *)categoriesData;

@end
