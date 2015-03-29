//
//  SettingsTableViewController.h
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NSManagedObjectContext;

@interface MIASettingsTableViewController : UITableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
