    //ViewControllers
#import "AddExpenseTableViewController.h"
    //View
#import "SelectedCategoryCell.h"
#import "SearchForCategoryCell.h"
    //CoreData
#import "Expense.h"
#import "ExpenseData.h"
#import "CategoryData+Fetch.h"
#import "CategoriesInfo.h"
    //Categories
#import "NSString+FormatAmount.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"
#import "NSDate+IsDatesWithEqualDate.h"
    //KVNProgress
#import <KVNProgress/KVNProgress.h>

static NSString * const kExpenseTextFieldCellIdentifier     = @"ExpenseTextFieldCell";
static NSString * const kCategoryCellIdentifier             = @"CategoryCell";
static NSString * const kDescriptionTextFieldCellIdentifier = @"DescriptionFieldCell";
static NSString * const kSelectedCategoryCellIdentifier     = @"SelectedCategoryCell";

static const NSInteger kExpenseTextFieldTag = 555;
static const NSInteger kDescriptionTextFieldTag = 777;
static const NSInteger kSearchBarTag = 240;

static const CGFloat kExpenseTextFieldHeight = 64.0f;
static const CGFloat kCustomTableViewCellHeight = 44.0f;

typedef NS_ENUM(NSUInteger, SectionType) {
    SectionTypeSelectionDate,
    SectionTypeExpenseAmount,
    SectionTypeSearchForCategory,
    SectionTypeCategoriesTitles,
    SectionTypeDescription
};

@interface AddExpenseTableViewController () <UITextFieldDelegate>

@property (weak, nonatomic) UITextField *expenseTextField;
@property (weak, nonatomic) UITextField *descriptionTextField;
@property (weak, nonatomic) UISearchBar *searchBar;

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)descriptionTextFieldDidEndOnExit:(UITextField *)sender;

@end

@implementation AddExpenseTableViewController {
    NSNumber *_expenseFromTextField;
    NSIndexPath *_selectedRow;
    BOOL categorySelected;

    BOOL _isDelegateNotified;

    BOOL _datePickerVisible;
    NSDate *_dateExpense;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    self.categoriesInfo = [self sortedCategoriesFromCategoriesInfo:_categoriesInfo];

    [self createDoneBarButton];

    _isDelegateNotified = NO;
    _datePickerVisible = NO;
    _dateExpense = [NSDate date];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self expenseTextFieldBecomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (!_isDelegateNotified) {
        [self resignActiveTextField];

        [self.delegate addExpenseTableViewControllerDidCancel:self];

        _isDelegateNotified = YES;
    }
}

#pragma mark - SortCategories -

- (NSArray *)sortedCategoriesFromCategoriesInfo:(NSArray *)categories {
    NSSortDescriptor *alphabeticSort = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(title)) ascending:YES selector:@selector(caseInsensitiveCompare:)];

    NSArray *sortedArray = [_categoriesInfo sortedArrayUsingDescriptors:@[alphabeticSort]];

        //Sort by frequency of use
    NSArray *dates = [[NSDate date]getFirstAndLastDaysInTheCurrentMonth];
    __weak NSManagedObjectContext *context = _managedObjectContext;

    NSSortDescriptor *sortByFrequencyUse = [NSSortDescriptor sortDescriptorWithKey:nil ascending:NO comparator:^NSComparisonResult(CategoriesInfo *obj1, CategoriesInfo *obj2) {

        NSUInteger countForCategory1 = [CategoryData countForFrequencyUseInManagedObjectContext:context betweenDates:dates andWithCategoryIdValue:obj1.idValue];
        NSUInteger countForCategory2 = [CategoryData countForFrequencyUseInManagedObjectContext:context betweenDates:dates andWithCategoryIdValue:obj2.idValue];

        if (countForCategory1 < countForCategory2) {
            return NSOrderedAscending;
        } else if (countForCategory1 > countForCategory2) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];

    return [sortedArray sortedArrayUsingDescriptors:@[sortByFrequencyUse]];
}

