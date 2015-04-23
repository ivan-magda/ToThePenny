//
//  CategoriesContainerViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 20.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CategoriesContainerViewController;
@class CategoriesInfo;

@protocol CategoriesContainerViewControllerDelegate <NSObject>

- (void)categoriesContainerViewController:(CategoriesContainerViewController *)controller didChooseCategory:(CategoriesInfo *)category;

@end
