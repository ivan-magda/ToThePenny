    //View
#import "MainViewController.h"
#import "AddExpenseViewController.h"
#import "MoreInfoTableViewController.h"
#import "CategoriesContainerViewController.h"
#import "MainTableViewProtocolsImplementer.h"

    //CoreData
#import "Expense.h"
#import "ExpenseData.h"
#import "CategoryData+Fetch.h"
#import "Fetch.h"
    //Data
#import "CategoriesInfo.h"

    //Caategories
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"
#import "NSDate+IsDateBetweenCurrentMonth.h"

static const CGFloat kMotionEffectMagnitudeValue = 10.0f;

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalAmountLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) MainTableViewProtocolsImplementer *tableViewProtocolsImplementer;

@end

@implementation MainViewController {
    CGFloat _totalExpeditures;
    NSMutableArray *_categoriesInfo;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);
    NSParameterAssert(self.delegate);

    self.tableViewProtocolsImplementer = [[MainTableViewProtocolsImplementer alloc]initWithTableView:self.tableView fetchedResultsController:self.fetchedResultsController];
    self.fetchedResultsController.delegate = self.tableViewProtocolsImplementer;

    self.tableView.dataSource = self.tableViewProtocolsImplementer;
    self.tableView.delegate = self.tableViewProtocolsImplementer;

    [self loadCategoriesData];

    for (CategoriesInfo *anInfo in _categoriesInfo) {
        NSParameterAssert(anInfo.title && anInfo.idValue && anInfo.amount);
    }

    [self.delegate mainViewController:self didLoadCategoriesInfo:_categoriesInfo];

    [self customSetUp];
    [self performFetch];
    [self updateLabels];
    [self addMotionEffectToViews];
}

- (void)dealloc {
    NSLog(@"Dealloc %@", self);
    _fetchedResultsController.delegate = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Helper methods -

- (void)customSetUp {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:self.managedObjectContext];

    [NSFetchedResultsController deleteCacheWithName:NSStringFromClass([Expense class])];
}

- (void)loadCategoriesData {
    _categoriesInfo = [Fetch loadCategoriesInfoInContext:self.managedObjectContext totalExpeditures:& _totalExpeditures];
}

- (void)updateLabels {
    self.totalAmountLabel.text = [NSString stringWithFormat:@"%.2f", _totalExpeditures];

    NSString *monthString = [self formatDateForMonthLabel:[NSDate date]];
    if (![self.monthLabel.text isEqualToString:monthString]) {
        self.monthLabel.text = monthString;
    }
}

- (NSString *)formatDateForMonthLabel:(NSDate *)theDate {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"MMMM"];
        [formatter setMonthSymbols:@[@"Январь", @"Февраль", @"Март", @"Апрель", @"Май", @"Июнь", @"Июль", @"Август", @"Сентябрь", @"Октябрь", @"Ноябрь", @"Декабрь"]];
    }
    return [formatter stringFromDate:theDate];
}

#pragma mark - MotionEffect -

- (void)addMotionEffectToViews {
    for (UIView *aView in self.view.subviews) {
        if ([aView isKindOfClass:[UITableView class]]) {
            [self makeLargerFrameForView:aView withValue:kMotionEffectMagnitudeValue];
            [self addMotionEffectToView:aView magnitude:kMotionEffectMagnitudeValue];
        }
    }
}

- (void)makeLargerFrameForView:(UIView *)view withValue:(CGFloat)value {
    view.frame = CGRectInset(view.frame, -value, -value);
}

- (void)addMotionEffectToView:(UIView *)view magnitude:(CGFloat)magnitude {
    UIInterpolatingMotionEffect *xMotion = [[UIInterpolatingMotionEffect alloc]
                                            initWithKeyPath:@"center.x"
                                            type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xMotion.minimumRelativeValue = @(-magnitude);
    xMotion.maximumRelativeValue = @(magnitude);

    UIInterpolatingMotionEffect *yMotion = [[UIInterpolatingMotionEffect alloc]
                                            initWithKeyPath:@"center.y"
                                            type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yMotion.minimumRelativeValue = @(-magnitude);
    yMotion.maximumRelativeValue = @(magnitude);

    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[xMotion, yMotion];
    [view addMotionEffect:group];
}

#pragma mark - Notifications -

- (void)contextDidChange:(NSNotification *)notification {
    NSSet *setWithKeys = [NSSet setWithArray:[notification.userInfo allKeys]];

    if ([setWithKeys member:@"deleted"]) {
        NSParameterAssert([[notification.userInfo[@"deleted"]allObjects]count] == 1);
        ExpenseData *deletedExpense = [notification.userInfo[@"deleted"]anyObject];

        if ([NSDate isDateBetweenCurrentMonth:deletedExpense.dateOfExpense]) {
            _totalExpeditures -= [deletedExpense.amount floatValue];
            [_categoriesInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CategoriesInfo *info = obj;
                if (info.idValue == deletedExpense.categoryId) {
                    [self updateCategoriesExpensesDataAtIndex:idx withValue:-deletedExpense.amount.floatValue];

                    *stop = YES;
                }
            }];
            [self.delegate mainViewController:self didUpdateCategoriesInfo:_categoriesInfo];
            [self updateLabels];
            return;
        }
    }
}

#pragma mark - Segues -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AddExpense"]) {
        UINavigationController *navigationController = segue.destinationViewController;

        AddExpenseViewController *controller = (AddExpenseViewController *)navigationController.topViewController;
        controller.delegate = self;
        controller.managedObjectContext = _managedObjectContext;

        NSMutableArray *categoriesTitles = [NSMutableArray arrayWithCapacity:[_categoriesInfo count]];
        for (CategoriesInfo *anInfo in _categoriesInfo) {
            [categoriesTitles addObject:anInfo.title];
        }
        controller.categories = categoriesTitles;

    } else if ([segue.identifier isEqualToString:@"MoreInfo"]) {
        MoreInfoTableViewController *controller = (MoreInfoTableViewController *)segue.destinationViewController;

        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

            ExpenseData *expense = [_fetchedResultsController objectAtIndexPath:indexPath];
            controller.expenseToShow = expense;
            controller.managedObjectContext = _managedObjectContext;
        }
    } else if ([segue.identifier isEqualToString:@"CategoriesInfo"]) {
        CategoriesContainerViewController *controller = segue.destinationViewController;
        self.delegate = controller;
    }
}

