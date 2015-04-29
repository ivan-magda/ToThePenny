#import "AddExpenseTableViewController.h"

    //CoreData
#import "Expense.h"
#import "ExpenseData.h"
#import "CategoryData.h"
#import "CategoryData+Fetch.h"
#import "CategoriesInfo.h"
    //KVNProgress
#import <KVNProgress/KVNProgress.h>

static NSString * const kExpenseTextFieldCellIdentifier     = @"ExpenseTextFieldCell";
static NSString * const kCategoryCellIdentifier             = @"CategoryCell";
static NSString * const kDescriptionTextFieldCellIdentifier = @"DescriptionFieldCell";

static const NSInteger kExpenseTextFieldTag = 555;
static const NSInteger kDescriptionTextFieldTag = 777;

@interface AddExpenseTableViewController () <UITextFieldDelegate>

@property (weak, nonatomic) UITextField *expenseTextField;
@property (weak, nonatomic) UITextField *descriptionTextField;

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)descriptionTextFieldDidEndOnExit:(UITextField *)sender;

@end

@implementation AddExpenseTableViewController {
    NSNumber *_expenseFromTextField;
    NSIndexPath *_selectedRow;
    BOOL _isChosenCategory;

    BOOL _isDelegateNotified;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createDoneBarButton];

    _isDelegateNotified = NO;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.expenseTextField becomeFirstResponder];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (!_isDelegateNotified) {
        [self resignActiveTextField];

        [self.delegate addExpenseTableViewControllerDidCancel:self];

        _isDelegateNotified = YES;
    }
}

#pragma mark - UITableViewDataSource -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return (_isChosenCategory ? 1 : [_categoriesInfo count]);
    } else {
        return (_isChosenCategory ? 1 : 0);
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        UITableViewCell *expenseTextFieldCell = [tableView dequeueReusableCellWithIdentifier:kExpenseTextFieldCellIdentifier];

        self.expenseTextField = (UITextField *)[expenseTextFieldCell viewWithTag:kExpenseTextFieldTag];
        self.expenseTextField.delegate = self;

        return expenseTextFieldCell;
    } else if (indexPath.section == 1) {
        NSString *selectedIdentifier = @"SelectedCell";

        if (_isChosenCategory) {
            UITableViewCell *selectedCategoryCell = [tableView dequeueReusableCellWithIdentifier:selectedIdentifier];
            if (selectedCategoryCell == nil) {
                selectedCategoryCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:selectedIdentifier];
            }
            [self configurateCell:selectedCategoryCell indexPath:indexPath];

            return selectedCategoryCell;
        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCategoryCellIdentifier];
            [self configurateCell:cell indexPath:indexPath];

            return cell;
        }
    } else if (indexPath.section == 2) {
        UITableViewCell *descriptionCell = [tableView dequeueReusableCellWithIdentifier:kDescriptionTextFieldCellIdentifier];

        self.descriptionTextField = (UITextField *)[descriptionCell viewWithTag:kDescriptionTextFieldTag];

        return descriptionCell;
    }
    return nil;
}

- (void)configurateCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (cell) {
        if (!_isChosenCategory) {
            CategoriesInfo *category = _categoriesInfo[indexPath.row];

            cell.textLabel.text = category.title;
            cell.imageView.image = [UIImage imageNamed:category.iconName];
        } else {
            CategoriesInfo *category = _categoriesInfo[_selectedRow.row];

            cell.textLabel.text = category.title;
            cell.detailTextLabel.text = @"X";
        }
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        [self.expenseTextField becomeFirstResponder];
        return;
    }
    if (indexPath.section == 2) {
        [self.descriptionTextField becomeFirstResponder];
    }
    [self.expenseTextField resignFirstResponder];

    if (!_isChosenCategory) {
        _isChosenCategory = YES;
        _selectedRow = indexPath;

        self.tableView.scrollEnabled = NO;
        [self.tableView reloadData];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.descriptionTextField becomeFirstResponder];
        });
    } else {
        _isChosenCategory = NO;
        _selectedRow = nil;

        [self.descriptionTextField resignFirstResponder];

        self.tableView.scrollEnabled = YES;
        [self.tableView reloadData];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 64.0f;
    } else if (indexPath.section == 1) {
        return 54.0f;
    } else {
        return 44.0f;
    }
}

#pragma mark - Helper Methods -

- (void)resignActiveTextField {
    [self.expenseTextField resignFirstResponder];
    [self.descriptionTextField resignFirstResponder];
}

#pragma mark - DoneBarButton -

- (void)createDoneBarButton {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneBarButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)doneBarButtonPressed:(UIBarButtonItem *)doneBarButton {
    [self resignActiveTextField];

    if (_expenseFromTextField.floatValue > 0.0f && _isChosenCategory) {
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
    } else if (_expenseFromTextField.floatValue == 0.0f && _isChosenCategory){
        [KVNProgress showErrorWithStatus:@"Please enter the amount of expense" completion:^{
            [_expenseTextField becomeFirstResponder];
        }];
    } else if (_expenseFromTextField.floatValue > 0.0f && !_isChosenCategory) {
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
    expenseData.dateOfExpense = expense.dateOfExpense;
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