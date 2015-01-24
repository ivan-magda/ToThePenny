//
//  DetailsViewController.m
//  Depoza
//
//  Created by Ivan Magda on 24/12/14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import "DetailsViewController.h"
#import "ExpenseData.h"

@interface DetailsViewController ()

@property (weak, nonatomic) IBOutlet UILabel *label;

@end

@implementation DetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"Details";

        //self.label.text = [NSString stringWithFormat:@"%@\n %@\n %@\n %@", self.expenseToShow.amount, self.expenseToShow.category, self.expenseToShow.descriptionOfExpense, self.expenseToShow.dateOfExpense];
}

@end