#pragma mark - AddExpenseViewControllerDelegate

- (void)updateCategoriesExpensesDataAtIndex:(NSInteger)index withValue:(CGFloat)amount {
    CategoriesInfo *info = _categoriesInfo[index];
    CGFloat value = [[info amount] floatValue] + amount;

    info.amount = @(value);
}

- (void)addExpenseViewController:(AddExpenseViewController *)controller didFinishAddingExpense:(Expense *)expense {
    _totalExpeditures += [expense.amount floatValue];

    [_categoriesInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSParameterAssert([obj isKindOfClass:[CategoriesInfo class]]);
        CategoriesInfo *anInfo = obj;

        if ([anInfo.title isEqualToString:expense.category]) {
            [self updateCategoriesExpensesDataAtIndex:idx withValue:expense.amount.floatValue];

            *stop = YES;
        }

    }];
    [self.delegate mainViewController:self didUpdateCategoriesInfo:_categoriesInfo];
    [self updateLabels];
}

#pragma mark - EditExpenseTableViewControllerDelegate

- (void)editExpenseTableViewControllerDelegate:(EditExpenseTableViewController *)controller didFinishUpdateExpense:(ExpenseData *)expense {
    NSArray *categories = [CategoryData getCategoriesWithExpensesBetweenMonthOfDate:[NSDate date]managedObjectContext:_managedObjectContext];

    for (CategoriesInfo *anInfo in _categoriesInfo) {
        anInfo.amount = @0;
    }

    float __block countForExpenditures = 0.0f;

    for (CategoryData *category in categories) {
        [_categoriesInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            CategoriesInfo *anInfo = obj;
            if (category.idValue == anInfo.idValue) {
                for (ExpenseData *expense in category.expense) {
                    CategoriesInfo *infoForUpdate = _categoriesInfo[idx];
                    infoForUpdate.amount = @([infoForUpdate.amount floatValue] + [expense.amount floatValue]);
                    countForExpenditures += [expense.amount floatValue];
                }
                *stop = YES;
            }
        }];
    }
    _totalExpeditures = countForExpenditures;

    [self.delegate mainViewController:self didUpdateCategoriesInfo:_categoriesInfo];
    [self updateLabels];
}

#pragma mark - AddCategoryViewControllerDelegate

- (void)addCategoryViewController:(AddCategoryViewController *)controller didFinishAddingCategory:(CategoryData *)category {
    CategoriesInfo *info = [[CategoriesInfo alloc]initWithTitle:category.title adValue:category.idValue amount:@0];
    [_categoriesInfo addObject:info];
    [self.delegate mainViewController:self didUpdateCategoriesInfo:_categoriesInfo];
}

#pragma mark - NSFetchedResultsController -

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

        //Create compound predicate: dateOfExpense >= dates[0] AND dateOfExpense <= dates[1]
    NSArray *dates = [NSDate getStartAndEndDatesOfTheCurrentDate];

    NSExpression *dateOfExpense = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(dateOfExpense))];
    NSExpression *startDate = [NSExpression expressionForConstantValue:[dates firstObject]];
    NSPredicate *predicateStartDate = [NSComparisonPredicate predicateWithLeftExpression:dateOfExpense
                                                                         rightExpression:startDate
                                                                                modifier:NSDirectPredicateModifier
                                                                                    type:NSGreaterThanOrEqualToPredicateOperatorType
                                                                                 options:0];

    NSExpression *endDate = [NSExpression expressionForConstantValue:[dates lastObject]];
    NSPredicate *predicateEndDate = [NSComparisonPredicate predicateWithLeftExpression:dateOfExpense
                                                                       rightExpression:endDate
                                                                              modifier:NSDirectPredicateModifier
                                                                                  type:NSLessThanOrEqualToPredicateOperatorType
                                                                               options:0];
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[predicateStartDate, predicateEndDate]];
    fetchRequest.predicate = predicate;

    NSSortDescriptor *categorySortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"category.title" ascending:YES];
    NSSortDescriptor *dateSortDescriptor = [[NSSortDescriptor alloc]
                              initWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO];
    [fetchRequest setSortDescriptors:@[categorySortDescriptor, dateSortDescriptor]];

    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:_managedObjectContext
                                          sectionNameKeyPath:@"category.title"
                                                   cacheName:NSStringFromClass([Expense class])];
    self.fetchedResultsController = theFetchedResultsController;

    return _fetchedResultsController;
}

- (void)performFetch {
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
}

@end