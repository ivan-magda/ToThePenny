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
    //View
#import "CustomRightDetailLabel.h"
    //CoreData
#import "ExpenseData.h"
#import "CategoryData+Fetch.h"
    //Categories
#import "NSString+FormatAmount.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface SearchExpensesTableViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate>

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) NSPredicate *categoriesSearchPredicate;
@property (strong, nonatomic) NSPredicate *expensesSearchPredicate;

@property (strong, nonatomic) UIBarButtonItem *searchButton;

@end

@implementation SearchExpensesTableViewController {
    BOOL _isSearchBarFirstResponder;
}

#pragma mark - ViewControllerLifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);

    [self configurateSearchBar];
    _isSearchBarFirstResponder = NO;

    _searchButton = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchBarButtonPressed:)];
    [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem, _searchButton]];

    self.definesPresentationContext = YES;
    self.tableView.allowsSelectionDuringEditing = YES;

    [NSFetchedResultsController deleteCacheWithName:@"All"];

    [self performFetch];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    if (_isSearchBarFirstResponder) {
        [_searchBar becomeFirstResponder];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

    if ([self isEditing]) {
        [self setEditing:NO];
    }
}

#pragma mark - Helpers -

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
    if ([self isSearchPredicatesIsNil]) {
        expense = [self.fetchedResultsController objectAtIndexPath:indexPath];

        cell.leftLabel.text = expense.category.title;
        cell.rightDetailLabel.text = [NSString stringWithFormat:@"%@, %@", [NSString formatAmount:expense.amount], [self formatDate:expense.dateOfExpense]];
    } else {
        if (indexPath.section == 0) {
            NSArray *filteredCategories = [CategoryData getCategoriesInContext:_fetchedResultsController.managedObjectContext usingPredicate:_categoriesSearchPredicate];
            CategoryData *category = filteredCategories[indexPath.row];

            cell.leftLabel.text = category.title;

            NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"idValue == %@", category.idValue]];
            NSArray *results = [CategoryData sumOfExpensesInManagedObjectContext:_fetchedResultsController.managedObjectContext usingPredicate:predicate];
            NSParameterAssert(results.count == 1);

            cell.rightDetailLabel.text = [NSString formatAmount:[results lastObject][@"sum"]];
        } else {
            expense = [self filteredArrayOfExpensesUsingPredicate:self.expensesSearchPredicate][indexPath.row];

            cell.leftLabel.text = (expense.descriptionOfExpense.length == 0 ? @"(No Description)" : expense.descriptionOfExpense);
            cell.rightDetailLabel.text = [NSString stringWithFormat:@"%@, %@", [NSString formatAmount:expense.amount], [self formatDate:expense.dateOfExpense]];
        }
    }
}

- (BOOL)isSearchPredicatesIsNil {
    return (_categoriesSearchPredicate == nil && _expensesSearchPredicate == nil);
}

- (NSArray *)filteredArrayOfExpensesUsingPredicate:(NSPredicate *)predicate {
    return [self.fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:predicate];
}

#pragma mark - Search -

- (void)configurateSearchBar {
    _searchBar = [UISearchBar new];
    _searchBar.delegate = self;
    _searchBar.showsCancelButton = YES;
    _searchBar.tintColor = UIColorFromRGB(0x067AB5);
    _searchBar.placeholder = NSLocalizedString(@"Search for expense", @"Placeholder text in search bar of SearchVC");
    [_searchBar sizeToFit];
}

- (void)addRightBarButtonItemsToNavigationItem:(NSArray *)items {
    [self.navigationItem setRightBarButtonItems:items animated:YES];
}

- (void)searchBarButtonPressed:(UIBarButtonItem *)sender {
    [self addRightBarButtonItemsToNavigationItem:nil];

    self.navigationItem.titleView = _searchBar;
    [_searchBar becomeFirstResponder];
}

