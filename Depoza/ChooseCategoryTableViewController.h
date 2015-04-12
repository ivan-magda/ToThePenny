//
//  ChooseCategoryTableViewController.h
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ChooseCategoryTableViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface ChooseCategoryTableViewController : UITableViewController

@property (nonatomic, strong) NSArray *titles;
@property (nonatomic, copy) NSString *originalCategoryName;
@property (nonatomic, copy) NSString *iconName;

@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) id<ChooseCategoryTableViewControllerDelegate> delegate;

@end
