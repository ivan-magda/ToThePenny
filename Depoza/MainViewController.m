#import "MainViewController.h"
#import "SWRevealViewController.h"
#import "AddExpenseViewController.h"
#import "Expense.h"
#import "ExpenseData.h"
#import "SharedManagedObjectContext.h"


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

    NSMutableDictionary *_categories;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    [self customSetUp];
    [self performFetch];
    [self updateLabels];
}

- (void)dealloc {
    _fetchedResultsController.delegate = nil;
}

#pragma mark - Helper methods -

- (void)customSetUp {
    [NSFetchedResultsController deleteCacheWithName:@"Expense"];

    self.managedObjectContext = [[SharedManagedObjectContext sharedInstance]managedObjectContext];
    
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

- (void)updateLabelsForMostValuableCategories {
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
        controller.managedObjectContext = self.managedObjectContext;
    }
}

#pragma mark - AddExpenseViewControllerProtocol -

- (void)addExpenseViewController:(AddExpenseViewController *)controller didFinishAddingExpense:(Expense *)expense {
    _totalExpeditures += [expense.sumOfExpense floatValue];

    [_categories setValue:@([_categories[expense.category]floatValue] + [expense.sumOfExpense floatValue]) forKey:expense.category];

    [self updateLabels];
    [self updateLabelsForMostValuableCategories];

    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDataSource -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.fetchedResultsController sections]count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections]objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ExpenseData *expense = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = expense.descriptionOfExpense;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@", expense.sumOfExpense];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

        // Set up the cell...
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

#pragma mark - NSFetchedResultsController -

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription
                                   entityForName:@"ExpenseData"inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];

    NSSortDescriptor *sort = [[NSSortDescriptor alloc]
                              initWithKey:@"dateOfExpense" ascending:YES];
    [fetchRequest setSortDescriptors:@[sort]];

    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:self.managedObjectContext
                                          sectionNameKeyPath:nil
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
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}


@end