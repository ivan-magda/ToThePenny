#import "AddExpenseViewController.h"
#import "Expense.h"

@implementation CategoryTableViewCell

@end


@interface AddExpenseViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *textField;

@end

@implementation AddExpenseViewController {
    NSNumber *_expenseFromTextField;
    UIBarButtonItem *_doneBarButtonItem;
    NSArray *_categories;
    NSIndexPath *_selectedRow;
    UITableView *_tableView;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];
    [self customSetUp];

    _categories = @[@"Связь", @"Вещи", @"Здоровье", @"Продукты", @"Еда вне дома", @"Жилье", @"Поездки", @"Другое", @"Развлечения", @"Test", @"Test", @"Test"];
}

- (void)customSetUp {
    [self createTableView];

    [self.textField becomeFirstResponder];
    self.textField.delegate = self;
}

#pragma mark - CustomTableView -

- (void)createTableView {
    _tableView = [[UITableView alloc]initWithFrame:[self tableViewRect] style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;

    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(hideKeyboard:)];
    gestureRecognizer.cancelsTouchesInView = NO;
    [_tableView addGestureRecognizer:gestureRecognizer];

    [self.view addSubview:_tableView];
}

- (CGRect)tableViewRect {
    CGFloat y = self.textField.frame.origin.y + self.textField.frame.size.height + 8;
    CGFloat width = self.view.frame.size.width;
    CGFloat height = self.view.frame.size.height - self.navigationController.navigationBar.frame.size.height - self.navigationController.navigationBar.frame.origin.y - self.textField.frame.size.height - 16;

    CGRect tableViewRect = CGRectMake(0, y, width, height);
    return tableViewRect;
}

#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_categories count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *identifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
    }
    [self configurateCell:cell indexPath:indexPath];

    return cell;
}

- (void)configurateCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath
{
    if (cell) {
        cell.textLabel.text = _categories[indexPath.row];

        if (cell.accessoryType == UITableViewCellAccessoryCheckmark) {
            if (_selectedRow.row != indexPath.row) {
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
        } else if (_selectedRow) {
            if (_selectedRow.row == indexPath.row) {
                cell.accessoryType = UITableViewCellAccessoryCheckmark;
            }
        }
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configurateCheckmarkForCellAtIndexPath:indexPath tableView:tableView];

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)configurateCheckmarkForCellAtIndexPath:(NSIndexPath *)indexPath tableView:(UITableView *)tableView
{
    if (_selectedRow == indexPath) {
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:_selectedRow];
        [self changeAccessorytype:cell];
        _selectedRow = nil;
    } else {
        if (_selectedRow) {
            UITableViewCell *oldCell = [tableView cellForRowAtIndexPath:_selectedRow];
            [self changeAccessorytype:oldCell];
        }
        UITableViewCell *newCell = [tableView cellForRowAtIndexPath:indexPath];
        [self changeAccessorytype:newCell];
        _selectedRow = indexPath;
    }
}

- (void)changeAccessorytype:(UITableViewCell *)cell {
    if (cell.accessoryType == UITableViewCellAccessoryNone) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    } else {
        cell.accessoryType = UITableViewCellAccessoryNone;
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
    [self.textField resignFirstResponder];
    [self removeDoneBarButton];
}

#pragma mark - UITextFieldDelegate -

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    NSString *stringFromTextField = [textField.text stringByReplacingCharactersInRange:range withString:string];
    if (stringFromTextField.length > 0) {
        _expenseFromTextField = [NSNumber numberWithFloat:[stringFromTextField floatValue]];
        [self createDoneBarButton];
    } else if (stringFromTextField.length == 0) {
        if (_doneBarButtonItem)
            [self removeDoneBarButton];
        if (_expenseFromTextField)
            _expenseFromTextField = @(0.0f);
    }

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    _expenseFromTextField = [NSNumber numberWithFloat:[textField.text floatValue]];
}

- (void)hideKeyboard:(UIGestureRecognizer *)gestureRecognizer {
    [self.textField resignFirstResponder];
}

@end