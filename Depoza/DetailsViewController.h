//
//  DetailsViewController.h
//  Depoza
//
//  Created by Ivan Magda on 24/12/14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ExpenseData;
@class NSManagedObjectContext;

@interface DetailsViewController : UIViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) ExpenseData *expenseToShow;

@end
