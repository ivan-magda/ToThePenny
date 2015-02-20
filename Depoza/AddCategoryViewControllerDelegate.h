//
//  AddCategoryViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 20.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AddCategoryViewController;
@class CategoryData;

@protocol AddCategoryViewControllerDelegate <NSObject>

- (void)addCategoryViewController:(AddCategoryViewController *)controller didFinishAddingCategory:(CategoryData *)category;

@end
