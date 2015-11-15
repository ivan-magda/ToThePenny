//
//  AllExpensesTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 08.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewController
#import "SearchTableViewController.h"
#import "DetailExpenseTableViewController.h"
#import "SelectedCategoryTableViewController.h"
    //View
#import "CustomRightDetailCell.h"
#import "FoundExpenseCell.h"
    //CoreData
#import "ExpenseData+Fetch.h"
#import "CategoryData+Fetch.h"
#import "CategoriesInfo.h"
    //Categories
#import "NSString+FormatAmount.h"
#import "NSString+FormatDate.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

static NSString * const kFoundExpenseCellReuseIdentifier = @"FoundExpenseCell";
static NSString * const kPlainCellReuseIdentifier = @"AllCell";

static NSString * const kExpenseFetchedResultsControllerCacheName = @"AllExpense";

typedef NS_ENUM(NSInteger, SearchTableViewCellType) {
    SearchTableViewCellTypeExpense,
    SearchTableViewCellTypeCategory,
    SearchTableViewCellTypeNothingFound
};

@interface SearchTableViewController () <NSFetchedResultsControllerDelegate, UISearchBarDelegate>

@property (strong, nonatomic) NSFetchedResultsController *expenseFetchedResultsController;

@property (strong, nonatomic) UISearchBar *searchBar;
@property (strong, nonatomic) NSPredicate *categoriesSearchPredicate;
@property (strong, nonatomic) NSPredicate *expensesSearchPredicate;

@end

@implementation SearchTableViewController {
    NSArray *_filteredCategories;
    NSArray *_filteredExpenses;
}

#pragma mark - ViewControllerLifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);

    [self configurateSearchBar];

    [NSFetchedResultsController deleteCacheWithName:kExpenseFetchedResultsControllerCacheName];
    [self performFetch];
}

#pragma mark - Search -

- (void)configurateSearchBar {
    _searchBar = [UISearchBar new];
    _searchBar.delegate = self;
    _searchBar.showsCancelButton = NO;
    _searchBar.tintColor = UIColorFromRGB(0x067AB5);
    _searchBar.placeholder = NSLocalizedString(@"Search", @"Placeholder text in search bar of SearchVC");
    [_searchBar sizeToFit];
    self.navigationItem.titleView = _searchBar;
    
    self.definesPresentationContext = YES;
    self.tableView.allowsSelectionDuringEditing = YES;
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
        NSExpression *expenses = [NSExpression expressionForKeyPath:@"expense.@count"];
        NSExpression *count = [NSExpression expressionForConstantValue:@0];
        NSPredicate *numberOfExpensesGreaterThenZero = [NSComparisonPredicate predicateWithLeftExpression:expenses rightExpression:count modifier:NSDirectPredicateModifier type:NSGreaterThanPredicateOperatorType options:0];

        NSPredicate *categoryPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[numberOfExpensesGreaterThenZero, containsTitlePredicate]];
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

        self.categoriesSearchPredicate = categoryPredicate;
        self.expensesSearchPredicate = expensesPredicate;

        _filteredCategories = [CategoryData getCategoriesInContext:_expenseFetchedResultsController.managedObjectContext usingPredicate:_categoriesSearchPredicate];
        _filteredExpenses = [self filteredArrayOfExpensesUsingPredicate:self.expensesSearchPredicate];
    } else {
        self.categoriesSearchPredicate = nil;
        self.expensesSearchPredicate = nil;
        _filteredCategories = nil;
        _filteredExpenses = nil;
    }

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
}


- (BOOL)isSearchPredicatesIsNil {
    return (_categoriesSearchPredicate == nil && _expensesSearchPredicate == nil);
}

- (NSArray *)filteredArrayOfExpensesUsingPredicate:(NSPredicate *)predicate {
    return [self.expenseFetchedResultsController.fetchedObjects filteredArrayUsingPredicate:predicate];
}

- (CategoryData *)filteredCategoryForIndexPath:(NSIndexPath *)indexPath {
    return _filteredCategories[(NSInteger)indexPath.row];
}

- (NSNumber *)sumOfExpensesWhenSearchProceed {
    NSNumber *sum = [_filteredExpenses valueForKeyPath:@"@sum.amount"];

    return sum;
}

- (BOOL)isNothingFound {
    return (![self isSearchPredicatesIsNil] && _filteredCategories.count == 0 && _filteredExpenses.count == 0);
}

