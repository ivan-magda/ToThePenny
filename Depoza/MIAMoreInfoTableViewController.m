//
//  DetailsViewController.m
//  Depoza
//
//  Created by Ivan Magda on 24/12/14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

    //View
#import "MIAMoreInfoTableViewController.h"
#import "MIAEditExpenseTableViewController.h"
    //CoreData
#import "ExpenseData.h"
#import "CategoryData.h"
    //Categories
#import "NSString+FormatAmount.h"

@interface MIAMoreInfoTableViewController ()

@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryName;
@property (weak, nonatomic) IBOutlet UILabel *textOfDescription;

@end

@implementation MIAMoreInfoTableViewController {
    BOOL _isEdited;
}

#pragma mark - ViewControllerLifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    [self updateLabels];
    
    NSParameterAssert(_managedObjectContext);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (_isEdited) {
        [self.navigationController popViewControllerAnimated:animated];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    _isEdited = YES;
}

- (void)dealloc {
    NSLog(@"Dealloc %@", self);
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EditExpense"]) {
        UINavigationController *navigationController = segue.destinationViewController;

        MIAEditExpenseTableViewController *controller = (MIAEditExpenseTableViewController *)navigationController.topViewController;
        controller.managedObjectContext = _managedObjectContext;
        controller.expenseToEdit = self.expenseToShow;
    }
}

#pragma mark - SetUp -

- (void)updateLabels {
    self.amountLabel.text = [NSString formatAmount:_expenseToShow.amount];
    self.dateLabel.text = [self formatDate:_expenseToShow.dateOfExpense];
    self.categoryName.text = _expenseToShow.category.title;
    self.textOfDescription.text = (_expenseToShow.descriptionOfExpense.length > 0) ? _expenseToShow.descriptionOfExpense : NSLocalizedString(@"(No Description)", @"MoreInfoVC text for description label");
}

- (NSString *)formatDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter = nil;
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = [NSTimeZone localTimeZone];
        dateFormatter.dateFormat = @"dd MMMM yyyy, HH:mm";
    }
    return [dateFormatter stringFromDate:date];
}

@end
