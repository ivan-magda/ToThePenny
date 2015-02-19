//
//  EditExpenseTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //View
#import "EditExpenseTableViewController.h"
#import "ChooseCategoryTableViewController.h"

    //CoreData
#import "ExpenseData.h"
#import "CategoryData.h"
#import "CategoryData+Fetch.h"

    //KVNProgress
#import <KVNProgress/KVNProgress.h>

@interface EditExpenseTableViewController () <UITextViewDelegate>
@property (weak, nonatomic) IBOutlet UITextView *amountTextView;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneBarButton;

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender;

@end

@implementation EditExpenseTableViewController {
    BOOL _datePickerVisible;
    NSDate *_dateOfExpense;
}

#pragma mark - UIViewController Life Cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(self.managedObjectContext);
    NSParameterAssert(self.expenseToEdit);

    _amountTextView.delegate = self;
    _dateOfExpense = _expenseToEdit.dateOfExpense;

    [self updateText];

    [self.amountTextView becomeFirstResponder];
}

#pragma mark - Helper Methods -

- (void)updateText {
    self.amountTextView.text = [NSString stringWithFormat:@"%.2f", _expenseToEdit.amount.floatValue];
    self.categoryNameLabel.text = _expenseToEdit.category.title;
    self.descriptionLabel.text = _expenseToEdit.descriptionOfExpense;
    [self updateDateLabel];
}

- (void)updateDateLabel {
    self.dateLabel.text = [self formatDate:_dateOfExpense];
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

#pragma mark - Segues -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ChooseCategory"]) {
        ChooseCategoryTableViewController *controller = (ChooseCategoryTableViewController *)segue.destinationViewController;

        NSArray *allCategoriesTitles = [CategoryData getAllTitlesInContext:_managedObjectContext];

        controller.delegate = self;
        controller.titles = allCategoriesTitles;
        controller.managedObjectContext = _managedObjectContext;
        controller.originalCategoryName = self.categoryNameLabel.text;
    }
}

#pragma mark - ChooseCategoryTableViewControllerDelegate -

- (void)chooseCategoryTableViewController:(ChooseCategoryTableViewController *)controller didFinishChooseCategory:(NSString *)category {
    self.categoryNameLabel.text = category;

    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UITableView
#pragma mark DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_datePickerVisible) {
        return 5;
    } else {
        return [super tableView:tableView numberOfRowsInSection:section];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2 && _datePickerVisible) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DatePickerCell"];

        if (cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DatePickerCell"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;

            UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 216.0f)];
            datePicker.tag = 100;
            [cell.contentView addSubview:datePicker];

            [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
        }
        return cell;
    } else {
        return [super tableView:tableView cellForRowAtIndexPath:indexPath];
    }
}

#pragma mark Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2 && _datePickerVisible) {
        return 217.0f;
    } else if (indexPath.row == 4) {
        NSIndexPath *correctIndex = [NSIndexPath indexPathForRow:3 inSection:0];
        return [super tableView:tableView heightForRowAtIndexPath:correctIndex];
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

    // Need to override this or the app crashes
- (NSInteger)tableView:(UITableView *)tableView indentationLevelForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2 && _datePickerVisible) {
        NSIndexPath *newIndexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section];
        return [super tableView:tableView indentationLevelForRowAtIndexPath:newIndexPath];
    } else {
        return [super tableView:tableView indentationLevelForRowAtIndexPath:indexPath];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self.amountTextView resignFirstResponder];

    if (indexPath.row == 1) {
        if (!_datePickerVisible) {
            [self showDatePicker];
        } else {
            [self hideDatePicker];
        }
    }
}

#pragma mark - UIDatePicker -

- (void)showDatePicker {
    _datePickerVisible = YES;

    NSIndexPath *indexPathDateRow = [NSIndexPath indexPathForRow:1 inSection:0];
    NSIndexPath *indexPathDatePicker = [NSIndexPath indexPathForRow:2 inSection:0];

    _dateLabel.textColor = _dateLabel.tintColor;

    [self.tableView beginUpdates];
    [self.tableView insertRowsAtIndexPaths:@[indexPathDatePicker] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView reloadRowsAtIndexPaths:@[indexPathDateRow] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];

    UITableViewCell *datePickerCell = [self.tableView cellForRowAtIndexPath:indexPathDatePicker];
    UIDatePicker *datePicker = (UIDatePicker *)[datePickerCell viewWithTag:100];
    [datePicker setDate:_dateOfExpense animated:NO];
}

- (void)hideDatePicker {
    if (_datePickerVisible) {
        _datePickerVisible = NO;

        NSIndexPath *indexPathDateRow = [NSIndexPath indexPathForRow:1 inSection:0];
        NSIndexPath *indexPathDatePicker = [NSIndexPath indexPathForRow:2 inSection:0];

        _dateLabel.textColor = [UIColor blackColor];

        [self.tableView beginUpdates];
        [self.tableView reloadRowsAtIndexPaths:@[indexPathDateRow] withRowAnimation:UITableViewRowAnimationNone];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathDatePicker] withRowAnimation:UITableViewRowAnimationFade];
        [self.tableView endUpdates];
    }
}

- (void)dateChanged:(UIDatePicker *)datePicker {
    _dateOfExpense = datePicker.date;
    [self updateDateLabel];
}

#pragma mark - UITextViewDelegate -

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *newText = [textView.text stringByReplacingCharactersInRange:range withString:text];

    self.doneBarButton.enabled = ([newText length] > 0);

    return YES;
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
    [self hideDatePicker];
}

#pragma mark - IBActions -

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)doneButtonPressed:(UIBarButtonItem *)sender {
    [self.amountTextView resignFirstResponder];
    [self hideDatePicker];

    BOOL isChanged = NO;

    if (_expenseToEdit.amount.floatValue != [_amountTextView.text floatValue]) {
        _expenseToEdit.amount = @([_amountTextView.text floatValue]);
        isChanged = YES;
    }

    if ([_expenseToEdit.dateOfExpense compare:_dateOfExpense] != NSOrderedSame) {
        _expenseToEdit.dateOfExpense = _dateOfExpense;
        isChanged = YES;
    }

    if (![_expenseToEdit.descriptionOfExpense isEqualToString:_descriptionLabel.text]) {
        _expenseToEdit.descriptionOfExpense = _descriptionLabel.text;
        isChanged = YES;
    }

    if (![_expenseToEdit.category.title isEqualToString:_categoryNameLabel.text]) {
        CategoryData *newSelectedCategory = [CategoryData categoryFromTitle:_categoryNameLabel.text context:_managedObjectContext];

        [_expenseToEdit.category removeExpenseObject:_expenseToEdit];

        _expenseToEdit.category = newSelectedCategory;
        _expenseToEdit.categoryId = newSelectedCategory.idValue;
        [newSelectedCategory addExpenseObject:_expenseToEdit];

        isChanged = YES;
    }
    NSError *error;
    if (![_managedObjectContext save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }

    if (isChanged) {
        [KVNProgress showSuccessWithStatus:@"Updated" completion:^{                [self dismissViewControllerAnimated:YES completion:nil];
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
