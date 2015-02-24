#import "AddExpenseViewController.h"

    //CoreData
#import "Expense.h"
#import "ExpenseData.h"
#import "CategoryData.h"
#import "CategoryData+Fetch.h"

    //KVNProgress
#import <KVNProgress/KVNProgress.h>

@interface AddExpenseViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *expenseTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;
- (IBAction)descriptionTextFieldDidEndOnExit:(UITextField *)sender;

@end

@implementation AddExpenseViewController {
    NSNumber *_expenseFromTextField;
    NSIndexPath *_selectedRow;
    BOOL _isChosenCategory;

    UITableView *_tableView;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];
    [self customSetUp];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
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
}

#pragma mark - CustomTableView -

- (void)createTableView {
    _tableView = [[UITableView alloc]initWithFrame:[self tableViewRect] style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeInteractive;

    [self.view addSubview:_tableView];
}

#warning remake this using constraints
- (CGRect)tableViewRect {
        //8 and 16 are space values to layoutGuide and so on
    CGRect tableViewRect;
    CGFloat originY = self.expenseTextField.frame.origin.y + self.expenseTextField.frame.size.height + 8;
    if (_isChosenCategory) {
        CGFloat height = 44;
        tableViewRect = CGRectMake(0, originY, self.view.frame.size.width, height);
    } else {
        CGFloat width = CGRectGetWidth(self.view.bounds);
        CGFloat height = self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.expenseTextField.frame.size.height - 16;
        tableViewRect = CGRectMake(0, originY, width, height);
    }
    return tableViewRect;
}

- (void)removeTableView {
    [_tableView removeFromSuperview];
    _tableView = nil;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (_isChosenCategory ? 1 : [_categories count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc]initWithStyle:(_isChosenCategory ? UITableViewCellStyleValue1 : UITableViewCellStyleDefault) reuseIdentifier:identifier];
    }
    [self configurateCell:cell indexPath:indexPath];

    return cell;
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

        [self removeTableView];
        [self createTableView];

        _tableView.scrollEnabled = NO;
    } else {
        _isChosenCategory = NO;
        _selectedRow = nil;

        [self.descriptionTextField resignFirstResponder];
        self.descriptionTextField.hidden = YES;

        [self removeTableView];
        [self createTableView];
    }
}

#pragma mark - Helper Methods -

- (void)resignActiveTextField {
    [self.expenseTextField resignFirstResponder];
    [self.descriptionTextField resignFirstResponder];
}

#pragma mark - DoneBarButtonItem -

- (void)createDoneBarButton {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneBarButtonPressed:)];
    self.navigationItem.rightBarButtonItem = doneButton;
}

- (void)doneBarButtonPressed:(UIBarButtonItem *)doneBarButton {
    [self resignActiveTextField];

    if (_expenseFromTextField.floatValue > 0.0f && _isChosenCategory) {
        Expense *expense = [Expense expenseWithAmount:_expenseFromTextField categoryName:_categories[_selectedRow.row] description:_descriptionTextField.text];

        [self addExpenseToCategoryData:expense];

        if ([self.delegate respondsToSelector:@selector(addExpenseViewController:didFinishAddingExpense:)]) {
            [self.delegate addExpenseViewController:self didFinishAddingExpense:expense];

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

    NSString *stringFromTextField = [textField.text stringByReplacingCharactersInRange:range withString:string];

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
    _expenseFromTextField = [NSNumber numberWithFloat:[textField.text floatValue]];
}

#pragma mark - IBAction -

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self resignActiveTextField];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)descriptionTextFieldDidEndOnExit:(UITextField *)sender {
    [self doneBarButtonPressed:nil];
}

@end