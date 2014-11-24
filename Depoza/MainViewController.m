#import "MainViewController.h"
#import "SWRevealViewController.h"
#import "AddExpenseViewController.h"
#import "Expense.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *revealBarButton;

@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalSummaLabel;

@property (weak, nonatomic) IBOutlet UILabel *firstCategoryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondCategoryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdCategoryNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *firstCategorySummaLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondCategorySummaLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdCategorySummaLabel;

@end

@implementation MainViewController {
    CGFloat _totalExpeditures;

    NSMutableDictionary *_categories;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    [self customSetUp];
    [self updateLabels];
}

- (void)customSetUp {
    self.revealBarButton.target = self.revealViewController;
    self.revealBarButton.action = @selector(revealToggle:);

    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];

    _categories = [@{
                    @"Связь"        : @0,
                    @"Вещи"         : @0,
                    @"Здоровье"     : @0,
                    @"Продукты"     : @0,
                    @"Еда вне дома" : @0,
                    @"Жилье"        : @0,
                    @"Поездки"      : @0,
                    @"Другое"       : @0,
                    @"Развлечения"  : @0
                    }mutableCopy];
}

- (void)updateLabels {
    if (_totalExpeditures == 0) {
        self.firstCategoryNameLabel.text = @"";
        self.firstCategorySummaLabel.text = @"";
        self.secondCategoryNameLabel.text = @"";
        self.secondCategorySummaLabel.text = @"";
        self.thirdCategoryNameLabel.text = @"";
        self.thirdCategorySummaLabel.text = @"";
    }
    self.totalSummaLabel.text = [NSString stringWithFormat:@"%.2f", _totalExpeditures];
    self.monthLabel.text = [self formatDate:[NSDate date]];
}

- (NSString *)formatDate:(NSDate *)theDate {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMMM"];
        [formatter setMonthSymbols:@[@"Январь", @"Февраль", @"Март", @"Апрель", @"Май", @"Июнь", @"Июль", @"Август", @"Сентябрь", @"Октябрь", @"Ноябрь", @"Декабрь"]];
    }
    return [formatter stringFromDate:theDate];
}

- (void)updateLabelsForMostValuebleCategories {
    CGFloat maxValue = 0;
    NSString *maxCategoryName;
    NSMutableSet *set = [NSMutableSet setWithCapacity:2];
    for (int i = 0; i < 3; ++i) {
        maxValue = 0;
        if (i > 0) {
            [set addObject:maxCategoryName];
        }
        for (NSString *key in _categories) {
            CGFloat currentvalue = [_categories[key]floatValue];
            if (currentvalue > maxValue) {
                if (![set member:key]) {
                    maxValue = currentvalue;
                    maxCategoryName = key;
                }
            }
        }
        if (maxValue > 0) {
            switch (i) {
                case 0:
                    self.firstCategoryNameLabel.text = maxCategoryName;
                    self.firstCategorySummaLabel.text = [NSString stringWithFormat:@"%.2f", maxValue];
                    break;
                case 1:
                    self.secondCategoryNameLabel.text = maxCategoryName;
                    self.secondCategorySummaLabel.text = [NSString stringWithFormat:@"%.2f", maxValue];
                    break;
                case 2:
                    self.thirdCategoryNameLabel.text = maxCategoryName;
                    self.thirdCategorySummaLabel.text = [NSString stringWithFormat:@"%.2f", maxValue];
                    break;
            }
        }
    }
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AddExpense"]) {
        UINavigationController *navigationController = segue.destinationViewController;
        AddExpenseViewController *controller = (AddExpenseViewController *)navigationController.topViewController;
        controller.delegate = self;
    }
}

#pragma mark - AddExpenseViewControllerProtocol -

- (void)addExpenseViewController:(AddExpenseViewController *)controller didFinishAddingExpense:(Expense *)expense {
    _totalExpeditures += [expense.sumOfExpense floatValue];

    CGFloat value = [_categories[expense.category]floatValue] + [expense.sumOfExpense floatValue];
    [_categories setValue:@(value) forKey:expense.category];

    [self updateLabels];

    [self updateLabelsForMostValuebleCategories];

    [self dismissViewControllerAnimated:YES completion:nil];
}

@end