//
//  SelectMonthViewController.m
//  Depoza
//
//  Created by Ivan Magda on 11.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewControllers
#import "SelectTimePeriodViewController.h"
#import "GradientView.h"
    //CoreData
#import "ExpenseData+Fetch.h"
    //Categories
#import "NSDate+FirstAndLastDaysOfMonth.h"
#import "NSString+FormatAmount.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface SelectTimePeriodViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SelectTimePeriodViewController {
    GradientView *_gradientView;
    NSArray *_dataSourceInformation;
    NSDateFormatter *_dateFormatter;
    NSInteger _currentYear;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    if (_isSelectMonthMode) {
        _dataSourceInformation = [ExpenseData getEachMonthWithSumExpensesInManagedObjectContext:_managedObjectContext];
        
        NSDictionary *dictionary = [[NSDate date]getComponents];
        _currentYear = [dictionary[@"year"]integerValue];
        
        _dateFormatter = [NSDateFormatter new];
        
        [_dateFormatter setDateFormat:@"MMMM"];
        if ([[[NSLocale currentLocale]objectForKey:NSLocaleCountryCode]isEqualToString:@"RU"]) {
            [_dateFormatter setMonthSymbols:@[@"Январь", @"Февраль", @"Март", @"Апрель", @"Май", @"Июнь", @"Июль", @"Август", @"Сентябрь", @"Октябрь", @"Ноябрь", @"Декабрь"]];
        }
    } else {
        _dataSourceInformation = [ExpenseData getEachYearWithSumExpensesInManagedObjectContext:_managedObjectContext];
    }
}

#pragma mark - Embed -

- (void)dismissFromParentViewController {
    [self willMoveToParentViewController:nil];

    [UIView animateWithDuration:0.3 animations:^ {
        CGRect rect = self.view.bounds;
        rect.origin.y += rect.size.height;
        self.view.frame = rect;
        _gradientView.alpha = 0.0f;
    }completion:^(BOOL finished) {
        [self.view removeFromSuperview];
        [self removeFromParentViewController];

        [_gradientView removeFromSuperview];
    }];
}

- (void)presentInParentViewController:(UIViewController *)parentViewController {
    _gradientView = [[GradientView alloc] initWithFrame:parentViewController.view.bounds];
    [parentViewController.view addSubview:_gradientView];

    self.view.frame = parentViewController.view.bounds;
    [parentViewController.view addSubview:self.view];
    [parentViewController addChildViewController:self];

    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];

    bounceAnimation.duration = 0.4;
    bounceAnimation.delegate = self;

    bounceAnimation.values = @[ @0.7, @1.2, @0.9, @1.0 ];
    bounceAnimation.keyTimes = @[ @0.0, @0.334, @0.666, @1.0 ];

    bounceAnimation.timingFunctions = @[
                                        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];

    [self.view.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];

    CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.fromValue = @0.0f;
    fadeAnimation.toValue = @1.0f;
    fadeAnimation.duration = 0.2;
    [_gradientView.layer addAnimation:fadeAnimation forKey:@"fadeAnimation"];
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    [self didMoveToParentViewController:self.parentViewController];
}

#pragma mark - UITableView -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _dataSourceInformation.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"SelectMonthCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:identifier];

        cell.layer.cornerRadius = 1.0f;
    }
    NSDictionary *dictionary = _dataSourceInformation[indexPath.section];
    NSInteger year = [dictionary[@"year"]integerValue];

    if (_isSelectMonthMode) {
        NSInteger month = [dictionary[@"month"]integerValue];
        
        NSString *monthString = [[_dateFormatter monthSymbols]objectAtIndex:month - 1];
        NSMutableString *text = [NSMutableString stringWithString:monthString];
        
        if (year != _currentYear) {
            [text appendString:[NSString stringWithFormat:@" %d", (int)year]];
        }
        
        cell.textLabel.text = [text uppercaseString];
    } else {
        cell.textLabel.text = [[NSString stringWithFormat:@"%ld", (long)year]uppercaseString];
    }

    cell.textLabel.font = [UIFont fontWithName:@".SFUIText-Light" size:17.0f];
    cell.textLabel.textColor = [UIColor blackColor];

    cell.detailTextLabel.text = [NSString formatAmount:dictionary[@"amount"]];
    cell.detailTextLabel.font = [UIFont fontWithName:@".SFUIText-Light" size:17.0f];
    cell.detailTextLabel.textColor = UIColorFromRGB(0xFF3333);

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if ([self.delegate respondsToSelector:@selector(selectTimePeriodViewController:didSelectValue:)]) {
        [_delegate selectTimePeriodViewController:self didSelectValue:_dataSourceInformation[indexPath.section]];
    }
    
    [self dismissFromParentViewController];
}

@end
