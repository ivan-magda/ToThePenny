#import "AddExpenseViewController.h"

    //CoreData
#import "Expense.h"
#import "ExpenseData.h"
#import "CategoryData.h"
#import "CategoryData+Fetch.h"

    //KVNProgress
#import <KVNProgress/KVNProgress.h>

static const CGFloat kDefaultTableViewCellHeight = 44.0f;

@interface AddExpenseViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *expenseTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *expenseTextFieldConstraintTop;

@property (nonatomic, strong) UITableView *tableView;
@property (weak, nonatomic) NSLayoutConstraint *tableViewConstraintHeight;

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)descriptionTextFieldDidEndOnExit:(UITextField *)sender;

@end

@implementation AddExpenseViewController {
    NSNumber *_expenseFromTextField;
    NSIndexPath *_selectedRow;
    BOOL _isChosenCategory;

    BOOL _isDelegateNotified;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];
    [self customSetUp];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (!_isDelegateNotified) {
        [self resignActiveTextField];

        [self.delegate addExpenseViewControllerDidCancel:self];

        _isDelegateNotified = YES;
    }
}

- (void)dealloc {
    NSLog(@"Dealloc %@", self);
}

- (void)customSetUp {
    [self createDoneBarButton];
    [self createTableView];

    [self.expenseTextField becomeFirstResponder];
    self.expenseTextField.delegate = self;

    self.descriptionTextField.hidden = YES;

    _isDelegateNotified = NO;
}

#pragma mark - UITableView

- (void)createTableView {
    self.tableView = [[UITableView alloc]initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.view addSubview:self.tableView];

        //Constraints
    NSDictionary *viewsDictionary = @{@"tableView" : self.tableView};

    NSArray *horzConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|" options:0 metrics:nil views:viewsDictionary];
    [self.view addConstraints:horzConstraints];

    NSLayoutConstraint *topConstraint = [NSLayoutConstraint constraintWithItem:self.expenseTextField attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    [self.view addConstraint:topConstraint];

    CGFloat height = [self calculateHeight];
    NSArray *heigthConstraints = [NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:[tableView(==%f)]", height] options:0 metrics:nil views:viewsDictionary];
    NSParameterAssert(heigthConstraints.count == 1);

    self.tableViewConstraintHeight = [heigthConstraints firstObject];
    [self.view addConstraint:self.tableViewConstraintHeight];
}

- (CGFloat)calculateHeight {
    if (_isChosenCategory) {
        return kDefaultTableViewCellHeight + 1.0f;
    } else {
        CGFloat superViewHeight = CGRectGetHeight(self.view.bounds);
        CGFloat statusBarHeight = CGRectGetHeight([[UIApplication sharedApplication]statusBarFrame]);
        CGFloat navigationBarHeight = CGRectGetHeight(self.navigationController.navigationBar.bounds);
        CGFloat expenseTextFieldHeight = CGRectGetHeight(self.expenseTextField.bounds);
        CGFloat expenseTextFieldTopSpace = self.expenseTextFieldConstraintTop.constant;

        return (superViewHeight - statusBarHeight - navigationBarHeight - expenseTextFieldHeight - expenseTextFieldTopSpace);
    }
}

#pragma mark UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (_isChosenCategory ? 1 : [_categories count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *defaultIdentifier = @"Cell";
    NSString *selectedIdentifier = @"Selected";

    if (_isChosenCategory) {
        UITableViewCell *selectedCategoryCell = [tableView dequeueReusableCellWithIdentifier:selectedIdentifier];
        if (selectedCategoryCell == nil) {
            selectedCategoryCell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:selectedIdentifier];
        }
        [self configurateCell:selectedCategoryCell indexPath:indexPath];

        return selectedCategoryCell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:defaultIdentifier];
        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:defaultIdentifier];
        }
        [self configurateCell:cell indexPath:indexPath];

        return cell;
    }
}

- (void)configurateCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    if (cell) {
        if (!_isChosenCategory) {
            cell.textLabel.text = _categories[indexPath.row];
        } else {
            cell.textLabel.text = _categories[_selectedRow.row];
            cell.detailTextLabel.text = @"X";
        }
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.expenseTextField resignFirstResponder];

    if (!_isChosenCategory) {
        _isChosenCategory = YES;
        _selectedRow = indexPath;

        self.descriptionTextField.hidden = NO;
        [self.descriptionTextField becomeFirstResponder];

        self.tableViewConstraintHeight.constant = [self calculateHeight];
        _tableView.scrollEnabled = NO;
        [self.tableView reloadData];
    } else {
        _isChosenCategory = NO;
        _selectedRow = nil;

        [self.descriptionTextField resignFirstResponder];
        self.descriptionTextField.hidden = YES;

        self.tableViewConstraintHeight.constant = [self calculateHeight];
        self.tableView.scrollEnabled = YES;
        [self.tableView reloadData];
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
        Expense *expense = [Expense expenseWithAmount:_expenseFromTextField categoryName:_categories[_selectedRow.row] description:_descriptionTextField.text];

        [self addExpenseToCategoryData:expense];

        if ([self.delegate respondsToSelector:@selector(addExpenseViewController:didFinishAddingExpense:)]) {
            [self.delegate addExpenseViewController:self didFinishAddingExpense:expense];

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

    [self.delegate addExpenseViewControllerDidCancel:self];

    _isDelegateNotified = YES;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self dismissViewControllerAnimated:YES completion:nil];
    });
}

- (IBAction)descriptionTextFieldDidEndOnExit:(UITextField *)sender {
    [self doneBarButtonPressed:nil];
}

@end