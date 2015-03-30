//
//  MainViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 24.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MainViewController;
@class NSArray;

@protocol MainViewControllerDelegate <NSObject>

- (void)mainViewController:(MainViewController *)mainViewController didLoadCategoriesInfo:(NSArray *)categoriesData;
- (void)mainViewController:(MainViewController *)mainViewController didUpdateCategoriesInfo:(NSArray *)categoriesData;

@end
