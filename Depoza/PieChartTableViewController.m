//
//  PieChartViewController.m
//  Depoza
//
//  Created by Ivan Magda on 03.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//
    // ViewControllers
#import "PieChartTableViewController.h"
#import "SelectTimePeriodViewController.h"
#import "SelectedCategoryTableViewController.h"
#import "HSDatePickerViewController.h"
    // CoreData
#import "ExpenseData+Fetch.h"
#import "CategoriesInfo.h"
#import "Fetch.h"
    // Categories
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"
#import "NSDate+StartAndEndDatesOfYear.h"
#import "NSDate+IsDatesWithEqualDate.h"
#import "NSDate+IsDatesWithEqualMonth.h"
#import "NSDate+IsDatesWithEqualYear.h"
#import "NSString+FormatAmount.h"
    // View
#import "PieChartTableViewCell.h"
    // Frameworks
#import <CorePlot.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

typedef NS_ENUM(NSUInteger, ShowBy) {
    ShowByDay,
    ShowByMonth,
    ShowByYear
};

static NSString * const kPieChartTableViewCellIdentifier = @"PieChartTableViewCell";

@interface PieChartTableViewController () <CPTPlotDataSource, CPTPieChartDataSource, CPTPieChartDelegate, SelectTimePeriodViewControllerDelegate, HSDatePickerViewControllerDelegate>

@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTTheme *theme;

@property (weak, nonatomic) IBOutlet UIButton *selectDateButton;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UIView *pieChartView;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSDateFormatter *monthAndYearLabelDateFormater;

@end

@implementation PieChartTableViewController {
    NSMutableArray *_categoriesInfo;
    NSNumber *_totalAmount;
    NSArray *_colors;
}

#pragma mark - UIViewController lifecycle methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _colors = @[@0xFF7F7F, @0x00FF99, @0x00FFFF, @0xFFFF00, @0xFFCC00, @0xFFCCFF, @0xCCFF00, @0xCCFFFF, @0xCCCC00, @0x33FFC0, @0xFF9900, @0xFF66FF, @0xCC99FF, @0x99FF00, @0x99FFFF, @0x9999FF, @0x99CCFF, @0x66FF00, @0x66FFCC, @0xFFFFCC, @0x00FF00, @0x66FFFF, @0x6699FF, @0xFF0000];
    
    [self configurateNavigationBar];
    
    self.segmentedControl.selectedSegmentIndex = ShowByMonth;
    
    [self updateTransactionsData];
    [self updateLabels];

    [self initPlot];
}

#pragma mark - Helper methods -

- (void)updateTransactionsData {
    NSArray *dates = [self getDatesForLoadCategoriesData];
    
    __weak PieChartTableViewController *weakSelf = self;
    
    [Fetch loadCategoriesInfoInContext:_managedObjectContext betweenDates:dates withCompletionHandler:^(NSArray *fetchedCategories, NSNumber *totalAmount) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(amount)) ascending:NO];
        NSMutableArray *sortedCategories = [[fetchedCategories sortedArrayUsingDescriptors:@[sortDescriptor]]mutableCopy];
        
        [weakSelf removeCategoriesWithoutTransactionsFrom:sortedCategories];
        
        _categoriesInfo = sortedCategories;
        _totalAmount = totalAmount;
    }];
}

- (NSArray *)getDatesForLoadCategoriesData {
    NSArray *dates;
    
    switch (self.segmentedControl.selectedSegmentIndex) {
        case ShowByDay: {
            dates = [_dateToShow getStartAndEndDatesFromDate];
            break;
        }
        case ShowByMonth: {
            dates = [_dateToShow getFirstAndLastDatesFromMonth];
            break;
        }
        case ShowByYear: {
            dates = [_dateToShow startAndEndDatesOfYear];
            break;
        }
        default:
            break;
    }
    NSParameterAssert(dates != nil);
    
    return dates;
}

- (void)updateLabels {
    self.amountLabel.text = [NSString formatAmount:_totalAmount];
    
    [self.selectDateButton setTitle:[self formatDate:_dateToShow] forState:UIControlStateNormal];
    [self.selectDateButton sizeToFit];
}

- (NSString *)formatDate:(NSDate *)date {
    static NSDateFormatter *dayFormatter   = nil;
    static NSDateFormatter *monthFormatter = nil;
    static NSDateFormatter *yearFormatter  = nil;
    
    switch (self.segmentedControl.selectedSegmentIndex) {
        case ShowByDay: {
            if (!dayFormatter) {
                dayFormatter = [NSDateFormatter new];
                [dayFormatter setDateFormat:@"d MMMM YYYY"];
            }
            return [dayFormatter stringFromDate:date];
        }
        case ShowByMonth: {
            if (!monthFormatter) {
                monthFormatter = [NSDateFormatter new];
                [monthFormatter setDateFormat:@"MMMM YYYY"];
                
                [self setRuMonthSymbols:monthFormatter];
            }
            return [monthFormatter stringFromDate:date];
        }
        case ShowByYear: {
            if (!yearFormatter) {
                yearFormatter = [NSDateFormatter new];
                [yearFormatter setDateFormat:@"YYYY"];
            }
            return [yearFormatter stringFromDate:date];
        }
        default:
            break;
    }
    return nil;
}

