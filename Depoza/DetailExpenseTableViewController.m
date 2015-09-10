//
//  EditExpenseTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewControllers
#import "DetailExpenseTableViewController.h"
#import "ChooseCategoryTableViewController.h"
#import "EditDescriptionViewController.h"
    //CoreData
#import "ExpenseData.h"
#import "CategoryData+Fetch.h"
#import "Expense.h"
    //Categories
#import "NSString+FormatAmount.h"
    //KVNProgress
#import <KVNProgress/KVNProgress.h>

NSString * const DetailExpenseTableViewControllerDidUpdateNotification = @"DetailExpenseTableViewControllerDidUpdateNotification";

static const CGFloat kExtendedTrailingSpaceConstantValue = 33.0f;

typedef NS_ENUM(NSInteger, ScrollDirection) {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
};

@interface DetailExpenseTableViewController () <UITextFieldDelegate, UIScrollViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *amountTextField;
@property (weak, nonatomic) IBOutlet UILabel *dateLabel;
@property (weak, nonatomic) IBOutlet UILabel *categoryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *amountTextFieldTrailingSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dateLabelTrailingSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoryLabelTrailingSpace;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *descriptionLabelTrailingSpace;

@property (nonatomic, assign) CGFloat lastContentOffset;

@end

@implementation DetailExpenseTableViewController {
    BOOL _datePickerVisible;
    NSDate *_dateOfExpense;
    NSString *_iconName;

    UIBarButtonItem *_editBarButton;
    UIBarButtonItem *_doneBarButton;
    UIBarButtonItem *_cancelBatButton;
    UIBarButtonItem *_deleteBarButton;

    BOOL _isEditMode;

    CGFloat _originalTrailingSpace;
}

#pragma mark - UIViewController Life Cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(self.managedObjectContext);
    NSParameterAssert(self.expenseToShow);
    
    _amountTextField.delegate = self;
    _dateOfExpense = _expenseToShow.dateOfExpense;
    _iconName = _expenseToShow.category.iconName;

    _editBarButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"Edit"] style:UIBarButtonItemStylePlain target:self action:@selector(editButtonPressed:)];
    _doneBarButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneButtonPressed:)];
    _cancelBatButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    _deleteBarButton = [[UIBarButtonItem alloc]initWithImage:[UIImage imageNamed:@"Trash"] style:UIBarButtonItemStylePlain target:self action:@selector(deleteButtonPressed:)];

    self.navigationItem.rightBarButtonItems = @[_deleteBarButton, _editBarButton];

    _isEditMode = NO;

    _originalTrailingSpace = self.descriptionLabelTrailingSpace.constant;

    [self updateText];
}

#pragma mark - Helper Methods -

- (void)updateText {
    self.amountTextField.text = [NSString formatAmount:_expenseToShow.amount];
    self.categoryNameLabel.text = _expenseToShow.category.title;
    self.descriptionLabel.text = (_expenseToShow.descriptionOfExpense.length > 0) ? _expenseToShow.descriptionOfExpense : NSLocalizedString(@"(No Description)", @"EditExpenseVC text for description label");
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
        dateFormatter.dateFormat = @"d MMMM yyyy, HH:mm";
    }
    return [dateFormatter stringFromDate:date];
}

- (void)animation {
    CATransition *animation = [CATransition animation];
    [animation setType:kCATransitionPush];
    [animation setSubtype:kCATransitionFromBottom];
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    [animation setFillMode:kCAFillModeBoth];
    [animation setDuration:.3];

    for (UIView *view in self.tableView.subviews) {
        if ([view isKindOfClass:[UITableViewCell class]]) {
            [view.layer addAnimation:animation forKey:@"UITableViewCellReloadDataAnimationKey"];
        }
    }
}

- (void)setDetailMode {
    _isEditMode = NO;

    self.amountTextField.text = [NSString formatAmount:_expenseToShow.amount];

    [self.navigationItem setLeftBarButtonItem:nil animated:YES];
    [self.navigationItem setHidesBackButton:NO animated:YES];
    [self.navigationItem setRightBarButtonItems:@[_deleteBarButton, _editBarButton] animated:YES];

    [self hideDatePicker];

    [self setAlpha:0];
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setAlpha:1];

        self.amountTextFieldTrailingSpace.constant = _originalTrailingSpace;
        self.dateLabelTrailingSpace.constant = _originalTrailingSpace;
        self.categoryLabelTrailingSpace.constant = _originalTrailingSpace;
        self.descriptionLabelTrailingSpace.constant = _originalTrailingSpace;
    } completion:nil];

    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)setEditMode {
    _isEditMode = YES;

    NSMutableCharacterSet *charactersToKeep = [NSMutableCharacterSet decimalDigitCharacterSet];
    [charactersToKeep addCharactersInString:@","];
    [charactersToKeep addCharactersInString:@"."];

    NSCharacterSet *charactersToRemove = [charactersToKeep invertedSet];

    NSString *newString = [[_amountTextField.text componentsSeparatedByCharactersInSet:charactersToRemove]
                           componentsJoinedByString:@""];
    self.amountTextField.text = newString;

    [self.navigationItem setHidesBackButton:YES animated:YES];
    [self.navigationItem setRightBarButtonItems:@[_doneBarButton] animated:YES];
    [self.navigationItem setLeftBarButtonItem:_cancelBatButton animated:YES];

    [self setAlpha:0.0f];
    [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self setAlpha:1.0f];

        self.amountTextFieldTrailingSpace.constant = kExtendedTrailingSpaceConstantValue;
        self.dateLabelTrailingSpace.constant = kExtendedTrailingSpaceConstantValue;
        self.categoryLabelTrailingSpace.constant = 0.0f;
        self.descriptionLabelTrailingSpace.constant = 0.0f;
    } completion:nil];

    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    [self.tableView endUpdates];
}

