    //View
#import "MainViewController.h"
#import "SWRevealViewController.h"
#import "AddExpenseViewController.h"
#import "DetailsViewController.h"

    //CoreData
#import "Expense.h"
#import "ExpenseData.h"
#import "CategoryData.h"
#import "SharedManagedObjectContext.h"

    //Categories
#import "NSDate+FirstAndLastDaysOfMonth.h"


@interface MainViewController () <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *revealBarButton;

@property (weak, nonatomic) IBOutlet UILabel *monthLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalSummaLabel;

@property (weak, nonatomic) IBOutlet UILabel *firstCategoryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondCategoryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdCategoryNameLabel;

@property (weak, nonatomic) IBOutlet UILabel *firstCategorySummaLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondCategorySummaLabel;
@property (weak, nonatomic) IBOutlet UILabel *thirdCategorySummaLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation MainViewController {
    CGFloat _totalExpeditures;
    NSMutableArray *_categoriesData;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    [self customSetUp];
    [self loadCategoriesData];
    [self performFetch];
    [self updateLabels];
}

- (void)dealloc {
    NSLog(@"Dealloc %@", self);
    _fetchedResultsController.delegate = nil;
}

- (void)loadCategoriesData {
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([CategoryData class]) inManagedObjectContext:_managedObjectContext];
    [request setEntity:entity];

    NSSortDescriptor *sort = [[NSSortDescriptor alloc]initWithKey:NSStringFromSelector(@selector(title)) ascending:NO];
    [request setSortDescriptors:@[sort]];

    NSError *error;
    NSArray *fetchedCategories = [_managedObjectContext executeFetchRequest:request error:&error];

    _categoriesData = [NSMutableArray arrayWithCapacity:[fetchedCategories count]];

    NSParameterAssert(fetchedCategories != nil);
    if (fetchedCategories == nil || [fetchedCategories count] == 0) {
        NSLog(@"Couldn't load categories data %@", [error localizedDescription]);
    } else {
        for (CategoryData *aData in fetchedCategories) {
            NSMutableDictionary *category = [@{@"title"    : aData.title,
                                               @"id"       : aData.idValue,
                                               @"expenses" : @0
                                               }mutableCopy];
            [_categoriesData addObject:category];
        }
    }

    request = [[NSFetchRequest alloc]init];
    entity = [NSEntityDescription entityForName:NSStringFromClass([ExpenseData class]) inManagedObjectContext:_managedObjectContext];
    [request setEntity:entity];

    NSArray *days = [NSDate getFirstAndLastDaysInTheCurrentMonth];

    _totalExpeditures = 0.0f;

    for (int i = 0; i < [_categoriesData count]; ++i) {
        NSNumber *idValue = [_categoriesData[i]objectForKey:@"id"];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"((dateOfExpense >= %@) and (dateOfExpense <= %@)) and categoryId = %@", [days firstObject], [days lastObject], idValue];
        [request setPredicate:predicate];

        NSArray *fetchedExpenses = [_managedObjectContext executeFetchRequest:request error:&error];
        NSParameterAssert(error == nil);

        if (fetchedExpenses && [fetchedExpenses count] > 0) {
            for (ExpenseData *aData in fetchedExpenses) {
                NSParameterAssert(aData.categoryId == _categoriesData[i][@"id"]);

                [_categoriesData[i] setObject:@([_categoriesData[i][@"expenses"]floatValue] + [aData.amount floatValue]) forKey:@"expenses"];

                _totalExpeditures += [aData.amount floatValue];
            }
        }
    }
}

#pragma mark - Helper methods -

- (void)customSetUp {
    self.revealBarButton.target = self.revealViewController;
    self.revealBarButton.action = @selector(revealToggle:);

    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];

    self.managedObjectContext = [[SharedManagedObjectContext sharedInstance]managedObjectContext];

    [NSFetchedResultsController deleteCacheWithName:@"Expense"];
}

- (void)updateLabels {
    self.firstCategoryNameLabel.text = @"";
    self.firstCategorySummaLabel.text = @"";
    self.secondCategoryNameLabel.text = @"";
    self.secondCategorySummaLabel.text = @"";
    self.thirdCategoryNameLabel.text = @"";
    self.thirdCategorySummaLabel.text = @"";

    [self updateLabelsForMostValuableCategories];

    self.totalSummaLabel.text = [NSString stringWithFormat:@"%.2f", _totalExpeditures];
    self.monthLabel.text = [self formatDate:[NSDate date] forLabel:@"monthLabel"];
}

