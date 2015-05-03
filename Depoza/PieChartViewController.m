//
//  PieChartViewController.m
//  Depoza
//
//  Created by Ivan Magda on 03.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "PieChartViewController.h"
#import <CorePlot-CocoaTouch.h>
#import "CPDStockPriceStore.h"

#import "Fetch.h"

#import "NSDate+StartAndEndDatesOfYear.h"

@interface PieChartViewController () <CPTPlotDataSource>

@property (nonatomic, strong) CPTGraphHostingView *hostView;
@property (nonatomic, strong) CPTTheme *theme;

@end

@implementation PieChartViewController {
    NSArray *_categoriesInfo;
    NSNumber *_totalAmount;
}

#pragma mark - UIViewController lifecycle methods
- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray *dates = [_dateToShow startAndEndDatesOfYear];

    [Fetch loadCategoriesInfoInContext:_managedObjectContext betweenDates:dates withCompletionHandler:^(NSArray *fetchedCategories, NSNumber *totalAmount) {
        _categoriesInfo = fetchedCategories;
        _totalAmount = totalAmount;
    }];

    [self initPlot];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    for (NSUInteger i = 0; i < [[[CPDStockPriceStore sharedInstance]tickerSymbols]count]; ++i) {
        NSLog(@"%ld %@",i, [CPTPieChart defaultPieSliceColorForIndex:i].uiColor);
    }
}

#pragma mark - CPTPlotDataSource methods
    //return here number of categories
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return [[[CPDStockPriceStore sharedInstance] tickerSymbols] count];
}

    //return amount of expenses in special category
-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    if (CPTPieChartFieldSliceWidth == fieldEnum) {
        return [[[CPDStockPriceStore sharedInstance] dailyPortfolioPrices] objectAtIndex:index];
    }
    return [NSDecimalNumber zero];
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index {
        // 1 - Define label text style
    static CPTMutableTextStyle *labelText = nil;
    if (!labelText) {
        labelText= [[CPTMutableTextStyle alloc] init];
        labelText.color = [CPTColor grayColor];
    }
        // 2 - Calculate portfolio total value
    NSDecimalNumber *portfolioSum = [NSDecimalNumber zero];
        //Count amount of all expenses
    for (NSDecimalNumber *price in [[CPDStockPriceStore sharedInstance] dailyPortfolioPrices]) {
        portfolioSum = [portfolioSum decimalNumberByAdding:price];
    }
        // 3 - Calculate percentage value
        //here return amount of expenses in special category
    NSDecimalNumber *price = [[[CPDStockPriceStore sharedInstance] dailyPortfolioPrices] objectAtIndex:index];
    NSDecimalNumber *percent = [price decimalNumberByDividingBy:portfolioSum];
        // 4 - Set up display label
    NSString *labelValue = [NSString stringWithFormat:@"$%0.2f USD (%0.1f %%)", [price floatValue], ([percent floatValue] * 100.0f)];
        // 5 - Create and return layer with label text
    return [[CPTTextLayer alloc] initWithText:labelValue style:labelText];
}
    //here return title of category
-(NSString *)legendTitleForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index {
    if (index < [[[CPDStockPriceStore sharedInstance] tickerSymbols] count]) {
        return [[[CPDStockPriceStore sharedInstance] tickerSymbols] objectAtIndex:index];
    }
    return @"N/A";
}

#pragma mark - Chart behavior

-(void)initPlot {
    [self configureHost];
    [self configureGraph];
    [self configureChart];
    [self configureLegend];
}

-(void)configureHost {
    CGRect hostViewRect = self.view.bounds;
    hostViewRect.size.height /= 2.0f;
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:hostViewRect];
    self.hostView.allowPinchScaling = NO;
    [self.view addSubview:self.hostView];
}

-(void)configureGraph {
        // 1 - Create and initialize graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    self.hostView.hostedGraph = graph;
    graph.paddingLeft = 0.0f;
    graph.paddingTop = 0.0f;
    graph.paddingRight = 0.0f;
    graph.paddingBottom = 0.0f;
    graph.axisSet = nil;
        // 2 - Set up text style
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor grayColor];
    textStyle.fontName = @"Helvetica-Bold";
    textStyle.fontSize = 16.0f;
        // 3 - Configure title
    NSString *title = @"Portfolio Prices: May 1, 2012";
    graph.title = title;
    graph.titleTextStyle = textStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, -12.0f);
        // 4 - Set theme
    self.theme = [CPTTheme themeNamed:kCPTPlainWhiteTheme];
    [graph applyTheme:self.theme];
}

-(void)configureChart {
        // 1 - Get reference to graph
    CPTGraph *graph = self.hostView.hostedGraph;
        // 2 - Create chart
    CPTPieChart *pieChart = [[CPTPieChart alloc] init];
    pieChart.dataSource = self;
    pieChart.delegate = self;
    pieChart.pieRadius = (self.hostView.bounds.size.height * 0.7) / 2;
    pieChart.identifier = graph.title;
    pieChart.startAngle = M_PI_4;
    pieChart.sliceDirection = CPTPieDirectionClockwise;
        // 3 - Create gradient
    CPTGradient *overlayGradient = [[CPTGradient alloc] init];
    overlayGradient.gradientType = CPTGradientTypeRadial;
    overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.0] atPosition:0.9];
    overlayGradient = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.4] atPosition:1.0];
    pieChart.overlayFill = [CPTFill fillWithGradient:overlayGradient];
        // 4 - Add chart to graph    
    [graph addPlot:pieChart];
}

-(void)configureLegend {
        // 1 - Get graph instance
    CPTGraph *graph = self.hostView.hostedGraph;
        // 2 - Create legend
    CPTLegend *theLegend = [CPTLegend legendWithGraph:graph];
        // 3 - Configure legend
    theLegend.numberOfColumns = 1;
    theLegend.fill = [CPTFill fillWithColor:[CPTColor whiteColor]];
    theLegend.borderLineStyle = [CPTLineStyle lineStyle];
    theLegend.cornerRadius = 5.0;
        // 4 - Add legend to graph
    graph.legend = theLegend;
    graph.legendAnchor = CPTRectAnchorRight;
    CGFloat legendPadding = -(self.view.bounds.size.width / 8);
    graph.legendDisplacement = CGPointMake(legendPadding, 0.0);
}

@end
