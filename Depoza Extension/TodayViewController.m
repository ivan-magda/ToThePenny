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
#import "Persistence.h"
#import "ExpenseData+Fetch.h"
#import "CategoryData.h"
#import "Fetch.h"

static NSString * const kAppGroupSharedContainer = @"group.com.vanyaland.depoza";

@interface TodayViewController () <NCWidgetProviding, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *noExpensesLabel;
@property (nonatomic, strong) Persistence *persistence;

@end

@implementation TodayViewController {
    NSArray *_expenses;
    NSUserDefaults *_userDefaults;
    NSInteger _numberExpensesToShow;
}

#pragma mark - ViewController Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    _persistence = [Persistence sharedInstance];

    _expenses = [ExpenseData expensesWithEqualDayWithDate:[NSDate date] managedObjectContext:_persistence.managedObjectContext];

    [self configurateUserDefaults];

    [self.tableView layoutIfNeeded];

    self.noExpensesLabel.textColor = [UIColor whiteColor];

    [UIView animateWithDuration:0.25
                          delay:0.0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         if (_expenses.count > 0) {
                             self.preferredContentSize = self.tableView.contentSize;

                             self.noExpensesLabel.hidden = YES;
                         } else {
                             self.tableView.hidden = YES;
                         }
                     } completion:nil];
}

#pragma mark Helpers

- (void)configurateUserDefaults {
    _userDefaults = [[NSUserDefaults alloc]initWithSuiteName:kAppGroupSharedContainer];

    _numberExpensesToShow = [_userDefaults integerForKey:@"numberExpenseToShow"];
    if (_numberExpensesToShow == 0) {
        _numberExpensesToShow = 5;
        [_userDefaults setInteger:_numberExpensesToShow forKey:@"numberExpenseToShow"];
    }
}

#pragma mark - NCWidgetProviding -

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    if ([Fetch isNewExpensesForTodayInManagedObjectContext:self.persistence.managedObjectContext]) {
        completionHandler(NCUpdateResultNewData);
    } else {
        completionHandler(NCUpdateResultNoData);
    }
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (_expenses.count > _numberExpensesToShow ? _numberExpensesToShow : _expenses.count);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSParameterAssert(cell);

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

#pragma mark UITableView Helpers

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
    cell.textLabel.textColor = [UIColor whiteColor];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f, %@", [expense.amount floatValue], [self formatDate:expense.dateOfExpense]];

    UIView *selectedView = [[UIView alloc]init];
    selectedView.backgroundColor = [UIColor colorWithRed:0.1 green:0.09 blue:0.1 alpha:0.2];
    [cell setSelectedBackgroundView:selectedView];
}

@end
