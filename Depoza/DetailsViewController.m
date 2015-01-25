//
//  DetailsViewController.m
//  Depoza
//
//  Created by Ivan Magda on 24/12/14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import "DetailsViewController.h"
#import "ExpenseData.h"
#import "CategoryData.h"

@interface DetailsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Details";

    self.label.text = [NSString stringWithFormat:@"Amount:%@\n Category:%@\n Description:%@\n Date:%@\n idValue:%@", self.expenseToShow.amount, self.expenseToShow.category.title, self.expenseToShow.descriptionOfExpense, self.expenseToShow.dateOfExpense, self.expenseToShow.idValue];
}

@end
