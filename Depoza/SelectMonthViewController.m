//
//  SelectMonthViewController.m
//  Depoza
//
//  Created by Ivan Magda on 11.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewControllers
#import "SelectMonthViewController.h"
#import "GradientView.h"
    //CoreData
#import "ExpenseData+Fetch.h"
    //Categories
#import "NSDate+FirstAndLastDaysOfMonth.h"
#import "NSString+FormatAmount.h"

@interface SelectMonthViewController () <UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end

@implementation SelectMonthViewController {
    GradientView *_gradientView;
    NSArray *_monthInfo;
    NSDateFormatter *_dateFormatter;
    NSInteger _currentYear;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.backgroundColor = [UIColor clearColor];

    _monthInfo = [ExpenseData getEachMonthWithSumExpensesInManagedObjectContext:_managedObjectContext];

    NSDictionary *dictionary = [[NSDate date]getComponents];
    _currentYear = [dictionary[@"year"]integerValue];

    _dateFormatter = [[NSDateFormatter alloc] init];
    [_dateFormatter setDateFormat:@"MMMM"];
    if ([[[NSLocale currentLocale]objectForKey:NSLocaleCountryCode]isEqualToString:@"RU"]) {
        [_dateFormatter setMonthSymbols:@[@"Январь", @"Февраль", @"Март", @"Апрель", @"Май", @"Июнь", @"Июль", @"Август", @"Сентябрь", @"Октябрь", @"Ноябрь", @"Декабрь"]];
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
    return _monthInfo.count;
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
    NSDictionary *dictionary = _monthInfo[indexPath.section];
    NSInteger month = [dictionary[@"month"]integerValue];
    NSInteger year = [dictionary[@"year"]integerValue];

    NSString *monthString = [[_dateFormatter monthSymbols]objectAtIndex:month - 1];
    NSMutableString *text = [NSMutableString stringWithString:monthString];
    if (year != _currentYear) {
        [text appendString:[NSString stringWithFormat:@" %d", (int)year]];
    }

    cell.textLabel.text = [text uppercaseString];
    cell.textLabel.textColor = [UIColor blackColor];

    cell.detailTextLabel.text = [NSString formatAmount:dictionary[@"amount"]];
    cell.detailTextLabel.textColor = [UIColor grayColor];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self dismissFromParentViewController];
}

@end