- (void)setRuMonthSymbols:(NSDateFormatter *)monthFormatter {
    if ([[[NSLocale currentLocale]objectForKey:NSLocaleCountryCode]isEqualToString:@"RU"]) {
        [monthFormatter setMonthSymbols:@[@"Январь", @"Февраль", @"Март", @"Апрель", @"Май", @"Июнь", @"Июль", @"Август", @"Сентябрь", @"Октябрь", @"Ноябрь", @"Декабрь"]];
    }
}

- (void)reloadData {
    [self updateTransactionsData];
    [self updateLabels];
    
    [self.hostView.hostedGraph reloadData];
    [self animateChartWithOpacity];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)removeCategoriesWithoutTransactionsFrom:(NSMutableArray *)categoriesInfo {
    NSMutableIndexSet *indexSet = [NSMutableIndexSet new];
    
    [categoriesInfo enumerateObjectsUsingBlock:^(CategoriesInfo *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.amount floatValue] == 0.0f) {
            [indexSet addIndex:idx];
        }
    }];
    
    [categoriesInfo removeObjectsAtIndexes:indexSet];
}

- (void)configurateNavigationBar {
    self.segmentedControl = [[UISegmentedControl alloc]initWithItems:@[NSLocalizedString(@"Day", @"Day"), NSLocalizedString(@"Month", @"Month"), NSLocalizedString(@"Year", @"Year")]];
    [_segmentedControl addTarget:self action:@selector(segmentedControlDidChangeValue:) forControlEvents:UIControlEventValueChanged];
    
    for (int i = 0; i < self.segmentedControl.numberOfSegments; ++i) {
        [self.segmentedControl setWidth:66.0f forSegmentAtIndex:(NSInteger)i];
    }
    
    self.navigationItem.titleView = self.segmentedControl;
}

- (NSNumber *)calculatePercentageValueForAmount:(NSNumber *)amount andTotalAmount:(NSNumber *)totalAmount {
    return @(amount.floatValue / totalAmount.floatValue * 100.0f);
}

- (UIColor *)getUIColorForIndex:(NSUInteger)index {
    if (index >= _colors.count) {
        return ([CPTPieChart defaultPieSliceColorForIndex:index].uiColor);
    }
    
    int value = [_colors[index] intValue];
    
    return UIColorFromRGB(value);
}

#pragma mark - CPTPlotDataSource -

    //return number of categories
- (NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return _categoriesInfo.count;
}

    //return amount of expenses in special category
- (NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    if (CPTPieChartFieldSliceWidth == fieldEnum) {
        CategoriesInfo *category = _categoriesInfo[index];
        return category.amount;
    }
    return @0;
}

