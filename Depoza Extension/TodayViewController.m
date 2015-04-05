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

#import "NSString+FormatAmount.h"

    //Declarations
static NSString * const kNumberExpensesToShowUserDefaultsKey = @"numberExpenseToShow";

static const CGFloat kDefaultRowHeight = 44.0f;

static const NSInteger kDefaultNumberExpensesToShow = 5;

typedef void (^UpdateBlock)(NCUpdateResult);


@interface TodayViewController () <NCWidgetProviding, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *noExpensesLabel;

@property (nonatomic, strong) Persistence *persistence;
@property (nonatomic, copy) UpdateBlock updateBlock;

@end

@implementation TodayViewController {
    NSArray *_expenses;
    NSUbiquitousKeyValueStore *_kvStore;
    NSInteger _numberExpensesToShow;
}

#pragma mark - ViewController Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.hidden = YES;
    self.noExpensesLabel.hidden = YES;

//    _persistence = [Persistence sharedInstance];
//
//    _expenses = [ExpenseData getTodayExpensesInManagedObjectContext:_persistence.managedObjectContext];
//
//    [self configurateUserDefaults];
//    [self updateUserInterfaceWithUpdateResult:NCUpdateResultNewData];
}

- (void)updateUserInterfaceWithUpdateResult:(NCUpdateResult)updateResult {
    if (_expenses == nil) {
        _expenses = [ExpenseData getTodayExpensesInManagedObjectContext:_persistence.managedObjectContext];
    }

    if (_expenses.count > 0 && updateResult == NCUpdateResultNewData) {
        self.tableView.hidden = NO;
        [self.tableView layoutIfNeeded];

        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             CGSize increasedTableViewContentSize = self.tableView.contentSize;
                                 //Increase height
                             increasedTableViewContentSize.height = increasedTableViewContentSize.height + kDefaultRowHeight/1.5f;
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
    _kvStore = [NSUbiquitousKeyValueStore defaultStore];

    _numberExpensesToShow = [[_kvStore objectForKey:kNumberExpensesToShowUserDefaultsKey]integerValue];
    if (_numberExpensesToShow == 0) {
        _numberExpensesToShow = kDefaultNumberExpensesToShow;
        [_kvStore setObject:@(_numberExpensesToShow) forKey:kNumberExpensesToShowUserDefaultsKey];
    }
}

#pragma mark - NCWidgetProviding -

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsZero;
}

    //A widget is not created every time you view the notification center so loadView won't be called every time it is displayed.
    //The notification center instead calls widgetPerformUpdateWithCompletionHandler when it thinks the widget information needs to be updated.
- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
//    self.updateBlock = completionHandler;
//    if ([Fetch hasNewExpensesForTodayInManagedObjectContext:self.persistence.managedObjectContext]) {
//        [self updateUserInterfaceWithUpdateResult:NCUpdateResultNewData];
//
//        self.updateBlock(NCUpdateResultNewData);
//    } else {
//        self.updateBlock(NCUpdateResultNoData);
//    }

    completionHandler(NCUpdateResultNewData);
}

#pragma mark - UITableView

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (_expenses.count > _numberExpensesToShow ? _numberExpensesToShow : _expenses.count);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    NSParameterAssert(cell);

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

        // Call the app and pass in a query string with the expense identifier
    NSParameterAssert(_expenses != nil);
    ExpenseData *selectedExpense = _expenses[indexPath.row];
    NSString *idValue = [NSString stringWithFormat:@"%@", selectedExpense.idValue];

    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"depoza://expense/?q=%@", idValue]];
    NSParameterAssert(url);
    NSLog(@"%@", url);

    [self.extensionContext openURL:url completionHandler:nil];
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

    NSString *amount = [NSString formatAmount:expense.amount];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@, %@", amount, [self formatDate:expense.dateOfExpense]];

        //Rangoon Green color
    UIView *selectedView = [[UIView alloc]init];
    selectedView.backgroundColor = [UIColor colorWithRed:0.1 green:0.09 blue:0.1 alpha:0.3];
    [cell setSelectedBackgroundView:selectedView];
}

@end
