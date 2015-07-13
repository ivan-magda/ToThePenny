//
//  PieChartViewController.h
//  Depoza
//
//  Created by Ivan Magda on 03.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NSManagedObjectContext;

@interface PieChartTableViewController : UITableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSDate *dateToShow;

@end
