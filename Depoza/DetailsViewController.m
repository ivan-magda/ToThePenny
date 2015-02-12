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

@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryName;
@property (weak, nonatomic) IBOutlet UILabel *textOfDescription;

@end

@implementation DetailsViewController

#pragma mark - ViewControllerLifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);

    [self updateLabels];

    UIBarButtonItem *deleteButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(deleteButtonPressed)];
    self.navigationItem.rightBarButtonItem = deleteButton;
}

- (void)dealloc {
    NSLog(@"Dealloc %@", self);
}

#pragma mark - SetUp -

- (void)updateLabels {
    self.amountLabel.text = [NSString stringWithFormat:@"%.2f", _expenseToShow.amount.floatValue];
    self.dateLabel.text = [self formatDate:_expenseToShow.dateOfExpense];
    self.categoryName.text = _expenseToShow.category.title;
    self.textOfDescription.text = _expenseToShow.descriptionOfExpense;
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

#pragma mark - Selector -

- (void)deleteButtonPressed {
    NSManagedObjectContext *context = _managedObjectContext;
    [context deleteObject:_expenseToShow];

    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [self.navigationController popViewControllerAnimated:YES];
}

@end
