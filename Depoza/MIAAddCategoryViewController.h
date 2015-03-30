//
//  AddCategoryViewController.h
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AddCategoryViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface MIAAddCategoryViewController : UITableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) id<MIAAddCategoryViewControllerDelegate> delegate;

@property (nonatomic, copy) NSString *iconName;

- (NSArray *)iconNames;

- (IBAction)done:(id)sender;

@end
