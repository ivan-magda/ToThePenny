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

@property (nonatomic, strong) NSDate *timePeriod;

/*!
 * It's a bool value that define time period of expenses that should be shown.
 * If 'YES' than period formed from 2 dates. First date is a min date of found expense and
 * max date is a the most recent date of expense in selected category.
 * If 'NO' than period formed from 2 dates based on timePeriod property. Where first date it's
 * a start date of a month and end date is's a end date of a month.
 */
@property (nonatomic, assign, readwrite) BOOL timePeriodFromMinAndMaxDates;

@end
