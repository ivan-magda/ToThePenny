//
//  AllExpensesTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 08.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewController
#import "SearchExpensesTableViewController.h"
#import "DetailExpenseTableViewController.h"
#import "DetailExpenseTableViewController.h"
#import "MainViewController.h"
#import "AddExpenseViewController.h"
    //View
#import "CustomRightDetailLabel.h"
    //CoreData
#import "ExpenseData.h"
#import "CategoryData+Fetch.h"
    //Categories
#import "NSString+FormatAmount.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface SearchExpensesTableViewController () <NSFetchedResultsControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) UISearchController *searchController;
@property (strong, nonatomic) NSPredicate *searchPredicate;

@property (strong, nonatomic) UIBarButtonItem *searchButton;

@end

@implementation SearchExpensesTableViewController

#pragma mark - ViewControllerLifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);

    [self createSearchBarButtonItem];
    [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem, _searchButton]];
    [self createSearchController];

    self.definesPresentationContext = YES;
    self.tableView.allowsSelectionDuringEditing = YES;

    [NSFetchedResultsController deleteCacheWithName:@"All"];

    [self performFetch];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if ([self isEditing]) {
        [self setEditing:NO];
    }
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
    self.searchController.searchBar.tintColor = UIColorFromRGB(0x067AB5);
    [self.searchController.searchBar sizeToFit];
}

#pragma mark SetEditig

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    if (editing) {
        [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem]];

        [self.tableView beginUpdates];
        for (int i = 0; i < [[self.fetchedResultsController sections]count]; ++i) {
            id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][i];
            [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[sectionInfo numberOfObjects] inSection:i]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView endUpdates];
    } else {
        [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem, _searchButton]];

        [self.tableView beginUpdates];
        for (int i = 0; i < [[self.fetchedResultsController sections]count]; ++i) {
            id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][i];
            [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:[sectionInfo numberOfObjects] inSection:i]] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
        [self.tableView endUpdates];
    }
}

#pragma mark UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
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

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"MoreInfo"] && [self isEditing]) {
        return NO;
    }
    return YES;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MoreInfo"]) {
        DetailExpenseTableViewController *detailsViewController = segue.destinationViewController;
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

            detailsViewController.managedObjectContext = _fetchedResultsController.managedObjectContext;
            if (self.searchPredicate == nil) {
                ExpenseData *expense = [_fetchedResultsController objectAtIndexPath:indexPath];
                detailsViewController.expenseToShow = expense;
            } else {
                NSArray *filteredExpenses = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:_searchPredicate];
                ExpenseData *expense = filteredExpenses[indexPath.row];
                detailsViewController.expenseToShow = expense;
            }
        }
    } else if ([segue.identifier isEqualToString:@"AddExpense"]) {
        NSArray *categoriesTitles = sender;

            //Get MainVC and set it as delegate of AddExpenseVC
        NSArray *windows = [[UIApplication sharedApplication]windows];
        UITabBarController *tabBarController = (UITabBarController *)[[windows firstObject] rootViewController];
        UINavigationController *navigationController = (UINavigationController *)tabBarController.viewControllers[0];
        MainViewController *mainViewController = (MainViewController *)navigationController.viewControllers[0];

        UINavigationController *segueNavigationController = segue.destinationViewController;
        AddExpenseViewController *controller = (AddExpenseViewController *)segueNavigationController.topViewController;
        controller.delegate = mainViewController;
        controller.managedObjectContext = _managedObjectContext;
        controller.categories = categoriesTitles;
    }
}

#pragma mark - UITableView -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (self.searchPredicate == nil ? [[self.fetchedResultsController sections] count] : 1);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.searchPredicate == nil) {
        int adjustment = [self isEditing] ? 1 : 0;
        id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
        return [sectionInfo numberOfObjects] + adjustment;
    } else {
        return [[self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:self.searchPredicate]count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomRightDetailLabel *cell = (CustomRightDetailLabel *)[tableView dequeueReusableCellWithIdentifier:@"AllCell"];
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
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        NSArray *categoriesTitles = [CategoryData getAllTitlesInContext:_managedObjectContext];
        [self performSegueWithIdentifier:@"AddExpense" sender:categoriesTitles];
    }
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][indexPath.section];
    if (indexPath.row >= [sectionInfo numberOfObjects]) {
        return UITableViewCellEditingStyleInsert;
    } else {
        return UITableViewCellEditingStyleDelete;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][indexPath.section];
    if ([self isEditing] && indexPath.row < [sectionInfo numberOfObjects]) {
        return nil;
    }
    return indexPath;
}

#pragma mark Helpers

- (NSString *)formatDate:(NSDate *)theDate {
    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [NSDateFormatter new];
        [formatter setDateFormat:@"dd.MM.YY"];
    }
    return [formatter stringFromDate:theDate];
}

- (void)configureCell:(CustomRightDetailLabel *)cell atIndexPath:(NSIndexPath *)indexPath {
    ExpenseData *expense = nil;

    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][indexPath.section];

    if (self.searchPredicate == nil && indexPath.row < [sectionInfo numberOfObjects]) {
        expense = [self.fetchedResultsController objectAtIndexPath:indexPath];
    } else if (indexPath.row < [sectionInfo numberOfObjects]){
        expense = [self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:self.searchPredicate][indexPath.row];
    }

    if (self.searchPredicate == nil && indexPath.row >= [sectionInfo numberOfObjects] && [self isEditing]) {
        cell.leftLabel.text = @"Add Expense";
        cell.rightDetailLabel.text = nil;
        cell.editingAccessoryType = UITableViewCellAccessoryNone;
    } else {
        cell.leftLabel.text = expense.category.title;
        cell.rightDetailLabel.text = [NSString stringWithFormat:@"%@, %@", [NSString formatAmount:expense.amount], [self formatDate:expense.dateOfExpense]];
    }
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][indexPath.section];
    if (indexPath.row >= [sectionInfo numberOfObjects] && [self isEditing]) {
        NSArray *categoriesTitles = [CategoryData getAllTitlesInContext:_managedObjectContext];
        [self performSegueWithIdentifier:@"AddExpense" sender:categoriesTitles];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    UINavigationController *navigationController = [self.storyboard instantiateViewControllerWithIdentifier:@"EditNavigationController"];

    DetailExpenseTableViewController *editExpenseViewController = [navigationController.viewControllers firstObject];
    editExpenseViewController.managedObjectContext = _managedObjectContext;
    editExpenseViewController.expenseToShow = [_fetchedResultsController objectAtIndexPath:indexPath];
    
    [self presentViewController:navigationController animated:YES completion:nil];
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