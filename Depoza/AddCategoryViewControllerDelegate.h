//
//  AddCategoryViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 20.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIAAddCategoryViewController;
@class CategoryData;

@protocol MIAAddCategoryViewControllerDelegate <NSObject>

- (void)addCategoryViewController:(MIAAddCategoryViewController *)controller didFinishAddingCategory:(CategoryData *)category;

@end