- (CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index {
        //Define label text style
    static CPTMutableTextStyle *labelText = nil;
    if (!labelText) {
        labelText = [CPTMutableTextStyle new];
        labelText.color = [CPTColor blackColor];
        labelText.fontName = @".SFUIText-Light";
        labelText.fontSize = 14.0f;
    }
    
    CategoriesInfo *category = _categoriesInfo[index];
    NSNumber *percentValue = [self calculatePercentageValueForAmount:category.amount andTotalAmount:_totalAmount];
    if (percentValue.floatValue < 4.0f) {
        return nil;
    }
    
        //Set up display label
    NSString *labelValue = [NSString stringWithFormat:@"%0.1f %%", percentValue.floatValue];
    
        //Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:labelValue style:labelText];
}

- (CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index {
    UIColor *color = [self getUIColorForIndex:index];
    CPTFill *fillColor = [CPTFill fillWithColor:[CPTColor colorWithCGColor:color.CGColor]];
    
    return fillColor;
}

#pragma mark - CPTPieChartDelegate -

- (void)pieChart:(CPTPieChart *)plot sliceWasSelectedAtRecordIndex:(NSUInteger)idx {
    CategoriesInfo *selectedCategory = _categoriesInfo[idx];
    [self performSegueWithIdentifier:@"CategorySelected" sender:selectedCategory];
}

#pragma mark - Chart behavior -

- (void)initPlot {
    [self configureHost];
    [self configureGraph];
    [self configureChart];
}

- (void)configureHost {
    CGRect hostViewRect = self.pieChartView.bounds;
    
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:hostViewRect];
    self.hostView.allowPinchScaling = NO;
    
    [self.pieChartView addSubview:self.hostView];
}

- (void)configureGraph {
        //Create and initialize graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    
    self.hostView.hostedGraph = graph;
    self.theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    
    [graph applyTheme:self.theme];
    graph.paddingLeft   = 0.0f;
    graph.paddingTop    = 0.0f;
    graph.paddingRight  = 0.0f;
    graph.paddingBottom = 0.0f;
    graph.axisSet = nil;
    graph.plotAreaFrame.borderLineStyle = nil;
}

- (void)configureChart {
        //Get reference to graph
    CPTGraph *graph = self.hostView.hostedGraph;
        //Create chart
    CPTPieChart *pieChart = [CPTPieChart new];
    pieChart.dataSource = self;
    pieChart.delegate   = self;
    pieChart.pieRadius  = (CGRectGetHeight(self.hostView.bounds) * 0.95f) / 2.0f;
    pieChart.pieInnerRadius = pieChart.pieRadius / 3.0f;
    pieChart.identifier = graph.title;
    pieChart.startAngle = M_PI_4;
    pieChart.sliceDirection = CPTPieDirectionClockwise;
    pieChart.labelOffset = -pieChart.pieInnerRadius * 1.7f;
    pieChart.labelRotationRelativeToRadius = YES;
        //Add chart to graph
    [graph addPlot:pieChart];
    
    [self animateChartWithOpacity];
}

- (void)animateChartWithOpacity {
    CPTGraph *graph = self.hostView.hostedGraph;
    graph.opacity = 0.0f;
    
    CABasicAnimation *fadeInAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeInAnimation.duration = 1.0f;
    fadeInAnimation.removedOnCompletion = NO;
    fadeInAnimation.fillMode = kCAFillModeForwards;
    fadeInAnimation.toValue = @1.0;
    [graph addAnimation:fadeInAnimation forKey:@"animateOpacity"];
}

#pragma mark - UITableViewDataSource -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _categoriesInfo.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return (PieChartTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kPieChartTableViewCellIdentifier];
}

- (void)configuratePieChartTableViewCell:(PieChartTableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoriesInfo *category = _categoriesInfo[(NSInteger)indexPath.row];
    
    cell.coloredCategoryView.backgroundColor    = [self getUIColorForIndex:(NSInteger)indexPath.row];
    cell.coloredCategoryView.layer.cornerRadius = (CGRectGetHeight(cell.coloredCategoryView.bounds) / 2.0f);
    cell.categoryTitleLabel.text = category.title;
    cell.amountLabel.text   = [NSString formatAmount:category.amount];
    cell.categoryIcon.image = [UIImage imageNamed:category.iconName];
    
    NSNumber *percent = [self calculatePercentageValueForAmount:category.amount andTotalAmount:_totalAmount];
    cell.percentLabel.text = [NSString stringWithFormat:@"%0.1f %%", percent.floatValue];
    
    UIView *separator = [[UIView alloc]initWithFrame: CGRectMake(15.0f, 64.0f - 0.5f, self.tableView.bounds.size.width - 15.0f, 0.5f)];
    separator.backgroundColor = self.tableView.separatorColor;
    
    [cell addSubview:separator];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (_categoriesInfo.count == 0) {
        return nil;
    }
    UIView *separator = [UIView new];
    separator.backgroundColor = self.tableView.separatorColor;
    
    return separator;
}

#pragma mark - UITableViewDelegate -

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configuratePieChartTableViewCell:(PieChartTableViewCell *)cell forRowAtIndexPath:indexPath];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return (_categoriesInfo.count == 0 ? 0.0f : 0.5f);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"CategorySelected"]) {
        SelectedCategoryTableViewController *controller = segue.destinationViewController;
        controller.managedObjectContext = _managedObjectContext;
        
        CategoriesInfo *category = nil;
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
            
            category = _categoriesInfo[(NSInteger)indexPath.row];
        } else if ([sender isKindOfClass:[CategoriesInfo class]]) {
            category = (CategoriesInfo *)sender;
        }
        
        NSParameterAssert(category != nil);
        
        controller.selectedCategory = category;
        controller.timePeriodDates  = [self getDatesForLoadCategoriesData];
    }

}

#pragma mark - HandleActions -

- (void)segmentedControlDidChangeValue:(UISegmentedControl *)segmentedControl {
    UIScrollView *scrollView = (UIScrollView *)self.tableView;
    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0.0f) animated:YES];
    
    CGFloat delay = (scrollView.contentOffset.y > 0 ? 0.45f : 0.0f);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        _dateToShow = [NSDate date];
        [self reloadData];
    });
}

