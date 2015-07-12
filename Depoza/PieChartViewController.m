//
//  PieChartViewController.m
//  Depoza
//
//  Created by Ivan Magda on 03.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "PieChartViewController.h"
#import <CorePlot-CocoaTouch.h>
    //CoreData
#import "CategoriesInfo.h"
#import "Fetch.h"
    //Categories
#import "NSDate+StartAndEndDatesOfYear.h"
#import "NSString+FormatAmount.h"
    //View
#import "PieChartTableViewCell.h"

static NSString * const kPieChartTableViewCellIdentifier = @"PieChartTableViewCell";

@interface PieChartViewController () <CPTPlotDataSource>

@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTTheme *theme;

@property (weak, nonatomic) IBOutlet UIButton *selectDateButton;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UIView *pieChartView;
@property (strong, nonatomic) UISegmentedControl *segmentedControl;

@end

@implementation PieChartViewController {
    NSMutableArray *_categoriesInfo;
    NSNumber *_totalAmount;
}

#pragma mark - UIViewController lifecycle methods -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self configurateNavigationBar];

    NSArray *dates = [_dateToShow startAndEndDatesOfYear];

    __weak PieChartViewController *weakSelf = self;
    
    [Fetch loadCategoriesInfoInContext:_managedObjectContext betweenDates:dates withCompletionHandler:^(NSArray *fetchedCategories, NSNumber *totalAmount) {
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(amount)) ascending:NO];
        NSMutableArray *sortedCategories = [[fetchedCategories sortedArrayUsingDescriptors:@[sortDescriptor]]mutableCopy];
        
        [weakSelf removeCategoriesWithoutTransactionsFrom:sortedCategories];
        
        _categoriesInfo = sortedCategories;
        _totalAmount = totalAmount;
    }];
    
    self.segmentedControl.selectedSegmentIndex = 2;
    self.amountLabel.text = [NSString formatAmount:_totalAmount];

    [self initPlot];
}

#pragma mark - Helper methods -

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
    UIBarButtonItem *barBtnItem = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"Back"] style:UIBarButtonItemStylePlain target:self action:@selector(goBack:)];
    self.navigationItem.leftBarButtonItem = barBtnItem;
    
    self.segmentedControl = [[UISegmentedControl alloc]initWithItems:@[NSLocalizedString(@"Day", @"Day"), NSLocalizedString(@"Month", @"Month"), NSLocalizedString(@"Year", @"Year")]];
    [_segmentedControl addTarget:self action:@selector(segmentedControlDidChangeValue:) forControlEvents:UIControlEventValueChanged];
    
    for (int i = 0; i < self.segmentedControl.numberOfSegments; ++i) {
        [self.segmentedControl setWidth:66.0f forSegmentAtIndex:i];
    }
    
    self.navigationItem.titleView = self.segmentedControl;
}

- (NSNumber *)calculatePercentageValueForAmount:(NSNumber *)amount andTotalAmount:(NSNumber *)totalAmount {
    return @(amount.floatValue / totalAmount.floatValue * 100.0f);
}

#pragma mark - CPTPlotDataSource methods -

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
        labelText.fontName = @"HelveticaNeue-Light";
        labelText.fontSize = 15.0f;
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
        //Create line style
    CPTMutableLineStyle *lineStyle = [CPTMutableLineStyle new];
    lineStyle.lineColor = [CPTColor whiteColor];
    lineStyle.lineWidth = 3.5f;
    pieChart.borderLineStyle = lineStyle;
        //Add chart to graph
    [graph addPlot:pieChart];
}

#pragma mark - UITableViewDataSource -

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _categoriesInfo.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoriesInfo *category = _categoriesInfo[indexPath.row];
    
    PieChartTableViewCell *cell = (PieChartTableViewCell *)[tableView dequeueReusableCellWithIdentifier:kPieChartTableViewCellIdentifier];
    
    cell.coloredCategoryView.backgroundColor = ([CPTPieChart defaultPieSliceColorForIndex:indexPath.row].uiColor);
    cell.coloredCategoryView.layer.cornerRadius = (CGRectGetHeight(cell.coloredCategoryView.bounds) / 2.0f);
    cell.categoryTitleLabel.text = category.title;
    cell.amountLabel.text  = [NSString formatAmount:category.amount];

    NSNumber *percent = [self calculatePercentageValueForAmount:category.amount andTotalAmount:_totalAmount];
    cell.percentLabel.text = [NSString stringWithFormat:@"%0.1f %%", percent.floatValue];
    
    
    UIView *separator = [[UIView alloc]initWithFrame: CGRectMake(15.0f, 64.0f - 0.5f,tableView.bounds.size.width - 15.0f, 0.5f)];
    separator.backgroundColor = tableView.separatorColor;
    
    [cell addSubview:separator];
    
    return cell;
}

#pragma mark - HandleActions -

- (void)goBack:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)segmentedControlDidChangeValue:(UISegmentedControl *)segmentedControl {
    NSLog(@"SelectedSegmentIndex %ld", (long)segmentedControl.selectedSegmentIndex);
}

@end
