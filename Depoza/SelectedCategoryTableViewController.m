//
//  SelectedCategoryTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 19.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewController
#import "SelectedCategoryTableViewController.h"
#import "DetailExpenseTableViewController.h"
    //CoreDate
#import "CategoryData+Fetch.h"
#import "ExpenseData+Fetch.h"
#import "CategoriesInfo.h"
    //View
#import "CustomRightDetailCell.h"
    //Categories
#import "NSString+FormatAmount.h"
#import "NSString+FormatDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"
#import "NSDate+IsDateBetweenCurrentYear.h"
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"
#import "NSDate+BeginningOfDay.h"
#import "NSDate+EndOfDay.h"

static NSString * const kSelectStartAndEndDatesCellReuseIdentifier = @"SelectStartAndEndDatesCell";
static NSString * const kCustomRightDetailCellReuseIdentifier = @"SelectedCell";

static NSString * const kFetchedResultsControllerCacheName = @"Selected";

static const NSInteger kNumberOfSectionsInTableView = 2;
static const NSInteger kNumberOfRowsInFirstSection = 2;

typedef NS_ENUM(NSUInteger, DateCellType) {
    NoneDateCellType = -1,
    StartDateCellType = 0,
    EndDateCellType = 1,
};

@interface SelectedCategoryTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;

@end

@implementation SelectedCategoryTableViewController {
    BOOL _datePickerVisible;
    NSIndexPath *_selectedIndexPath;

    NSDate *_startDate;
    NSDate *_endDate;

    NSDate *_minimumDate;
    NSDate *_maximumDate;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSParameterAssert(self.timePeriodDates.count == 2);

    self.title = _selectedCategory.title;
    _datePickerVisible = NO;

    [self configureTimePeriod];

    [NSFetchedResultsController deleteCacheWithName:kFetchedResultsControllerCacheName];
    [self performFetch];
}

#pragma mark - Helpers -

- (void)configureTimePeriod {
    NSDate *minDate = [NSDate getBeginningOfDayDateFromDate:[self.timePeriodDates firstObject]];
    NSDate *maxDate = [NSDate getEndOfDayDateFromDate:[self.timePeriodDates lastObject]];
    
    NSDate *oldestDate = [NSDate getBeginningOfDayDateFromDate:[ExpenseData oldestDateExpenseInManagedObjectContext:_managedObjectContext andCategoryId:_selectedCategory.idValue]];
    NSDate *mostRecentDate = [NSDate getEndOfDayDateFromDate:[ExpenseData mostRecentDateExpenseInManagedObjectContext:_managedObjectContext andCategoryId:_selectedCategory.idValue]];
    
    if ([maxDate compare:mostRecentDate] == NSOrderedDescending) {
        _maximumDate = mostRecentDate;
    } else {
        _maximumDate = maxDate;
    }
    
    if ([minDate compare:oldestDate] == NSOrderedDescending) {
        _minimumDate = oldestDate;
    } else {
        _minimumDate = minDate;
    }
    
    _startDate = minDate;
    _endDate   = maxDate;
}

- (BOOL)isNothingFound {
    return _fetchedResultsController.fetchedObjects.count == 0;
}

- (void)updateSegmentedControlState {
    BOOL isNothingFound = [self isNothingFound];
    for (int i = 0; i < self.segmentedControl.numberOfSegments; ++i) {
        [self.segmentedControl setEnabled:!isNothingFound forSegmentAtIndex:i];
    }
    
    NSInteger selectedSegmentIndex = (isNothingFound ? UISegmentedControlNoSegment : 0);
    self.segmentedControl.selectedSegmentIndex = selectedSegmentIndex;
}

