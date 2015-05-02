//
//  CategoriesTableViewController.h
//  Depoza
//
//  Created by Ivan Magda on 02.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString * const CategoriesTableViewControllerDidRemoveCategoryNotification;

@interface CategoriesTableViewController : UITableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
