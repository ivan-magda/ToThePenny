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
static const CGFloat kDefaultRowHeight = 44.0f;

typedef void (^UpdateBlock)(NCUpdateResult);

@interface TodayViewController () <NCWidgetProviding, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *noExpensesLabel;

@property (nonatomic, strong) Persistence *persistence;
@property (nonatomic, copy) UpdateBlock updateBlock;

@end

@implementation TodayViewController {
    NSArray *_expenses;
    NSUserDefaults *_userDefaults;
    NSInteger _numberExpensesToShow;
}

#pragma mark - ViewController Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.hidden = YES;
    self.noExpensesLabel.hidden = YES;

    _persistence = [Persistence sharedInstance];

    _expenses = [ExpenseData expensesWithEqualDayWithDate:[NSDate date] managedObjectContext:_persistence.managedObjectContext];

    [self configurateUserDefaults];
    [self updateUserInterfaceWithUpdateResult:NCUpdateResultNewData];
}

- (void)updateUserInterfaceWithUpdateResult:(NCUpdateResult)updateResult {
    _expenses = [ExpenseData expensesWithEqualDayWithDate:[NSDate date] managedObjectContext:_persistence.managedObjectContext];
    if (_expenses.count > 0 && updateResult == NCUpdateResultNewData) {
        self.tableView.hidden = NO;
        [self.tableView layoutIfNeeded];

        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             CGSize increasedTableViewContentSize = self.tableView.contentSize;
                                 //Increase height
                             increasedTableViewContentSize.height = increasedTableViewContentSize.height + kDefaultRowHeight/2;
                             self.preferredContentSize = increasedTableViewContentSize;

                             self.tableView.alpha = 1.0f;
                             self.noExpensesLabel.alpha = 0.0f;
                         } completion:^(BOOL finished) {
                             self.noExpensesLabel.hidden = YES;
                         }];
    } else if (_expenses.count == 0 && updateResult == NCUpdateResultNewData) {
        self.noExpensesLabel.hidden = NO;

        CGSize labelSize = CGSizeMake(CGRectGetWidth(self.noExpensesLabel.bounds), CGRectGetHeight(self.noExpensesLabel.bounds) * 2);

        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.preferredContentSize = labelSize;

                             self.noExpensesLabel.alpha = 1.0f;
                             self.tableView.alpha = 0.0f;
                         } completion:^(BOOL finished) {
                             self.tableView.hidden = YES;
                         }];
    }
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

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    self.updateBlock = completionHandler;
    if ([Fetch isNewExpensesForTodayInManagedObjectContext:self.persistence.managedObjectContext]) {
        [self updateUserInterfaceWithUpdateResult:NCUpdateResultNewData];

        self.updateBlock(NCUpdateResultNewData);
    } else {
        self.updateBlock(NCUpdateResultNoData);
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

- (NSString *)formatAmount:(NSNumber *)amount {
    static NSNumberFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.currencyCode = [[NSLocale currentLocale]objectForKey:NSLocaleCurrencyCode];
    }
    return [formatter stringFromNumber:amount];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ExpenseData *expense = _expenses[indexPath.row];

    cell.textLabel.text = expense.category.title;
    cell.textLabel.textColor = [UIColor whiteColor];

    NSString *amount = [self formatAmount:expense.amount];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", amount, [self formatDate:expense.dateOfExpense]];

    UIView *selectedView = [[UIView alloc]init];
    selectedView.backgroundColor = [UIColor colorWithRed:0.1 green:0.09 blue:0.1 alpha:0.2];
    [cell setSelectedBackgroundView:selectedView];
}

@end