- (void)updateSearchResultsWithSearchText:(NSString *)searchText {
    if (searchText.length > 0) {
            //Categories predicate
        NSExpression *categoryTitle = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(title))];
        NSExpression *title = [NSExpression expressionForConstantValue:searchText];
        NSPredicate *containsTitlePredicate = [NSComparisonPredicate predicateWithLeftExpression:categoryTitle
                                                                                 rightExpression:title
                                                                                        modifier:NSDirectPredicateModifier
                                                                                            type:NSContainsPredicateOperatorType
                                                                                         options:NSCaseInsensitivePredicateOption];
            //Expenses predicate
        NSExpression *categoryTitleForExpense = [NSExpression expressionForKeyPath:@"category.title"];
        NSExpression *text = [NSExpression expressionForConstantValue:searchText];
        NSPredicate *containsTitleForExpensePredicate = [NSComparisonPredicate predicateWithLeftExpression:categoryTitleForExpense
                                                                        rightExpression:text
                                                                               modifier:NSDirectPredicateModifier
                                                                                   type:NSContainsPredicateOperatorType
                                                                                options:NSCaseInsensitivePredicateOption];
        NSExpression *description = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(descriptionOfExpense))];
        NSPredicate *containsDescriptionPredicate = [NSComparisonPredicate predicateWithLeftExpression:description
                                                                                       rightExpression:text
                                                                                              modifier:NSDirectPredicateModifier
                                                                                                  type:NSContainsPredicateOperatorType
                                                                                               options:NSCaseInsensitivePredicateOption];
        NSPredicate *expensesPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:@[containsTitleForExpensePredicate, containsDescriptionPredicate]];

        self.categoriesSearchPredicate = containsTitlePredicate;
        self.expensesSearchPredicate = expensesPredicate;
    } else {
        self.categoriesSearchPredicate = nil;
        self.expensesSearchPredicate = nil;
    }

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark SetEditig

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    [super setEditing:editing animated:animated];

    if (editing) {
        [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem]];
    } else {
        [self addRightBarButtonItemsToNavigationItem:@[self.editButtonItem, _searchButton]];
    }
}

#pragma mark UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];

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
    self.searchBar.text = nil;
    self.categoriesSearchPredicate = nil;
    self.expensesSearchPredicate = nil;

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self searchBarSearchButtonClicked];
        return NO;
    }
    NSString *newText = [searchBar.text stringByReplacingCharactersInRange:range withString:text];
    [self updateSearchResultsWithSearchText:newText];

    return YES;
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if (searchText.length == 0) {
        [self updateSearchResultsWithSearchText:searchText];
    }
}

- (void)searchBarSearchButtonClicked {
    [self.searchBar resignFirstResponder];

    [self updateSearchResultsWithSearchText:_searchBar.text];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self searchBarSearchButtonClicked];
}

#pragma mark - Segues

- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
    if ([identifier isEqualToString:@"MoreInfo"] && [self isEditing]) {
        return NO;
    }
    return YES;
}

#warning need to override
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"MoreInfo"]) {
        DetailExpenseTableViewController *detailsViewController = segue.destinationViewController;
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

            detailsViewController.managedObjectContext = _fetchedResultsController.managedObjectContext;
            if (self.categoriesSearchPredicate == nil) {
                ExpenseData *expense = [_fetchedResultsController objectAtIndexPath:indexPath];
                detailsViewController.expenseToShow = expense;

                _isSearchBarFirstResponder = (self.searchBar.isFirstResponder);
            } else {
                NSArray *filteredExpenses = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:_expensesSearchPredicate];
                ExpenseData *expense = filteredExpenses[indexPath.row];
                detailsViewController.expenseToShow = expense;

                _isSearchBarFirstResponder = YES;
            }
        }
    }

    [self.searchBar resignFirstResponder];
}

#pragma mark - UITableView -
#pragma mark UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self isSearchPredicatesIsNil]) {
        if (section == 0) {
            id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
            return [sectionInfo numberOfObjects];
        } else {
            return 0;
        }
    } else {
        if (section == 0) {
            return [[CategoryData getCategoriesInContext:_fetchedResultsController.managedObjectContext usingPredicate:_categoriesSearchPredicate]count];
        } else {
            return [[self filteredArrayOfExpensesUsingPredicate:self.expensesSearchPredicate]count];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CustomRightDetailLabel *cell = (CustomRightDetailLabel *)[tableView dequeueReusableCellWithIdentifier:@"AllCell"];
    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self isSearchPredicatesIsNil];
}

#warning check for correct object received to delete
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

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self isEditing]) {
        return nil;
    }
    return indexPath;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self isSearchPredicatesIsNil] && section == 1) {
        NSArray *filteredExpenses = [_fetchedResultsController.fetchedObjects filteredArrayUsingPredicate:_expensesSearchPredicate];
        NSNumber *sum = [filteredExpenses valueForKeyPath:@"@sum.amount"];

        return [NSString stringWithFormat:@"Transactions %@", [NSString formatAmount:sum]];
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (![self isSearchPredicatesIsNil] && section == 1) {
        return self.tableView.sectionHeaderHeight;
    }
    return 0.0f;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if (![self isSearchPredicatesIsNil]) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        [footer.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:17]];
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

- (NSFetchedResultsController *)fetchedResultsController {
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

    if ([self isSearchPredicatesIsNil]) {
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
    } else {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
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