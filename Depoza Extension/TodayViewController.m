//
//  TodayViewController.m
//  Depoza Extension
//
//  Created by Ivan Magda on 23.03.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>

    //CoreData
@import CoreData;
#import "Persistence.h"
#import "ExpenseData+Fetch.h"
#import "CategoryData.h"


@interface TodayViewController () <NCWidgetProviding, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) Persistence *persistence;

@end

@implementation TodayViewController {
    NSArray *_expenses;

    BOOL _isFirst;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _persistence = [Persistence sharedInstance];

    [self updateTableView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)updateTableView {
    _expenses = [ExpenseData expensesWithEqualDayWithDate:[NSDate date] managedObjectContext:_persistence.managedObjectContext];

    [self.tableView layoutIfNeeded];
    self.preferredContentSize = self.tableView.contentSize;
}

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsMake(0.0f, 8.0f, 16.0f, 8.0f);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _expenses.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSParameterAssert(cell);

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (NSString *)formatDate:(NSDate *)theDate {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [NSDateFormatter new];
        formatter.timeStyle = NSDateFormatterShortStyle;
    }
    return [formatter stringFromDate:theDate];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ExpenseData *expense = _expenses[indexPath.row];

    cell.textLabel.text = expense.category.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f, %@", [expense.amount floatValue], [self formatDate:expense.dateOfExpense]];
}


@end