#pragma mark - UITableViewDataSource -

    // 0 section for date and date picker
    // 1 section for amount text field
    // 2 section for search for category search bar
    // 3 section for categories titles
    // 4 section for description text field
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 5;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case SectionTypeSelectionDate:
            return (_datePickerVisible ? 2 : 1);
            break;
        case SectionTypeExpenseAmount:
            return 1;
            break;
        case SectionTypeSearchForCategory:
            return (categorySelected ? 0 : 1);
        case SectionTypeCategoriesTitles:
            return (categorySelected ? 1 : [_categoriesInfo count]);
            break;
        case SectionTypeDescription:
            return (categorySelected ? 1 : 0);
            break;
        default:
            return 0;
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat y;
    if (indexPath.section == SectionTypeExpenseAmount) {
        y = kExpenseTextFieldHeight - 0.5f;
    } else if (_datePickerVisible && indexPath.section == 0 && indexPath.row == 1) {
        y = 217.0f - 0.5f;
    } else {
        y = kCustomTableViewCellHeight - 0.5f;
    }
    
    CGRect separatorFrame = CGRectMake(15.0f, y, CGRectGetWidth(tableView.bounds), 0.5f);
    UIView *separatorLineView = [[UIView alloc]initWithFrame:separatorFrame];
    separatorLineView.backgroundColor = tableView.separatorColor;

    if (indexPath.section == SectionTypeSelectionDate) {
        if (indexPath.row == 0) {
            NSString *identifier = @"DateCell";
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

            if (cell == nil) {
                cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
                cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:17.0f];
                [cell.contentView addSubview:separatorLineView];
            }

            cell.textLabel.text = [self formatDate:_dateExpense];

            return cell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DatePickerCell"];

            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DatePickerCell"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;

                UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetHeight(self.view.bounds), 216.0f)];
                datePicker.tag = 112;

                [datePicker setMaximumDate:[NSDate getStartAndEndDatesOfTheCurrentDate].lastObject];
                [datePicker setDate:_dateExpense];

                [cell.contentView addSubview:datePicker];
                [cell.contentView addSubview:separatorLineView];

                [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
            }

            UIDatePicker *datePicker = (UIDatePicker *)[cell viewWithTag:112];
            [datePicker setDate:_dateExpense animated:NO];

            return cell;
        }
    } else if (indexPath.section == SectionTypeExpenseAmount) {
        UITableViewCell *expenseTextFieldCell = [tableView dequeueReusableCellWithIdentifier:kExpenseTextFieldCellIdentifier];

        self.expenseTextField = (UITextField *)[expenseTextFieldCell viewWithTag:kExpenseTextFieldTag];
        self.expenseTextField.delegate = self;
        self.expenseTextField.placeholder = [NSString formatAmount:@0];

        [expenseTextFieldCell.contentView addSubview:separatorLineView];

        return expenseTextFieldCell;
    } else if (indexPath.section == SectionTypeSearchForCategory) {
        SearchForCategoryCell *cell = (SearchForCategoryCell *)[tableView dequeueReusableCellWithIdentifier:@"SearchFoarCategoryCell"];
        [cell.contentView addSubview:separatorLineView];

        self.searchBar = (UISearchBar *)[cell viewWithTag:kSearchBarTag];

        return cell;
    } else if (indexPath.section == SectionTypeCategoriesTitles) {
        if (categorySelected) {
            SelectedCategoryCell *selectedCategoryCell = (SelectedCategoryCell *)[tableView dequeueReusableCellWithIdentifier:kSelectedCategoryCellIdentifier];

            [self configurateCell:selectedCategoryCell indexPath:indexPath];

            [selectedCategoryCell.contentView addSubview:separatorLineView];

            return selectedCategoryCell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCategoryCellIdentifier];
            [self configurateCell:cell indexPath:indexPath];

            [cell.contentView addSubview:separatorLineView];

            return cell;
        }
    } else if (indexPath.section == SectionTypeDescription) {
        UITableViewCell *descriptionCell = [tableView dequeueReusableCellWithIdentifier:kDescriptionTextFieldCellIdentifier];

        self.descriptionTextField = (UITextField *)[descriptionCell viewWithTag:kDescriptionTextFieldTag];

        [descriptionCell.contentView addSubview:separatorLineView];

        return descriptionCell;
    }
    return nil;
}

