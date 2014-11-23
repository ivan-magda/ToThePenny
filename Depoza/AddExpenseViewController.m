#import "AddExpenseViewController.h"
#import "Expense.h"


@interface AddExpenseViewController () <UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *expenseTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;

@end

@implementation AddExpenseViewController {
    NSNumber *_expenseFromTextField;
    NSArray *_categories;
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

    _categories = @[@"Связь", @"Вещи", @"Здоровье", @"Продукты", @"Еда вне дома", @"Жилье", @"Поездки", @"Другое", @"Развлечения"];
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
    if (!_isChosenCategory) {
        _isChosenCategory = YES;
        _selectedRow = indexPath;

        self.descriptionTextField.hidden = NO;
        [self.descriptionTextField becomeFirstResponder];

        [self removeTableView];
        [self createTableView];
    } else {
        _isChosenCategory = NO;
        _selectedRow = nil;

        self.descriptionTextField.hidden = YES;

        [self removeTableView];
        [self createTableView];
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
    [self.expenseTextField resignFirstResponder];
    [self removeDoneBarButton];
}

#pragma mark - UITextFieldDelegate -

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
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
    [self.expenseTextField resignFirstResponder];
}

@end