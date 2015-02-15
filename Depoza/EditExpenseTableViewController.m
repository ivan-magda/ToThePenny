//
//  EditExpenseTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "EditExpenseTableViewController.h"
#import "ExpenseData.h"
#import "CategoryData.h"

@interface EditExpenseTableViewController ()
@property (weak, nonatomic) IBOutlet UITextView *amountTextView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender;

@end

@implementation EditExpenseTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(self.managedObjectContext);
    NSParameterAssert(self.expenseToEdit);

    [self updateText];
}

- (void)updateText {
    self.amountTextView.text = [NSString stringWithFormat:@"%.2f", _expenseToEdit.amount.floatValue];
    self.dateLabel.text = [self formatDate:_expenseToEdit.dateOfExpense];
    self.categoryNameLabel.text = _expenseToEdit.category.title;
    self.descriptionLabel.text = _expenseToEdit.descriptionOfExpense;
}

- (NSString *)formatDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = [NSTimeZone localTimeZone];
        dateFormatter.dateFormat = @"dd MMMM yyyy";
    }
    return [dateFormatter stringFromDate:date];
}

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
@end