- (void)configurateCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (cell) {
        if (!categorySelected) {
            CategoriesInfo *category = _categoriesInfo[indexPath.row];

            cell.textLabel.text = category.title;
        } else {
            CategoriesInfo *category = _categoriesInfo[_selectedRow.row];

            SelectedCategoryCell *selectedCell = (SelectedCategoryCell *)cell;
            selectedCell.categoryTitle.text = category.title;
        }
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SectionTypeSelectionDate) {
        [self.expenseTextField resignFirstResponder];
        
        if (!_datePickerVisible) {
            [self showDatePicker];
        } else {
            [self hideDatePicker];
        }
        return;
    }
        // Also hide the date picker when tapped on any other row.
    [self hideDatePicker];

    if (indexPath.section == SectionTypeExpenseAmount) {
        [self.expenseTextField becomeFirstResponder];
        return;
    } else if (indexPath.section == SectionTypeSearchForCategory) {
        [self.searchBar becomeFirstResponder];
        return;
    } else if (indexPath.section == SectionTypeDescription) {
        [self.descriptionTextField becomeFirstResponder];
        return;
    }

    [self.searchBar resignFirstResponder];
    [self.expenseTextField resignFirstResponder];

    if (!categorySelected) {
        categorySelected = YES;
        _selectedRow = indexPath;

        [self reloadTableViewSections];

        [self descriptionTextFieldBecomeFirstResponder];
    } else {
        categorySelected = NO;
        _selectedRow = nil;

        self.descriptionTextField.text = nil;
        [self.descriptionTextField resignFirstResponder];

        [self reloadTableViewSections];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_datePickerVisible && indexPath.section == SectionTypeSelectionDate && indexPath.row == 1) {
        return 217.0f;
    } else if (indexPath.section == SectionTypeExpenseAmount) {
        return kExpenseTextFieldHeight;
    } else {
        return kCustomTableViewCellHeight;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == SectionTypeSelectionDate && indexPath.row == 1) {
        return nil;
    }
    return indexPath;
}

#pragma mark - Helper Methods -

- (void)reloadTableViewSections {
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(2, 3)] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (void)expenseTextFieldBecomeFirstResponder {
    if (_expenseTextField != nil) {
        [self.expenseTextField becomeFirstResponder];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self expenseTextFieldBecomeFirstResponder];
        });
    }
}

- (void)descriptionTextFieldBecomeFirstResponder {
    if (_descriptionTextField != nil) {
        [self.descriptionTextField becomeFirstResponder];
    } else {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.descriptionTextField becomeFirstResponder];
        });
    }
}

- (void)resignActiveTextField {
    [self.expenseTextField resignFirstResponder];
    [self.descriptionTextField resignFirstResponder];
}

#pragma mark Date

- (NSString *)formatDate:(NSDate *)date {
    static NSDateFormatter *dateFormatter = nil;
    static NSDateFormatter *todayFormatter = nil;
    if (dateFormatter == nil || todayFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.timeZone = [NSTimeZone localTimeZone];
        dateFormatter.dateFormat = @"d MMMM HH:mm";

        todayFormatter = [NSDateFormatter new];
        todayFormatter.timeZone = [NSTimeZone localTimeZone];
        todayFormatter.dateFormat = @"HH:mm";

    }

    if ([[NSDate date]isDatesWithEqualDates:date]) {
        return [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Today", @"'Today' text in -formatDate:"), [todayFormatter stringFromDate:date]];
    }

    return [dateFormatter stringFromDate:date];
}

- (void)updateDateLabelWithDate:(NSDate *)date {
    NSString *formatDate = [self formatDate:date];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[self dateCellIndexPath]];
    cell.textLabel.text = formatDate;
}

#pragma mark DatePicker

- (void)dateChanged:(UIDatePicker *)datePicker {
    _dateExpense = datePicker.date;
    [self updateDateLabelWithDate:_dateExpense];
}

- (NSIndexPath *)dateCellIndexPath {
    return [NSIndexPath indexPathForRow:0 inSection:0];
}

- (void)showDatePicker {
    _datePickerVisible = YES;

    [self.expenseTextField resignFirstResponder];
    [self.descriptionTextField resignFirstResponder];

    [self reloadFirstSection];

    [self updateDateCellDateTextColorWithColor:[self.view tintColor] atIndexPath:[self dateCellIndexPath]];
}

- (void)hideDatePicker {
    if (_datePickerVisible) {
        _datePickerVisible = NO;

        [self updateDateCellDateTextColorWithColor:[UIColor blackColor] atIndexPath:[self dateCellIndexPath]];

        [self reloadFirstSection];
    }
}