- (void)reloadExpensesSection {
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (void)reloadSelectTimePeriodSection {
    [self.tableView beginUpdates];
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

- (NSArray *)sortedArrayBySegmentedControlState {
    NSArray *expenses = _fetchedResultsController.fetchedObjects;

    NSSortDescriptor *sortDescriptor = nil;
    switch (self.segmentedControl.selectedSegmentIndex) {
        case UISegmentedControlNoSegment: case 0: {
            sortDescriptor = [[NSSortDescriptor alloc]initWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO];
            break;
        }
        case 1: {
            sortDescriptor = [[NSSortDescriptor alloc]initWithKey:NSStringFromSelector(@selector(amount)) ascending:NO];
            break;
        }
        default:
            break;
    }
    
    return [expenses sortedArrayUsingDescriptors:@[sortDescriptor]];
}

- (void)updateDateCellDateTextColorWithColor:(UIColor *)color atIndexPath:(NSIndexPath *)indexPath {
    CustomRightDetailCell *cell = (CustomRightDetailCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.rightDetailLabel.textColor = color;
}

- (void)updateDateStringOnDateCellAtIndexPath:(NSIndexPath *)indexPath withDate:(NSDate *)date {
    CustomRightDetailCell *cell = (CustomRightDetailCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    cell.rightDetailLabel.text = [NSString formatDate:date];
}

#pragma mark - UITableViewDataSource -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return kNumberOfSectionsInTableView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return (_datePickerVisible ? (kNumberOfRowsInFirstSection + 1) : kNumberOfRowsInFirstSection);
    } else {
        id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections]objectAtIndex:0];
        return [sectionInfo numberOfObjects];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        if (indexPath.row == StartDateCellType) {
                //Start date cell
            CustomRightDetailCell *cell = (CustomRightDetailCell *)[tableView dequeueReusableCellWithIdentifier:kSelectStartAndEndDatesCellReuseIdentifier];
            cell.leftLabel.text = NSLocalizedString(@"Start date", @"Start date, selected category view controller");
            cell.rightDetailLabel.text = [NSString formatDate:_startDate];

            return cell;
        } else if (indexPath.row == EndDateCellType && !_datePickerVisible) {

            return [self getConfiguratedEndDateCell];

        } else if (indexPath.row == EndDateCellType && _datePickerVisible &&
                   _selectedIndexPath.row == EndDateCellType) {

            return [self getConfiguratedEndDateCell];

        } else if (indexPath.row == 2 && _datePickerVisible && _selectedIndexPath.row == StartDateCellType) {

            return [self getConfiguratedEndDateCell];

        } else {
            UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DatePickerCell"];

            if (cell == nil) {
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DatePickerCell"];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;

                UIDatePicker *datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 216.0f)];
                datePicker.tag = 110;
                datePicker.datePickerMode = UIDatePickerModeDate;
                [cell.contentView addSubview:datePicker];

                [datePicker setMinimumDate:_minimumDate];
                [datePicker setMaximumDate:_maximumDate];

                [datePicker addTarget:self action:@selector(dateChanged:) forControlEvents:UIControlEventValueChanged];
            }
            UIDatePicker *datePicker = (UIDatePicker *)[cell viewWithTag:110];
            NSDate *dateToSet = (_selectedIndexPath.row == StartDateCellType ? _startDate : _endDate);
            [datePicker setDate:dateToSet animated:NO];

            return cell;
        }
    } else {
            //Expense cell
        CustomRightDetailCell *cell = (CustomRightDetailCell *)[tableView dequeueReusableCellWithIdentifier:kCustomRightDetailCellReuseIdentifier];

            //Expenses shows at 2 section, because need to change section at index path
        NSIndexPath *correctIndexPath = [self correctIndexPathForFetchedResultsControllerFromIndexPath:indexPath];
        [self configureExpenseCell:cell atIndexPath:correctIndexPath];
        
        return cell;
    }
}

- (void)configureExpenseCell:(CustomRightDetailCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *correctIndexPath = [self correctIndexPathForFetchedResultsControllerFromIndexPath:indexPath];
    ExpenseData *expense = [self sortedArrayBySegmentedControlState][correctIndexPath.row];

    if (expense.descriptionOfExpense.length == 0) {
        cell.leftLabel.text = NSLocalizedString(@"(No Description)", @"SelectedCategoryVC when expenseDescription.length == 0 show (No description)");
    } else {
        cell.leftLabel.text = expense.descriptionOfExpense;
    }

    cell.rightDetailLabel.text = [NSString stringWithFormat:@"%@, %@", [NSString formatAmount:expense.amount],[NSString formatDate:expense.dateOfExpense]];
}

- (CustomRightDetailCell *)getConfiguratedEndDateCell {
    CustomRightDetailCell *cell = (CustomRightDetailCell *)[self.tableView dequeueReusableCellWithIdentifier:kSelectStartAndEndDatesCellReuseIdentifier];
    cell.leftLabel.text = NSLocalizedString(@"End date", @"End date, selected category view controller");
    cell.rightDetailLabel.text = [NSString formatDate:_endDate];

    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    NSIndexPath *correctIndexPath = [self correctIndexPathForFetchedResultsControllerFromIndexPath:indexPath];
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        ExpenseData *expense = [self sortedArrayBySegmentedControlState][correctIndexPath.row];
        
        [self.fetchedResultsController.managedObjectContext deleteObject:expense];

        NSError *error = nil;
        if (![self.fetchedResultsController.managedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Period of the transactions.", @"SelectedCategoryVC title for header in section");
    } else {
        if (_fetchedResultsController.fetchedObjects.count > 0) {
            return NSLocalizedString(@"Founded transactions.", @"SelectedCategoryVC title for header in section");
        } else {
            return NSLocalizedString(@"Nothing found.", @"'Nothing found' title for header in section");
        }
    }
}

#pragma mark - UITableViewDelegate -

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _datePickerVisible) {
        if (indexPath.row == EndDateCellType && _selectedIndexPath.row == StartDateCellType) {
            return nil;
        } else if (indexPath.row == 2 && _selectedIndexPath.row == EndDateCellType) {
            return nil;
        }
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    _selectedIndexPath = indexPath;

    if (indexPath.section == 0) {
        if (!_datePickerVisible) {
            [self showDatePicker];
        } else {
            [self hideDatePicker];
        }
        return;
    }
        // Also hide the date picker when tapped on any other row.
    [self hideDatePicker];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_datePickerVisible && indexPath.section == 0) {
        if (indexPath.row == EndDateCellType && _selectedIndexPath.row == StartDateCellType) {
            return 217.0f;
        } else if (indexPath.row == 2 && _selectedIndexPath.row == EndDateCellType) {
            return 217.0f;
        }
    }
    return 44.0f;
}