- (void)setAlpha:(CGFloat)alpha {
    self.amountTextField.alpha = alpha;
    self.dateLabel.alpha = alpha;
    self.categoryNameLabel.alpha = alpha;
    self.descriptionLabel.alpha = alpha;
}

#pragma mark - Segues -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ChooseCategory"]) {
        ChooseCategoryTableViewController *controller = (ChooseCategoryTableViewController *)segue.destinationViewController;

        NSArray *allCategoriesTitles = [CategoryData getAllTitlesInContext:_managedObjectContext];

        controller.delegate = self;
        controller.context = _managedObjectContext;
        controller.titles = allCategoriesTitles;
        controller.iconName = _iconName;
        controller.originalCategoryName = self.categoryNameLabel.text;
    } else if ([segue.identifier isEqualToString:@"EditDescription"]) {
        EditDescriptionViewController *controller = segue.destinationViewController;

        NSString *text = ([_descriptionLabel.text isEqualToString:NSLocalizedString(@"(No Description)", @"EditExpenseVC check for no description text in prepare for segue")] ? @"" : _descriptionLabel.text);

        [controller setExpenseDescription:text withDidSaveCompletionHandler:^(NSString *text) {
            self.descriptionLabel.text = text;
            [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
        }];
    }
}

#pragma mark - ChooseCategoryTableViewControllerDelegate -

- (void)chooseCategoryTableViewController:(ChooseCategoryTableViewController *)controller didFinishChooseCategoryName:(NSString *)category andIconName:(NSString *)iconName {
    self.categoryNameLabel.text = category;
    _iconName = iconName;
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
    } else if (_isEditMode && ((!_datePickerVisible && indexPath.row == 2) || (!_datePickerVisible && indexPath.row == 3))){
        UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        return cell;
    }
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = (_isEditMode ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone);

    return cell;
}

#pragma mark Delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_isEditMode) {
        return indexPath;
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 2 && _datePickerVisible) {
        return 217.0f;
    } else if (( _datePickerVisible && indexPath.row == 4) ||
               (!_datePickerVisible && indexPath.row == 3)) {
        // UILabels can display their content in multiple rows but this takes
        // some trickery. We first say to the label: this is your width, now
        // try to fit all the text in there (sizeToFit). This resizes both the
        // label's width and height.
        
        CGRect rect = CGRectMake(_descriptionLabel.frame.origin.x, _descriptionLabel.frame.origin.y, CGRectGetWidth(_descriptionLabel.frame), CGFLOAT_MAX);
        self.descriptionLabel.frame = rect;
        [self.descriptionLabel sizeToFit];
        
        rect.size.height = CGRectGetHeight(self.descriptionLabel.frame);
        self.descriptionLabel.frame = rect;
        
        return self.descriptionLabel.frame.size.height + 21.0f;
    } else {
        return [super tableView:tableView heightForRowAtIndexPath:indexPath];
    }
}

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

    switch (indexPath.row) {
        case 0: {
            if (_datePickerVisible) {
                [self hideDatePicker];
                [self.amountTextField becomeFirstResponder];
            }
            break;
        }
        case 1: {
            [self.amountTextField resignFirstResponder];

            if (!_datePickerVisible) {
                [self showDatePicker];
            } else {
                [self hideDatePicker];
            }
            break;
        }
        default: {
            [self.amountTextField resignFirstResponder];
            if (_datePickerVisible) {
                [self hideDatePicker];
            }
            break;
        }
    }
}

#pragma mark - UIDatePicker -

