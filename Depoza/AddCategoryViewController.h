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

@interface AddCategoryViewController : UITableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) NSString *iconName;

@property (nonatomic, strong) id<AddCategoryViewControllerDelegate> delegate;

- (IBAction)done:(id)sender;

@end