- (void)reloadFirstSection {
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (void)updateDateCellDateTextColorWithColor:(UIColor *)color atIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.textLabel.textColor = color;
}

#pragma mark - DoneBarButton -

- (void)createDoneBarButton {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)doneBarButtonPressed:(UIBarButtonItem *)doneBarButton {
    [self resignActiveTextField];

    if (_expenseFromTextField.floatValue > 0.0f && categorySelected) {
        CategoriesInfo *category = _categoriesInfo[_selectedRow.row];

        Expense *expense = [Expense expenseWithAmount:_expenseFromTextField categoryName:category.title description:_descriptionTextField.text];

        [self addExpenseToCategoryData:expense];

        if ([self.delegate respondsToSelector:@selector(addExpenseTableViewController:didFinishAddingExpense:)]) {
            [self.delegate addExpenseTableViewController:self didFinishAddingExpense:expense];

            _isDelegateNotified = YES;

            [KVNProgress showSuccessWithStatus:@"Added" completion:^{
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        } else {
            NSParameterAssert(NO);
        }
    } else if (_expenseFromTextField.floatValue == 0.0f && categorySelected){
        [KVNProgress showErrorWithStatus:@"Please enter the amount of expense" completion:^{
            [_expenseTextField becomeFirstResponder];
        }];
    } else if (_expenseFromTextField.floatValue > 0.0f && !categorySelected) {
        [KVNProgress showErrorWithStatus:@"Please choose category" completion:^{
            [self resignActiveTextField];
        }];
    } else {
        [KVNProgress showErrorWithStatus:@"Please enter the data" completion:^{
            [_expenseTextField becomeFirstResponder];
        }];
    }
}

#pragma mark WorkWithCoreData

- (void)addExpenseToCategoryData:(Expense *)expense {
    CategoryData *categoryData = [CategoryData categoryFromTitle:expense.category context:_managedObjectContext];

    ExpenseData *expenseData = [NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([ExpenseData class]) inManagedObjectContext:self.managedObjectContext];
    expenseData.amount = expense.amount;
    expenseData.categoryId = categoryData.idValue;
    expenseData.dateOfExpense = _dateExpense;
    expenseData.descriptionOfExpense = expense.descriptionOfExpense;
    expenseData.idValue = @(expense.idValue);
    expenseData.category = categoryData;

    [categoryData addExpenseObject:expenseData];

    NSError *error;
    if (![self.managedObjectContext save:&error]) {
        NSLog(@"Whoops, couldn't save: %@", [error localizedDescription]);
    }
}

#pragma mark - UITextFieldDelegate -

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    if (_datePickerVisible) {
        [self hideDatePicker];
    }

    NSString *text = textField.text;
    if (text.length > 0) {
        NSMutableCharacterSet *charactersToKeep = [NSMutableCharacterSet decimalDigitCharacterSet];
        [charactersToKeep addCharactersInString:@","];

        NSCharacterSet *charactersToRemove = [charactersToKeep invertedSet];

        NSString *newString = [[text componentsSeparatedByCharactersInSet:charactersToRemove]
                               componentsJoinedByString:@""];
        textField.text = newString;
    }
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *stringFromTextField = stringFromTextField = [[textField.text stringByReplacingCharactersInRange:range withString:string]stringByReplacingOccurrencesOfString:@"," withString:@"."];

    if (stringFromTextField.length > 0) {
        _expenseFromTextField = [NSNumber numberWithFloat:[stringFromTextField floatValue]];
    } else if (stringFromTextField.length == 0) {
        if (_expenseFromTextField) {
            _expenseFromTextField = @(0.0f);
        }
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    _expenseFromTextField = [NSNumber numberWithFloat:[[textField.text stringByReplacingOccurrencesOfString:@"," withString:@"." ]floatValue]];

    if (_expenseFromTextField.floatValue > 0) {
        textField.text = [NSString formatAmount:_expenseFromTextField];
    } else {
        textField.text = nil;
    }
}

#pragma mark - IBAction -

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self resignActiveTextField];

    [self.delegate addExpenseTableViewControllerDidCancel:self];

    _isDelegateNotified = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (IBAction)descriptionTextFieldDidEndOnExit:(UITextField *)sender {
    [self doneBarButtonPressed:nil];
}

@end