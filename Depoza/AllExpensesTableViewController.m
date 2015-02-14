//
//  AllExpensesTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 08.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //View
#import "AllExpensesTableViewController.h"
#import "MoreInfoViewController.h"

    //CoreData
#import "ExpenseData.h"
#import "CategoryData.h"

@interface AllExpensesTableViewController () <NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSPredicate *searchPredicate;

@property (strong, nonatomic) UIBarButtonItem *searchButton;

@end

@implementation AllExpensesTableViewController

#pragma mark - ViewControllerLifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createSearchBarButtonItem];
    [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem, _searchButton]];
    [self createSearchController];

    self.definesPresentationContext = YES;

    [NSFetchedResultsController deleteCacheWithName:@"All"];

    [self performFetch];
}

#pragma mark - Search -

- (void)createSearchBarButtonItem {
    _searchButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonPressed:)];
}

- (void)addRightBarButtonItemsToNavigationItem:(NSArray *)items {
    [self.navigationItem setRightBarButtonItems:items animated:YES];
}

- (void)searchBarButtonPressed:(UIBarButtonItem *)sender {
    [self addRightBarButtonItemsToNavigationItem:nil];

    self.navigationItem.titleView = _searchController.searchBar;
    [self.navigationItem.titleView becomeFirstResponder];
}

- (void)createSearchController {
        // Create the search controller with this controller displaying the search results
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.hidesNavigationBarDuringPresentation = NO;
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    [self.searchController.searchBar sizeToFit];
}

#pragma mark SuperEditButtonItem

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    if (self.navigationItem.rightBarButtonItems.count == 2) {
        [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem]];
    } else if (self.navigationItem.rightBarButtonItems.count == 1) {
        [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem, _searchButton]];
    }
}

#pragma mark UISearchBarDelegate

-(void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    CGRect frame = self.navigationItem.titleView.frame;
    frame.size.width = 0.0f;
    [UIView animateWithDuration:0.3f
                          delay:0.0f
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         self.navigationItem.titleView.frame = frame;
                         self.navigationItem.titleView.alpha = 0;
                     } completion:^(BOOL finished) {
                         self.navigationItem.titleView = nil;
                         [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem, _searchButton]];
                     }];
     }

#pragma mark SearchResultsUpdater

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController {
    NSString *searchText = self.searchController.searchBar.text;

    if (searchText.length > 0) {
        NSExpression *categoryTitle = [NSExpression expressionForKeyPath:@"category.title"];
        NSExpression *text = [NSExpression expressionForConstantValue:searchText];
        NSPredicate *containsTitle = [NSComparisonPredicate predicateWithLeftExpression:categoryTitle
                                                                        rightExpression:text
                                                                               modifier:NSDirectPredicateModifier
                                                                                   type:NSContainsPredicateOperatorType options:NSCaseInsensitivePredicateOption];
        NSExpression *description = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(descriptionOfExpense))];
        NSPredicate *containsDescription = [NSComparisonPredicate predicateWithLeftExpression:description
                                                                              rightExpression:text
                                                                                     modifier:NSDirectPredicateModifier
                                                                                         type:NSContainsPredicateOperatorType
                                                                                      options:NSCaseInsensitivePredicateOption];
        NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[containsTitle, containsDescription]];

        self.searchPredicate = predicate;
    } else if (searchText.length == 0) {
        self.searchPredicate = nil;
    }
    
    [self.tableView reloadData];
}

#pragma mark - Segues

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MoreInfo"]) {
        MoreInfoViewController *detailsViewController = (MoreInfoViewController *)[segue destinationViewController];

        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

            ExpenseData *expense = [_fetchedResultsController objectAtIndexPath:indexPath];
            detailsViewController.expenseToShow = expense;
            detailsViewController.managedObjectContext = _fetchedResultsController.managedObjectContext;
        }
    }
}

#pragma mark - UITableView -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.searchPredicate == nil ? [[self.fetchedResultsController sections] count] : 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchPredicate == nil) {
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
        return [sectionInfo numberOfObjects];
    } else {
        return [[self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:self.searchPredicate]count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AllCell"];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.searchPredicate == nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];

        NSError *error = nil;
        if (![context save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSString *)formatDate:(NSDate *)theDate {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"dd.MM.YY"];
    }
    return [formatter stringFromDate:theDate];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ExpenseData *expense = nil;
    if (self.searchPredicate == nil) {
        expense = [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else {
        expense = [self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:self.searchPredicate][indexPath.row];
    }
    cell.textLabel.text = expense.category.title;
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f, %@", [expense.amount floatValue], [self formatDate:expense.dateOfExpense]];
}

#pragma mark - NSFetchedResultsController -

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([ExpenseData class]) inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;

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
                                                             cacheName:@"All"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;

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