#import "AddExpenseViewController.h"

    //CoreData
#import "Expense.h"
#import "ExpenseData.h"
#import "CategoryData.h"
#import "Fetch.h"


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

    UIBarButtonItem *_doneBarButtonItem;
    UITableView *_tableView;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];
    [self customSetUp];
}

- (void)customSetUp {
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

- (CGRect)tableViewRect {
        //8 and 16 are space values to layoutGuide and so on
    CGRect tableViewRect;
    CGFloat originY = self.expenseTextField.frame.origin.y + self.expenseTextField.frame.size.height + 8;
    if (_isChosenCategory) {
        CGFloat height = 44;
        tableViewRect = CGRectMake(0, originY, self.view.frame.size.width, height);
    } else {
        CGFloat width = self.view.frame.size.width;
        CGFloat height = self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.expenseTextField.frame.size.height - 16;
        tableViewRect = CGRectMake(0, originY, width, height);
    }
    return tableViewRect;
}

- (void)removeTableView {
    [_tableView removeFromSuperview];
    _tableView.dataSource = nil;
    _tableView.delegate = nil;
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

        if (_expenseFromTextField.floatValue > 0.0f) {
            [self createDoneBarButton];
        }
    } else {
        _isChosenCategory = NO;
        _selectedRow = nil;

        [self.descriptionTextField resignFirstResponder];
        self.descriptionTextField.hidden = YES;

        [self removeTableView];
        [self createTableView];
        [self removeDoneBarButton];
    }
}

#pragma mark - CustomDoneBarButtonItem -

- (void)createDoneBarButton {
    _doneBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(doneBarButtonPressed:)];
    self.navigationItem.rightBarButtonItem = _doneBarButtonItem;
}

- (void)removeDoneBarButton {
    self.navigationItem.rightBarButtonItem = nil;
    _doneBarButtonItem = nil;
}

- (void)doneBarButtonPressed:(UIBarButtonItem *)doneBarButton {
    Expense *expense = [Expense expenseWithAmount:_expenseFromTextField category:_categories[_selectedRow.row] description:_descriptionTextField.text];

    [self addExpenseToCategoryData:expense];

    [self.descriptionTextField resignFirstResponder];

    [self.delegate addExpenseViewController:self didFinishAddingExpense:expense];
}

- (void)addExpenseToCategoryData:(Expense *)expense {
    CategoryData *categoryData = [Fetch findCategoryFromTitle:expense.category context:_managedObjectContext];

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

        if (_isChosenCategory) {
            if (!_doneBarButtonItem) {
                [self createDoneBarButton];
            }
        }

    } else if (stringFromTextField.length == 0) {
        if (_expenseFromTextField) {
            _expenseFromTextField = @(0.0f);
        }
        if (_doneBarButtonItem) {
            [self removeDoneBarButton];
        }
    }
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    _expenseFromTextField = [NSNumber numberWithFloat:[textField.text floatValue]];
}

#pragma mark - IBAction -

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    if (!_isChosenCategory)
        [self.expenseTextField resignFirstResponder];
    else
        [self.descriptionTextField resignFirstResponder];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)descriptionTextFieldDidEndOnExit:(UITextField *)sender {
    [self doneBarButtonPressed:nil];
}

@end