- (NSString *)formatDate:(NSDate *)theDate forLabel:(NSString *)text {
    if ([text isEqualToString:@"monthLabel"]) {
        static NSDateFormatter *formatter = nil;
        if (formatter == nil) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"MMMM"];
            [formatter setMonthSymbols:@[@"Январь", @"Февраль", @"Март", @"Апрель", @"Май", @"Июнь", @"Июль", @"Август", @"Сентябрь", @"Октябрь", @"Ноябрь", @"Декабрь"]];
        }
        return [formatter stringFromDate:theDate];
    } else if ([text isEqualToString:@"detailTextLabel"]) {
        static NSDateFormatter *formatter = nil;
        if (formatter == nil) {
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"HH:mm"];
        }
        return [formatter stringFromDate:theDate];

    }
    return nil;
}

- (void)updateLabelsForMostValuableCategories {
    CGFloat maxValue = 0;
    NSString *maxCategoryTitle;
    NSMutableSet *set = [NSMutableSet setWithCapacity:2];

    for (int i = 0; i < 3; ++i) {
        maxValue = 0;

        if (i > 0) {
            NSParameterAssert(maxCategoryTitle != nil);
            [set addObject:maxCategoryTitle];
        }

        for (NSDictionary *aDictionary in _categoriesData) {
            CGFloat currentvalue = [aDictionary[@"expenses"]floatValue];
            NSString *title = aDictionary[NSStringFromSelector(@selector(title))];

            if (currentvalue > maxValue) {
                if (![set member:title]) {
                    maxValue = currentvalue;
                    maxCategoryTitle = title;
                }
            }
        }

        if (maxValue > 0 && maxCategoryTitle.length > 0) {
            switch (i) {
                case 0:
                    self.firstCategoryNameLabel.text = maxCategoryTitle;
                    self.firstCategorySummaLabel.text = [NSString stringWithFormat:@"%.2f", maxValue];
                    break;
                case 1:
                    self.secondCategoryNameLabel.text = maxCategoryTitle;
                    self.secondCategorySummaLabel.text = [NSString stringWithFormat:@"%.2f", maxValue];
                    break;
                case 2:
                    self.thirdCategoryNameLabel.text = maxCategoryTitle;
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
        controller.managedObjectContext = _managedObjectContext;

        NSMutableArray *categoriesTitles = [NSMutableArray arrayWithCapacity:[_categoriesData count]];
        for (NSDictionary *aDictionary in _categoriesData) {
            [categoriesTitles addObject:aDictionary[NSStringFromSelector(@selector(title))]];
        }
        controller.categories = categoriesTitles;

    } else if ([segue.identifier isEqualToString:@"ShowDetails"]) {
        DetailsViewController *controller = (DetailsViewController *)segue.destinationViewController;

        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

            ExpenseData *expense = [_fetchedResultsController objectAtIndexPath:indexPath];
            controller.expenseToShow = expense;
        }
    }
}

#pragma mark - AddExpenseViewControllerProtocol -

- (void)addExpenseViewController:(AddExpenseViewController *)controller didFinishAddingExpense:(Expense *)expense {
    if (self.tableView.hidden) {
        self.tableView.hidden = NO;
    }
    _totalExpeditures += [expense.amount floatValue];

    [_categoriesData enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSParameterAssert([obj isKindOfClass:[NSDictionary class]]);

        if ([obj[NSStringFromSelector(@selector(title))] isEqualToString:expense.category]) {
            CGFloat value = [_categoriesData[idx][@"expenses"]floatValue] + [expense.amount floatValue];
            [_categoriesData[idx]setObject:@(value) forKey:@"expenses"];

            *stop = YES;
        }

    }];

    [self updateLabels];

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
   NSUInteger numberOfSections = [[self.fetchedResultsController sections]count];
    if (numberOfSections == 0) {
        _tableView.hidden = YES;

        return numberOfSections;
    }
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections]objectAtIndex:section];
    return [sectionInfo numberOfObjects];
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

#pragma mark - UITableViewDelegate -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - NSFetchedResultsController -

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:NSStringFromClass([ExpenseData class])
                                   inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];

    NSSortDescriptor *categorySortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"category.title" ascending:NO];
    NSSortDescriptor *dateSortDescriptor = [[NSSortDescriptor alloc]
                              initWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:YES];
    [fetchRequest setSortDescriptors:@[categorySortDescriptor, dateSortDescriptor]];

    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:_managedObjectContext
                                          sectionNameKeyPath:@"category.title"
                                                   cacheName:@"Expense"];
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