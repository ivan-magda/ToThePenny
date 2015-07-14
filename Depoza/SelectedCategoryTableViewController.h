//
//  SelectedCategoryTableViewController.h
//  Depoza
//
//  Created by Ivan Magda on 19.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CategoriesInfo;

@interface SelectedCategoryTableViewController : UITableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) CategoriesInfo *selectedCategory;

@property (nonatomic, strong) NSArray *timePeriodDates;

@end