#pragma mark - DatePicker -

- (void)showDatePicker {
    _datePickerVisible = YES;

    [self reloadSelectTimePeriodSection];

    [self updateDateCellDateTextColorWithColor:[self.view tintColor] atIndexPath:_selectedIndexPath];
}

- (void)hideDatePicker {
    if (_datePickerVisible) {
        _datePickerVisible = NO;

        [self updateDateCellDateTextColorWithColor:[UIColor lightGrayColor] atIndexPath:_selectedIndexPath];

        _selectedIndexPath = nil;

        [self reloadSelectTimePeriodSection];

        [NSFetchedResultsController deleteCacheWithName:kFetchedResultsControllerCacheName];
        self.fetchedResultsController.fetchRequest.predicate = [self compoundPredicateForFetchedResultsController];
        [self performFetch];
        
        [self updateSegmentedControlState];

        [self reloadExpensesSection];
    }
}

- (void)dateChanged:(UIDatePicker *)datePicker {
    switch (_selectedIndexPath.row) {
        case StartDateCellType: {
            _startDate = [NSDate getBeginningOfDayDateFromDate:datePicker.date];

            [self updateDateStringOnDateCellAtIndexPath:_selectedIndexPath withDate:_startDate];

            break;
        }
        case EndDateCellType: {
            _endDate = [NSDate getEndOfDayDateFromDate:datePicker.date];

            [self updateDateStringOnDateCellAtIndexPath:_selectedIndexPath withDate:_endDate];

            break;
        }
        default:
            break;
    }
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MoreInfo"]) {
        DetailExpenseTableViewController *controller = segue.destinationViewController;
        controller.managedObjectContext = _managedObjectContext;
        
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

            ExpenseData *expense = [self sortedArrayBySegmentedControlState][indexPath.row];
            controller.expenseToShow = expense;
        }
    }
}

#pragma mark - IBAction -

- (IBAction)segmentedControlDidChangeValue:(UISegmentedControl *)sender {
    [self reloadExpensesSection];
}


#pragma mark - NSFetchedResultsController -

- (NSIndexPath *)correctIndexPathForFetchedResultsControllerFromIndexPath:(NSIndexPath *)indexPath {
    return (indexPath == nil ? nil : [NSIndexPath indexPathForRow:indexPath.row inSection:0]);
}

- (NSIndexPath *)correctIndexPathForTableViewUpdatesFromIndexPath:(NSIndexPath *)indexPath {
    return (indexPath == nil ? nil : [NSIndexPath indexPathForRow:indexPath.row inSection:1]);
}

- (NSPredicate *)compoundPredicateForFetchedResultsController {
    NSNumber *idValue = self.selectedCategory.idValue;
    NSArray *dates = @[_startDate, _endDate];

    NSExpression *idKeyPath = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(categoryId))];
    NSExpression *idToFind  = [NSExpression expressionForConstantValue:idValue];
    NSPredicate *idPredicate  = [NSComparisonPredicate predicateWithLeftExpression:idKeyPath
                                                                   rightExpression:idToFind
                                                                          modifier:NSDirectPredicateModifier
                                                                              type:NSEqualToPredicateOperatorType
                                                                           options:0];

    NSExpression *dateExp    = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(dateOfExpense))];
    NSExpression *dateStart  = [NSExpression expressionForConstantValue:[dates firstObject]];
    NSExpression *dateEnd    = [NSExpression expressionForConstantValue:[dates lastObject]];
    NSExpression *expression = [NSExpression expressionForAggregate:@[dateStart, dateEnd]];

    NSPredicate *datePredicate = [NSComparisonPredicate predicateWithLeftExpression:dateExp
                                                                    rightExpression:expression
                                                                           modifier:NSDirectPredicateModifier
                                                                               type:NSBetweenPredicateOperatorType
                                                                            options:0];

    return [NSCompoundPredicate andPredicateWithSubpredicates:@[idPredicate, datePredicate]];
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];
    fetchRequest.predicate = [self compoundPredicateForFetchedResultsController];

        // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];

        // Edit the sort key as appropriate.
    NSSortDescriptor *dateSort = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO];

    [fetchRequest setSortDescriptors:@[dateSort]];

        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc]
                                                             initWithFetchRequest:fetchRequest
                                                             managedObjectContext:self.managedObjectContext
                                                             sectionNameKeyPath:nil
                                                             cacheName:kFetchedResultsControllerCacheName];
    aFetchedResultsController.delegate = self;
    _fetchedResultsController = aFetchedResultsController;

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
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    NSUInteger correctSectionIndex = 1;
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:correctSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:correctSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
        case NSFetchedResultsChangeMove:
            break;
        case NSFetchedResultsChangeUpdate:
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    [self.tableView endUpdates];
}

@end