#pragma mark UISearchBarDelegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    [self.searchBar setShowsCancelButton:YES animated:YES];
    
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    [self.searchBar setShowsCancelButton:NO animated:YES];
    self.searchBar.text = nil;

    _categoriesSearchPredicate = nil;
    _expensesSearchPredicate = nil;
    _filteredCategories = nil;
    _filteredExpenses = nil;

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
    if ([identifier isEqualToString:@"MoreInfo"]) {
        return YES;
    } else if ([identifier isEqualToString:@"CategorySelected"] && ![self isNothingFound]) {
        return YES;
    }

    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        UITableViewCell *cell = (UITableViewCell *)sender;
        indexPath = [self.tableView indexPathForCell:cell];
    }
    
    if ([segue.identifier isEqualToString:@"MoreInfo"]) {
        DetailExpenseTableViewController *detailsViewController = segue.destinationViewController;
        detailsViewController.managedObjectContext = _expenseFetchedResultsController.managedObjectContext;
        if ([self isSearchPredicatesIsNil]) {
            ExpenseData *expense = [_expenseFetchedResultsController objectAtIndexPath:indexPath];
            detailsViewController.expenseToShow = expense;
        } else {
            NSArray *filteredExpenses = [_expenseFetchedResultsController.fetchedObjects filteredArrayUsingPredicate:_expensesSearchPredicate];
            ExpenseData *expense = filteredExpenses[(NSInteger)indexPath.row];
            detailsViewController.expenseToShow = expense;
        }
    } else if ([segue.identifier isEqualToString:@"CategorySelected"] && indexPath.section == 0) {
        SelectedCategoryTableViewController *controller = segue.destinationViewController;
        controller.managedObjectContext = _expenseFetchedResultsController.managedObjectContext;
        
        CategoriesInfo *category = [CategoriesInfo categoryInfoFromCategoryData:[self filteredCategoryForIndexPath:indexPath]];
        controller.selectedCategory = category;
        
        NSDate *minimumDate = [ExpenseData oldestDateExpenseInManagedObjectContext:_managedObjectContext andCategoryId:category.idValue];
        NSDate *maximumDate = [ExpenseData mostRecentDateExpenseInManagedObjectContext:_managedObjectContext andCategoryId:category.idValue];
        controller.timePeriodDates = @[minimumDate, maximumDate];
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
            id <NSFetchedResultsSectionInfo> sectionInfo = [self.expenseFetchedResultsController sections][(NSInteger)section];
            return [sectionInfo numberOfObjects];
        } else {
            return 0;
        }
    } else if ([self isNothingFound] && section == 0) {
        return 1;
    } else {
        if (section == 0) {
            return _filteredCategories.count;
        } else {
            return _filteredExpenses.count;
        }
    }
}

- (SearchTableViewCellType)searchTableViewCellTypeForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && _categoriesSearchPredicate != nil && ![self isNothingFound]) {
        return SearchTableViewCellTypeCategory;
    } else if ([self isNothingFound] && indexPath.section == 0) {
        return SearchTableViewCellTypeNothingFound;
    } else {
        return SearchTableViewCellTypeExpense;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self searchTableViewCellTypeForRowAtIndexPath:indexPath]) {
        case SearchTableViewCellTypeCategory :
            return (CustomRightDetailCell *)[tableView dequeueReusableCellWithIdentifier:kPlainCellReuseIdentifier];
        case SearchTableViewCellTypeNothingFound :
            return [tableView dequeueReusableCellWithIdentifier:kPlainCellReuseIdentifier];
        case SearchTableViewCellTypeExpense :
            return (FoundExpenseCell *)[tableView dequeueReusableCellWithIdentifier:kFoundExpenseCellReuseIdentifier];
        default :
            return nil;
    }
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ExpenseData *expense = nil;
    if ([self isSearchPredicatesIsNil]) {
        FoundExpenseCell *cellToConfigurate = (FoundExpenseCell *)cell;
        expense = [self.expenseFetchedResultsController objectAtIndexPath:indexPath];

        [self configureFoundExpenseCell:cellToConfigurate withExpense:expense];
    } else {
        if (indexPath.section == 0) {
            CustomRightDetailCell *cellToConfigurate = (CustomRightDetailCell *)cell;
            CategoryData *category = [self filteredCategoryForIndexPath:indexPath];

            cellToConfigurate.leftLabel.text = category.title;
            cellToConfigurate.selectionStyle = UITableViewCellSelectionStyleDefault;
            cellToConfigurate.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

            NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"idValue == %@", category.idValue]];
            NSArray *results = [CategoryData sumOfExpensesInManagedObjectContext:_expenseFetchedResultsController.managedObjectContext usingPredicate:predicate];
            NSParameterAssert(results.count == 1);

            cellToConfigurate.rightDetailLabel.text = [NSString formatAmount:[results lastObject][@"sum"]];
        } else {
            FoundExpenseCell *cellToConfigurate = (FoundExpenseCell *)cell;
            expense = _filteredExpenses[(NSInteger)indexPath.row];

            [self configureFoundExpenseCell:cellToConfigurate withExpense:expense];
        }
    }
}