- (SelectTimePeriodViewController *)getConfiguratedSelectTimePeriodViewController {
    SelectTimePeriodViewController *selectTimePeriodViewController = [[SelectTimePeriodViewController alloc]initWithNibName:NSStringFromClass([SelectTimePeriodViewController class]) bundle:nil];
    selectTimePeriodViewController.managedObjectContext = self.managedObjectContext;
    selectTimePeriodViewController.delegate = self;
    
    return selectTimePeriodViewController;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [NSDateFormatter new];
        [_dateFormatter setDateFormat:@"ccc d MMMM"];
    }
    return _dateFormatter;
}

- (NSDateFormatter *)monthAndYearLabelDateFormater {
    if (!_monthAndYearLabelDateFormater) {
        _monthAndYearLabelDateFormater = [NSDateFormatter new];
        [_monthAndYearLabelDateFormater setDateFormat:@"MMMM yyyy"];
        [self setRuMonthSymbols:_monthAndYearLabelDateFormater];
    }
    return _monthAndYearLabelDateFormater;
}

- (IBAction)selectDateButtonPressed:(UIButton *)sender {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case ShowByDay: {
            HSDatePickerViewController *hsdpvc = [HSDatePickerViewController new];
            hsdpvc.delegate = self;
            hsdpvc.date = _dateToShow;
            hsdpvc.minuteStep = StepFifteenMinutes;
            hsdpvc.minDate = [ExpenseData oldestDateExpenseInManagedObjectContext:_managedObjectContext];
            
            NSDate *maxDate = [ExpenseData mostRecentDateExpenseInManagedObjectContext:_managedObjectContext];
            if ([maxDate compare:[NSDate date]] == NSOrderedAscending) {
                maxDate = [NSDate getStartAndEndDatesOfTheCurrentDate].lastObject;
            }
            hsdpvc.maxDate = maxDate;
            
            hsdpvc.dateFormatter = [self dateFormatter];
            hsdpvc.monthAndYearLabelDateFormater = [self monthAndYearLabelDateFormater];
            
            hsdpvc.backButtonTitle = NSLocalizedString(@"Back", @"HSDatePickerViewController backButtonTitle");
            hsdpvc.confirmButtonTitle = NSLocalizedString(@"Set Date", @"HSDatePickerViewController confirmButtonTitle");
            
            [hsdpvc presentInParentViewController:self.tabBarController];
            
            return;
        }
        case ShowByMonth: {
            SelectTimePeriodViewController *selectTimePeriodViewController = [self getConfiguratedSelectTimePeriodViewController];
            selectTimePeriodViewController.isSelectMonthMode = YES;
            
            [selectTimePeriodViewController presentInParentViewController:self.tabBarController];
            
            return;
        }
        case ShowByYear: {
            SelectTimePeriodViewController *selectTimePeriodViewController = [self getConfiguratedSelectTimePeriodViewController];
            selectTimePeriodViewController.isSelectMonthMode = NO;
            
            [selectTimePeriodViewController presentInParentViewController:self.tabBarController];
            
            return;
        }
        default:
            break;
    }
}

#pragma mark - SelectTimePeriodViewControllerDelegate -

- (void)selectTimePeriodViewController:(SelectTimePeriodViewController *)selectMonthViewController didSelectValue:(NSDictionary *)info {
    NSDate *date = [self dateFromMonthInfo:info];
    
    switch (self.segmentedControl.selectedSegmentIndex) {
        case ShowByDay: {
            if ([date isDatesWithEqualDates:_dateToShow]) {
                _dateToShow = date;
                return;
            }
            break;
        }
        case ShowByMonth: {
            if ([date isDatesWithEqualMonth:_dateToShow]) {
                _dateToShow = date;
                return;
            }
            break;
        }
        case ShowByYear: {
            if ([date isDatesWithEqualYear:_dateToShow]) {
                _dateToShow = date;
                return;
            }
            break;
        }
        default:
            break;
    }
    _dateToShow = date;
    
    [self reloadData];
}

- (NSDate *)dateFromMonthInfo:(NSDictionary *)monthInfo {
    NSCalendar *calendar = [NSCalendar currentCalendar];
    
    NSDateComponents *dayComponents = [NSDateComponents new];
    dayComponents.year  = [monthInfo[@"year"]integerValue];
    dayComponents.month = [monthInfo[@"month"]integerValue];
    dayComponents.day   = 10;
    
    return [calendar dateFromComponents:dayComponents];
}

#pragma mark - HSDatePickerViewControllerDelegate -

- (void)hsDatePickerPickedDate:(NSDate *)date {
    _dateToShow = date;
    
    [self reloadData];
}

@end
