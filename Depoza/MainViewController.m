    //ViewControllers
#import "MainViewController.h"
#import "AddExpenseViewController.h"
#import "MoreInfoTableViewController.h"
#import "CategoriesContainerViewController.h"
#import "MainTableViewProtocolsImplementer.h"

    //CoreData
#import "Expense.h"
#import "ExpenseData+Fetch.h"
#import "CategoryData+Fetch.h"
#import "Fetch.h"
    //Data
#import "CategoriesInfo.h"

    //Caategories
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.m"
#import "NSString+FormatAmount.h"

static const CGFloat kMotionEffectMagnitudeValue = 10.0f;

@interface MainViewController () <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalAmountLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSFetchedResultsController *todayFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *monthFetchedResultsController;
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

    self.monthLabel.text = @"";
    self.totalAmountLabel.text = @"";

    self.tableViewProtocolsImplementer = [[MainTableViewProtocolsImplementer alloc]initWithTableView:self.tableView fetchedResultsController:self.todayFetchedResultsController];

    self.todayFetchedResultsController.delegate = _tableViewProtocolsImplementer;
    self.monthFetchedResultsController.delegate = self;

    self.tableView.dataSource = _tableViewProtocolsImplementer;
    self.tableView.delegate   = _tableViewProtocolsImplementer;

    [NSFetchedResultsController deleteCacheWithName:@"todayFetchedResultsController"];
    [NSFetchedResultsController deleteCacheWithName:@"monthFetchedResultsController"];
}

- (void)dealloc {
    _todayFetchedResultsController.delegate = nil;
    _monthFetchedResultsController.delegate = nil;
}

#pragma mark - Helper methods -

- (void)updateUserInterfaceWithNewFetch:(BOOL)fetch {
    [self loadCategoriesData];
    [self.delegate mainViewController:self didLoadCategoriesInfo:_categoriesInfo];

    if (fetch) {
        [self performFetches];
    }
    [self updateLabels];
    [self.tableView reloadData];
}

- (void)performFetches {
    [self todayPerformFetch];
    [self monthPerformFetch];
}

- (void)loadCategoriesData {
    _categoriesInfo = [Fetch loadCategoriesInfoInContext:self.managedObjectContext totalExpeditures:& _totalExpeditures];
}

- (void)updateLabels {
    self.totalAmountLabel.text = [NSString formatAmount:@(_totalExpeditures)];

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
        if ([[[NSLocale currentLocale]objectForKey:NSLocaleCountryCode]isEqualToString:@"RU"]) {
            [formatter setMonthSymbols:@[@"Январь", @"Февраль", @"Март", @"Апрель", @"Май", @"Июнь", @"Июль", @"Август", @"Сентябрь", @"Октябрь", @"Ноябрь", @"Декабрь"]];
        }
    }
    return [formatter stringFromDate:theDate];
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
        controller.managedObjectContext = _managedObjectContext;

        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

            ExpenseData *expense = [_todayFetchedResultsController objectAtIndexPath:indexPath];
            controller.expenseToShow = expense;
        } else if ([sender isKindOfClass:[ExpenseData class]]) {
            ExpenseData *expense = sender;
            controller.expenseToShow = expense;
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
                for (ExpenseData *anExpense in category.expense) {
                    CategoriesInfo *infoForUpdate = _categoriesInfo[idx];
                    infoForUpdate.amount = @([infoForUpdate.amount floatValue] + [anExpense.amount floatValue]);
                    countForExpenditures += [anExpense.amount floatValue];
                }
                *stop = YES;
            }
        }];
    }
    _totalExpeditures = countForExpenditures;

    [self.delegate mainViewController:self didUpdateCategoriesInfo:_categoriesInfo];
    [self updateLabels];

    [self.tableViewProtocolsImplementer.tableView reloadData];
}

#pragma mark - AddCategoryViewControllerDelegate

- (void)addCategoryViewController:(AddCategoryViewController *)controller didFinishAddingCategory:(CategoryData *)category {
    CategoriesInfo *info = [[CategoriesInfo alloc]initWithTitle:category.title iconName:category.iconName idValue:category.idValue andAmount:@0];
    [_categoriesInfo addObject:info];
    [self.delegate mainViewController:self didUpdateCategoriesInfo:_categoriesInfo];
}

#pragma mark - NSFetchedResultsController
#pragma mark Today

- (NSFetchedResultsController *)todayFetchedResultsController {
    if (_todayFetchedResultsController) {
        return _todayFetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

        //Create compound predicate: dateOfExpense >= dates[0] AND dateOfExpense <= dates[1]
    NSArray *dates = [NSDate getStartAndEndDatesOfTheCurrentDate];
    NSPredicate *predicate = [ExpenseData compoundPredicateBetweenDates:dates];
    fetchRequest.predicate = predicate;

    NSSortDescriptor *dateSortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO];
    [fetchRequest setSortDescriptors:@[dateSortDescriptor]];
    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:_managedObjectContext
                                          sectionNameKeyPath:nil
                                                   cacheName:@"todayFetchedResultsController"];
    _todayFetchedResultsController = theFetchedResultsController;

    return _todayFetchedResultsController;
}

- (void)todayPerformFetch {
    NSError *todayError;
    if (![self.todayFetchedResultsController performFetch:&todayError]) {
        NSLog(@"Unresolved error %@, %@", todayError, [todayError userInfo]);
        exit(-1);  // Fail
    }
}

#pragma mark Month

- (NSFetchedResultsController *)monthFetchedResultsController {
    if (_monthFetchedResultsController) {
        return _monthFetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

        //Create compound predicate: dateOfExpense >= dates[0] AND dateOfExpense <= dates[1]
    NSArray *dates = [NSDate getFirstAndLastDaysInTheCurrentMonth];
    NSPredicate *predicate = [ExpenseData compoundPredicateBetweenDates:dates];
    fetchRequest.predicate = predicate;

    NSSortDescriptor *dateSortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO];
    [fetchRequest setSortDescriptors:@[dateSortDescriptor]];
    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *theFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil
                                                   cacheName:@"monthFetchedResultsController"];
    _monthFetchedResultsController = theFetchedResultsController;

    return _monthFetchedResultsController;
}

- (void)monthPerformFetch {
    NSError *monthError;
    if (![self.monthFetchedResultsController performFetch:&monthError]) {
        NSLog(@"Unresolved error %@, %@", monthError, [monthError userInfo]);
        exit(-1);  // Fail
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
        case NSFetchedResultsChangeUpdate:
        case NSFetchedResultsChangeMove:
            break;

        case NSFetchedResultsChangeDelete: {
            ExpenseData *deletedExpense = (ExpenseData *)anObject;
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

@end