- (void)configureFoundExpenseCell:(FoundExpenseCell *)cell withExpense:(ExpenseData *)expense {
    cell.categoryTitleLabel.text = expense.category.title;
    cell.descriptionLabel.text = (expense.descriptionOfExpense.length == 0 ? NSLocalizedString(@"(No Description)", @"Found expense cell no descrition text") : expense.descriptionOfExpense);
    cell.amountLabel.text = [NSString formatAmount:expense.amount];
    cell.dateLabel.text = [NSString formatDate:expense.dateOfExpense];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return [self isSearchPredicatesIsNil];
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.expenseFetchedResultsController managedObjectContext];
        [context deleteObject:[self.expenseFetchedResultsController objectAtIndexPath:indexPath]];

        NSError *error = nil;
        if (![context save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (![self isSearchPredicatesIsNil] && section == 1) {
        NSNumber *sum = [self sumOfExpensesWhenSearchProceed];

        return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Transactions", @"Transactions title for header in SearchVC"), [NSString formatAmount:sum]];
    } else if (![self isSearchPredicatesIsNil] && section == 0) {
        NSArray *filteredCategories = _filteredCategories;

        NSMutableArray *predicateArray = [NSMutableArray new];
        for (CategoryData *category in filteredCategories) {
            NSExpression *categoryId = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(idValue))];
            NSExpression *idValue = [NSExpression expressionForConstantValue:category.idValue];
            NSPredicate *containsIdValue = [NSComparisonPredicate predicateWithLeftExpression:categoryId rightExpression:idValue modifier:NSDirectPredicateModifier type:NSEqualToPredicateOperatorType options:0];

            [predicateArray addObject:containsIdValue];
        }
        NSPredicate *predicate = [NSCompoundPredicate orPredicateWithSubpredicates:predicateArray];

        NSArray *results = [CategoryData sumOfExpensesInManagedObjectContext:_expenseFetchedResultsController.managedObjectContext usingPredicate:predicate];

        CGFloat sum = 0.0f;
        for (NSDictionary *sumDict in results) {
            sum += [sumDict[@"sum"]floatValue];
        }

        return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"Categories", @"Categories title for header in SearchVC"), [NSString formatAmount:@(sum)]];
    }
    return nil;
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    switch ([self searchTableViewCellTypeForRowAtIndexPath:indexPath]) {
        case SearchTableViewCellTypeCategory : {
            [self configureCell:cell atIndexPath:indexPath];
            break;
        }
        case SearchTableViewCellTypeNothingFound : {
            CustomRightDetailCell  *nothingFoundCell = (CustomRightDetailCell *)cell;
            nothingFoundCell.leftLabel.text = NSLocalizedString(@"Nothing found", @"Nothing found text for nothing found cell in SearchVC");
            nothingFoundCell.rightDetailLabel.text = nil;
            nothingFoundCell.selectionStyle = UITableViewCellSelectionStyleNone;
            nothingFoundCell.accessoryType = UITableViewCellAccessoryNone;
            break;
        }
        case SearchTableViewCellTypeExpense : {
            [self configureCell:cell atIndexPath:indexPath];
            break;
        }
        default :
            NSAssert(NO, @"Unsopported type of cell!");
            break;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    if (![self isSearchPredicatesIsNil]) {
        UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
        [footer.textLabel setFont:[UIFont fontWithName:@".SFUIText-Light" size:17]];
        footer.textLabel.textAlignment = NSTextAlignmentLeft;

        NSString *text = [tableView.dataSource tableView:tableView titleForHeaderInSection:section];
        if (text) {
            NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc]initWithString:text];

            NSRange range = [text rangeOfString:@":"];
            if (range.location != NSNotFound) {
                NSInteger length = text.length;
                range.location += 1;
                range.length = length - range.location;

                [attributedText addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0xFF3333) range:range];
            }
            footer.textLabel.attributedText = attributedText;

            footer.textLabel.textAlignment = NSTextAlignmentCenter;

            UIView *backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0f,0.0f,CGRectGetWidth(self.view.bounds),[tableView.delegate tableView:tableView heightForHeaderInSection:section])];
            backgroundView.backgroundColor = [UIColor colorWithRed:255 green:255 blue:255 alpha:0.85f];
            footer.backgroundView = backgroundView;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (![self isSearchPredicatesIsNil]) {
        if (section == 0 && _filteredCategories.count == 0) {
            return 0.0f;
        } else if ([[self sumOfExpensesWhenSearchProceed]floatValue] == 0.0f) {
            return 0.0f;
        }
        return self.tableView.sectionHeaderHeight + 16.0f;
    }
    return 0.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (![self isSearchPredicatesIsNil] && indexPath.section == 0) {
        return 44.0f;
    } else {
        return 60.0f;
    }
}

#pragma mark - NSFetchedResultsController -

- (NSFetchedResultsController *)expenseFetchedResultsController {
    if (_expenseFetchedResultsController != nil) {
        return _expenseFetchedResultsController;
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
                                                             cacheName:kExpenseFetchedResultsControllerCacheName];
    aFetchedResultsController.delegate = self;
    self.expenseFetchedResultsController = aFetchedResultsController;

    return _expenseFetchedResultsController;
}

- (void)performFetch {
    NSError *error;
    if (![self.expenseFetchedResultsController performFetch:&error]) {
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
    if (![self isSearchPredicatesIsNil]) {
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

    [self.tableView endUpdates];
}

@end