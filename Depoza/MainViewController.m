    //View
#import "MainViewController.h"
#import "AddExpenseViewController.h"
#import "MoreInfoTableViewController.h"
#import "CategoriesContainerViewController.h"

    //CoreData
#import "Expense.h"
#import "ExpenseData.h"
#import "CategoryData+Fetch.h"
#import "Fetch.h"

    //Caategories
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

static const CGFloat kMotionEffectMagnitudeValue = 10.0f;

@interface MainViewController () <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalSummaLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation MainViewController {
    CGFloat _totalExpeditures;
    NSMutableArray *_categoriesData;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);
    NSParameterAssert(self.delegate);

    [self loadCategoriesData];
    [self.delegate mainViewController:self didLoadCategoriesData:_categoriesData];

    [self performFetch];
    [self updateLabels];
        //[self addMotionEffectToViews];

    [self customSetUp];
}

- (void)dealloc {
    NSLog(@"Dealloc %@", self);
    _fetchedResultsController.delegate = nil;
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - MotionEffect -

- (void)addMotionEffectToViews {
    for (UIView *aView in self.view.subviews) {
        if ([aView isKindOfClass:[UILabel class]] ||
            [aView isKindOfClass:[UITableView class]]) {
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

        if ([self isDateBetweenCurrentMonth:deletedExpense.dateOfExpense]) {
            _totalExpeditures -= [deletedExpense.amount floatValue];
            [_categoriesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                NSDictionary *dictionary = (NSDictionary *)obj;
                if (dictionary[@"id"] == deletedExpense.categoryId) {
                    [self updateCategoriesExpensesDataAtIndex:idx withValue:-deletedExpense.amount.floatValue];

                    *stop = YES;
                }
            }];
            [self.delegate mainViewController:self didUpdateCategoriesData:_categoriesData];
            [self updateLabels];
            return;
        }
    }
}

#pragma mark - Helper methods -

- (BOOL)isDateBetweenCurrentMonth:(NSDate *)dateToCompare {
    NSArray *dates = [NSDate getFirstAndLastDaysInTheCurrentMonth];
    NSDate *startDate = dates.firstObject;
    NSDate *endDate = dates.lastObject;

    //dateToCompare >= startDate && dateToCompare <= endDate
    BOOL isBetween = ([dateToCompare compare:startDate] == NSOrderedSame ||
                      [dateToCompare compare:startDate] == NSOrderedDescending) &&
    ([dateToCompare compare:endDate]   == NSOrderedSame ||
     [dateToCompare compare:endDate]   == NSOrderedAscending);

    return isBetween;
}

- (void)customSetUp {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(contextDidChange:) name:NSManagedObjectContextObjectsDidChangeNotification object:_managedObjectContext];

    [NSFetchedResultsController deleteCacheWithName:NSStringFromClass([Expense class])];
}

- (void)loadCategoriesData {
    _categoriesData = [Fetch loadCategoriesDataInContext:_managedObjectContext totalExpeditures:& _totalExpeditures];
}

- (void)updateLabels {
    self.totalSummaLabel.text = [NSString stringWithFormat:@"%.2f", _totalExpeditures];
    if (![self.monthLabel.text isEqualToString:[self formatDate:[NSDate date] forLabel:NSStringFromSelector(@selector(monthLabel))]]) {
        self.monthLabel.text = [self formatDate:[NSDate date] forLabel:NSStringFromSelector(@selector(monthLabel))];
    }
}

- (NSString *)formatDate:(NSDate *)theDate forLabel:(NSString *)labelName {
    if ([labelName isEqualToString:NSStringFromSelector(@selector(monthLabel))]) {
        static NSDateFormatter *formatter = nil;
        if (formatter == nil) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMMM"];
            [formatter setMonthSymbols:@[@"Январь", @"Февраль", @"Март", @"Апрель", @"Май", @"Июнь", @"Июль", @"Август", @"Сентябрь", @"Октябрь", @"Ноябрь", @"Декабрь"]];
        }
        return [formatter stringFromDate:theDate];
    } else if ([labelName isEqualToString:@"detailTextLabel"]) {
        static NSDateFormatter *formatter = nil;
        if (formatter == nil) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"HH:mm"];
        }
        return [formatter stringFromDate:theDate];
    }
    return nil;
}