- (void)showDatePicker {
    _datePickerVisible = YES;

    NSIndexPath *indexPathDateRow    = [NSIndexPath indexPathForRow:1 inSection:0];
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

        NSIndexPath *indexPathDateRow    = [NSIndexPath indexPathForRow:1 inSection:0];
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

#pragma mark - UITextFieldDelegate -

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField {
    return _isEditMode;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *newText = [textField.text stringByReplacingCharactersInRange:range withString:string];

    _doneBarButton.enabled = (([newText length] > 0) && (newText.floatValue > 0.0f));

    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self hideDatePicker];
}

#pragma mark - UIBarButtons -

- (void)editButtonPressed:(UIBarButtonItem *)sender {
    [self setEditMode];

    [self.amountTextField becomeFirstResponder];
}

- (void)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.amountTextField resignFirstResponder];
    [self hideDatePicker];

    _dateOfExpense = _expenseToShow.dateOfExpense;
    _iconName = _expenseToShow.category.iconName;

    [self updateText];
    [self setDetailMode];
}

- (void)deleteButtonPressed:(UIBarButtonItem *)sender {
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"Delete transaction?", @"Delete transaction alert view title in DetailExpenseVC") message:nil delegate:self cancelButtonTitle:NSLocalizedString(@"No", @"Cancel button title in DetailExpenseVC") otherButtonTitles:NSLocalizedString(@"Delete", @"Delete transaction alert view other button title in DetailExpenseVC"), nil];
    [alertView show];
}

- (void)deleteTransaction {
    [self.managedObjectContext deleteObject:_expenseToShow];
    
    NSError *error = nil;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    [KVNProgress showSuccessWithStatus:NSLocalizedString(@"Deleted", @"Successful deleted message in DetailVC") completion:^{
        [self.navigationController popViewControllerAnimated:YES];
    }];
}

- (void)doneButtonPressed:(UIBarButtonItem *)sender {
    [self.amountTextField resignFirstResponder];
    [self hideDatePicker];

    BOOL isChanged = NO;

    NSString *amountString = [_amountTextField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    if (_expenseToShow.amount.floatValue != [amountString floatValue]) {
        self.expenseToShow.amount = @([amountString floatValue]);
        isChanged = YES;
    }

    if ([_expenseToShow.dateOfExpense compare:_dateOfExpense] != NSOrderedSame) {
        self.expenseToShow.dateOfExpense = _dateOfExpense;
        isChanged = YES;
    }

    if (![_expenseToShow.descriptionOfExpense isEqualToString:_descriptionLabel.text] && ![_descriptionLabel.text isEqualToString:NSLocalizedString(@"(No Description)", @"EditExpenseVC check for no description text when done button pressed")]) {
        self.expenseToShow.descriptionOfExpense = _descriptionLabel.text;
        isChanged = YES;
    }
    NSParameterAssert(![_expenseToShow.descriptionOfExpense isEqualToString:NSLocalizedString(@"(No Description)", @"EditExpenseVC assertion check")]);

    if (![_expenseToShow.category.title isEqualToString:_categoryNameLabel.text]) {
        CategoryData *newSelectedCategory = [CategoryData categoryFromTitle:_categoryNameLabel.text context:_managedObjectContext];

        [_expenseToShow.category removeExpenseObject:_expenseToShow];

        self.expenseToShow.category   = newSelectedCategory;
        self.expenseToShow.categoryId = newSelectedCategory.idValue;
        [newSelectedCategory addExpenseObject:_expenseToShow];

        isChanged = YES;
    }

    if (![_expenseToShow.category.iconName isEqualToString:_iconName]) {
        CategoryData *category = [CategoryData categoryFromTitle:_categoryNameLabel.text context:_managedObjectContext];
        category.iconName = _iconName;
        
        isChanged = YES;
    }

    NSError *error;
    if ([_managedObjectContext hasChanges] && ![_managedObjectContext save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }

    if (isChanged) {
        [[NSNotificationCenter defaultCenter]postNotificationName:DetailExpenseTableViewControllerDidUpdateNotification object:nil];

        [KVNProgress showSuccessWithStatus:NSLocalizedString(@"Updated", @"Successful update message in DetailVC") completion:^{
            [self.navigationController popViewControllerAnimated:YES];
        }];
    }

    [self updateText];
    [self setDetailMode];
}

#pragma mark - UIScrollViewDelegate -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    ScrollDirection scrollDirection = ScrollDirectionNone;

    if (_lastContentOffset > scrollView.contentOffset.y) {
        scrollDirection = ScrollDirectionDown;
    } else if (self.lastContentOffset < scrollView.contentOffset.y) {
        scrollDirection = ScrollDirectionUp;
    }

    self.lastContentOffset = scrollView.contentOffset.y;

    if (_isEditMode && scrollDirection == ScrollDirectionDown && _datePickerVisible) {
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0.0f) animated:NO];
        [self hideDatePicker];
    }
}

#pragma mark - UIAlertViewDelegate -

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if (alertView.cancelButtonIndex != buttonIndex) {
        [self deleteTransaction];
    }
}

@end
