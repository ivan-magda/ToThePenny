//
//  AddCategoryViewController.h
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CategoryData;
@class NSManagedObjectContext;

extern NSString * const ManageCategoryTableViewControllerDidAddCategoryNotification;
extern NSString * const ManageCategoryTableViewControllerDidUpdateCategoryNotification;

@interface ManageCategoryTableViewController : UITableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) CategoryData *categoryToEdit;

@end
