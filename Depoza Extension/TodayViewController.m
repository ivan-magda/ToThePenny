    //
    //  TodayViewController.m
    //  Depoza Extension
    //
    //  Created by Ivan Magda on 23.03.15.
    //  Copyright (c) 2015 Ivan Magda. All rights reserved.
    //

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
    //View
#import "CustomRightDetailCell.h"
    //Data
#import "Expense.h"
    //Categories
#import "NSString+FormatAmount.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

    //Declarations
static NSString * const kAppGroupSharedContainer = @"group.com.vanyaland.depoza";
static NSString * const kTodayExpensesKey = @"todayExpenses";
static NSString * const kNumberExpensesToShowUserDefaultsKey = @"numberExpenseToShow";
static NSString * const kDetailViewControllerPresentingFromExtensionKey = @"DetailViewPresenting";

static NSString * const kCustomRightDetailCellIdentifier = @"Cell";

static const CGFloat kDefaultRowHeight = 44.0f;

static const NSInteger kDefaultNumberExpensesToShow = 5;

typedef void (^UpdateBlock)(NCUpdateResult);


@interface TodayViewController () <NCWidgetProviding, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UILabel *noExpensesLabel;

@property (nonatomic, copy) UpdateBlock updateBlock;

@end

@implementation TodayViewController {
    NSArray *_expenses;
    NSUserDefaults *_userDefaults;
    NSInteger _numberExpensesToShow;

    Expense *_mostRecentExpense;
}

#pragma mark - ViewController Life Cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.hidden = YES;
    self.noExpensesLabel.hidden = YES;

    [self configurateUserDefaults];

    _expenses = [self getTodayExpenses];
    _mostRecentExpense = [_expenses firstObject];

    [self updateUserInterfaceWithUpdateResult:NCUpdateResultNewData];
}

- (void)updateUserInterfaceWithUpdateResult:(NCUpdateResult)updateResult {
    if (_expenses == nil) {
        _expenses = [self getTodayExpenses];
    }

    [_userDefaults setBool:NO forKey:kDetailViewControllerPresentingFromExtensionKey];
    [_userDefaults synchronize];

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

- (NSArray *)getTodayExpenses {
    NSData *data = [_userDefaults objectForKey:kTodayExpensesKey];
    NSDictionary *expenseDictionary = [NSKeyedUnarchiver unarchiveObjectWithData:data];

        //Get today components
    NSDictionary *dateComponents = [[NSDate date]getComponents];
    NSInteger year  = [dateComponents[@"year"]integerValue];
    NSInteger month = [dateComponents[@"month"]integerValue];
    NSInteger day   = [dateComponents[@"day"]integerValue];

    if ([expenseDictionary[@"day"]integerValue]   == day &&
        [expenseDictionary[@"month"]integerValue] == month &&
        [expenseDictionary[@"year"]integerValue]  == year) {
        NSArray *expenses = expenseDictionary[@"expenses"];

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO];

        return [expenses sortedArrayUsingDescriptors:@[sortDescriptor]];
    }

    return nil;
}

- (void)configurateUserDefaults {
    _userDefaults = [[NSUserDefaults alloc]initWithSuiteName:kAppGroupSharedContainer];

    _numberExpensesToShow = [_userDefaults integerForKey:kNumberExpensesToShowUserDefaultsKey];
    if (_numberExpensesToShow == 0) {
        _numberExpensesToShow = kDefaultNumberExpensesToShow;
        [_userDefaults setInteger:_numberExpensesToShow forKey:kNumberExpensesToShowUserDefaultsKey];
        [_userDefaults synchronize];
    }
}

#pragma mark - NCWidgetProviding -

- (UIEdgeInsets)widgetMarginInsetsForProposedMarginInsets:(UIEdgeInsets)defaultMarginInsets {
    return UIEdgeInsetsMake(defaultMarginInsets.top, 0, 0, 0);
}

    //A widget is not created every time you view the notification center so loadView won't be called every time it is displayed.
    //The notification center instead calls widgetPerformUpdateWithCompletionHandler when it thinks the widget information needs to be updated.
- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    self.updateBlock = completionHandler;

    _expenses = [self getTodayExpenses];
    if (![_mostRecentExpense isEqual:_expenses.firstObject]) {
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
    NSString *identifier = @"Cell";
    CustomRightDetailCell *cell = (CustomRightDetailCell *)[tableView dequeueReusableCellWithIdentifier:identifier];

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    [_userDefaults setBool:YES forKey:kDetailViewControllerPresentingFromExtensionKey];
    [_userDefaults synchronize];

        // Call the app and pass in a query string with the expense identifier
    NSParameterAssert(_expenses != nil);
    Expense *selectedExpense = _expenses[indexPath.row];
    NSString *idValue = [NSString stringWithFormat:@"%@", @(selectedExpense.idValue)];

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

- (void)configureCell:(CustomRightDetailCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Expense *expense = _expenses[indexPath.row];

    cell.leftLabel.text = (expense.descriptionOfExpense.length == 0 ? expense.category : expense.descriptionOfExpense);
    cell.rightDetailLabel.text = [NSString formatAmount:expense.amount];

        //Rangoon Green color
    UIView *selectedView = [[UIView alloc]init];
    selectedView.backgroundColor = [UIColor colorWithRed:0.1 green:0.09 blue:0.1 alpha:0.3];
    [cell setSelectedBackgroundView:selectedView];
}

@end
