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
#import "CustomRightDetailLabel.h"
    //Categories
#import "NSString+FormatAmount.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

@interface SelectedCategoryTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation SelectedCategoryTableViewController


- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = _selectedCategory.title;

    [NSFetchedResultsController deleteCacheWithName:@"Selected"];

    [self performFetch];
}

- (NSString *)formatDate:(NSDate *)theDate {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"dd.MM"];
    }
    return [formatter stringFromDate:theDate];
}

#pragma mark - UITableViewDataSource -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger numberOfSections = [[self.fetchedResultsController sections]count];
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [[self.fetchedResultsController sections]objectAtIndex:section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(CustomRightDetailLabel *)cell atIndexPath:(NSIndexPath *)indexPath {
    ExpenseData *expense = [self.fetchedResultsController objectAtIndexPath:indexPath];
    if (expense.descriptionOfExpense.length == 0) {
        cell.leftLabel.text = NSLocalizedString(@"(No Description)", @"SelectedCategoryVC when expenseDescription.length == 0 show (No description)");
    } else {
        cell.leftLabel.text = expense.descriptionOfExpense;
    }

    cell.rightDetailLabel.text = [NSString stringWithFormat:@"%@, %@", [NSString formatAmount:expense.amount],[self formatDate:expense.dateOfExpense]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomRightDetailLabel *cell = (CustomRightDetailLabel *)[tableView dequeueReusableCellWithIdentifier:@"SelectedCell"];
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.fetchedResultsController.managedObjectContext deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];

        NSError *error = nil;
        if (![self.fetchedResultsController.managedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
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

            ExpenseData *expense = [_fetchedResultsController objectAtIndexPath:indexPath];
            controller.expenseToShow = expense;
        }
    }
}

#pragma mark - NSFetchedResultsController -

- (NSFetchedResultsController *)fetchedResultsController {
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

    NSNumber *idValue = self.selectedCategory.idValue;
    NSArray *dates = [_timePeriod getFirstAndLastDaysInTheCurrentMonth];

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

    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[idPredicate, datePredicate]];

    fetchRequest.predicate = predicate;

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
                                                             cacheName:@"Selected"];
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

    UITableView *tableView = self.tableView;

    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;

        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
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