#pragma mark - Segues -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AddExpense"]) {
        UINavigationController *navigationController = segue.destinationViewController;

        AddExpenseViewController *controller = (AddExpenseViewController *)navigationController.topViewController;
        controller.delegate = self;
        controller.managedObjectContext = _managedObjectContext;

        NSMutableArray *categoriesTitles = [NSMutableArray arrayWithCapacity:[_categoriesData count]];
        for (NSDictionary *aDictionary in _categoriesData) {
            [categoriesTitles addObject:aDictionary[NSStringFromSelector(@selector(title))]];
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
    CGFloat value = [_categoriesData[index][@"expenses"]floatValue] + amount;

    [_categoriesData[index]setObject:@(value) forKey:@"expenses"];
}

- (void)addExpenseViewController:(AddExpenseViewController *)controller didFinishAddingExpense:(Expense *)expense {
    _totalExpeditures += [expense.amount floatValue];

    [_categoriesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSParameterAssert([obj isKindOfClass:[NSDictionary class]]);

        if ([obj[NSStringFromSelector(@selector(title))] isEqualToString:expense.category]) {
            [self updateCategoriesExpensesDataAtIndex:idx withValue:expense.amount.floatValue];

            *stop = YES;
        }

    }];
    [self.delegate mainViewController:self didUpdateCategoriesData:_categoriesData];
    [self updateLabels];
}

#pragma mark - EditExpenseTableViewControllerDelegate

- (void)editExpenseTableViewControllerDelegate:(EditExpenseTableViewController *)controller didFinishUpdateExpense:(ExpenseData *)expense {
    NSArray *categories = [CategoryData getCategoriesWithExpensesBetweenMonthOfDate:[NSDate date]managedObjectContext:_managedObjectContext];

    for (NSMutableDictionary *category in _categoriesData) {
        category[@"expenses"] = @0;
    }

    float __block countForExpenditures = 0.0f;

    for (CategoryData *category in categories) {
        [_categoriesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            NSDictionary *dictionary = (NSDictionary *)obj;
            if (category.idValue == dictionary[@"id"]) {
                for (ExpenseData *expense in category.expense) {
                    [_categoriesData[idx] setObject:@([_categoriesData[idx][@"expenses"]floatValue] + [expense.amount floatValue]) forKey:@"expenses"];

                    countForExpenditures += [expense.amount floatValue];
                }
                *stop = YES;
            }
        }];
    }
    _totalExpeditures = countForExpenditures;

    [self.delegate mainViewController:self didUpdateCategoriesData:_categoriesData];
    [self updateLabels];
}

#pragma mark - AddCategoryViewControllerDelegate

- (void)addCategoryViewController:(AddCategoryViewController *)controller didFinishAddingCategory:(CategoryData *)category {
    NSMutableDictionary *newCategory = [@{@"title"    : category.title,
                                          @"id"       : category.idValue,
                                          @"expenses" : @0
                                         }mutableCopy];
    [_categoriesData addObject:newCategory];
    [self.delegate mainViewController:self didUpdateCategoriesData:_categoriesData];
}

#pragma mark - UITableViewDataSource -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (_fetchedResultsController) {
        NSUInteger numberOfSections = [[self.fetchedResultsController sections]count];
        return numberOfSections;
    } else {
        return 0;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (_fetchedResultsController) {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections]objectAtIndex:section];
        return [sectionInfo numberOfObjects];
    } else {
        return 0;
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ExpenseData *expense = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = (expense.descriptionOfExpense.length > 0 ? expense.descriptionOfExpense : @"(No Description)");
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f, %@", [expense.amount floatValue], [self formatDate:expense.dateOfExpense forLabel:@"detailTextLabel"]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];

    return [[sectionInfo name]uppercaseString];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_managedObjectContext deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];

        NSError *error = nil;
        if (![_managedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

#pragma mark - UITableViewDelegate -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    _fetchedResultsController.delegate = self;

    return _fetchedResultsController;
}

- (void)performFetch {
    NSError *error;
    if (![self.fetchedResultsController performFetch:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        exit(-1);  // Fail
    }
}

#pragma mark NSFetchedResultsControllerDelegate

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
        // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {

    UITableView *tableView = self.tableView;

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;

        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            NSParameterAssert(false);
            break;
        case NSFetchedResultsChangeUpdate:
            NSParameterAssert(false);
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

@end