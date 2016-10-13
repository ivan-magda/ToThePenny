//
//  MainTableViewProtocolsImplementer.m
//  Depoza
//
//  Created by Ivan Magda on 26.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//
    //View
#import "MainTableViewProtocolsImplementer.h"
#import "MainViewCell.h"
    //CoreData
#import "ExpenseData.h"
#import "CategoryData.h"
    //Categories
#import "NSString+FormatAmount.h"
#import "NSDate+IsDateBetweenCurrentMonth.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

static const CGFloat kTableViewRowHeight = 44.0f;

typedef NS_ENUM(NSInteger, ScrollDirection) {
    ScrollDirectionNone,
    ScrollDirectionRight,
    ScrollDirectionLeft,
    ScrollDirectionUp,
    ScrollDirectionDown,
    ScrollDirectionCrazy,
};

@interface MainTableViewProtocolsImplementer () <UIScrollViewDelegate>

@property (nonatomic, assign) CGFloat lastContentOffset;

@end

@implementation MainTableViewProtocolsImplementer {
    UILabel *_tableViewHeaderLabel;
}

- (instancetype)initWithTableView:(UITableView *)tableView fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController {
    if (self = [super init]) {
        _tableView = tableView;
        _fetchedResultsController = fetchedResultsController;
        _tableViewHeaderLabel = nil;
    }
    return self;
}

#pragma mark - Helpers -

- (NSString *)formatDate:(NSDate *)theDate {

    static NSDateFormatter *formatter = nil;
    if (formatter == nil) {
        formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"HH:mm"];
    }
    return [formatter stringFromDate:theDate];
}

- (BOOL)isCurrentMonthShowing {
    ExpenseData *anExpense = [_fetchedResultsController.fetchedObjects firstObject];
    return [NSDate isDateBetweenCurrentMonth:anExpense.dateOfExpense];
}

- (NSAttributedString *)colorAttributedStringForTableHeaderView {
    NSString *text = [self.tableView.dataSource tableView:self.tableView titleForHeaderInSection:0];
    if (!text) {
        return nil;
    }
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc]initWithString:text];

    NSRange range = [text rangeOfString:@":"];
    if (range.location != NSNotFound) {
        NSInteger length = text.length;
        range.location += 1;
        range.length = length - range.location;
        [attributedText addAttribute:NSForegroundColorAttributeName value:UIColorFromRGB(0xFF3333) range:range];
    }

    return attributedText;
}

- (void)configureCell:(MainViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    ExpenseData *expense = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.categoryLabel.text = (expense.descriptionOfExpense.length == 0 ? expense.category.title : expense.descriptionOfExpense);
    cell.amountLabel.text = [NSString stringWithFormat:@"%@", [NSString formatAmount:expense.amount]];
    
    cell.categoryLabel.accessibilityLabel = cell.categoryLabel.text;
    cell.amountLabel.accessibilityLabel = cell.amountLabel.text;
}

- (BOOL)noNewTransactionsToday {
    return (self.fetchedResultsController.fetchedObjects.count == 0);
}

#pragma mark - UITableViewDataSource -

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger numberOfSections = [[self.fetchedResultsController sections]count];
    return numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    id<NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][(NSInteger)section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MainViewCell *cell = (MainViewCell *)[tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.accessibilityLabel = [NSString stringWithFormat:@"cell_%ld", (long)indexPath.row];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return (self.fetchedResultsController.fetchedObjects.count > 0);
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self noNewTransactionsToday]) {
        return nil;
    }

    if (![self isCurrentMonthShowing] && self.fetchedResultsController.fetchedObjects.count > 0) {
        return NSLocalizedString(@"All transactions for month", @"Title for header, when show all expenses for month");
    }

    NSArray *expenses = self.fetchedResultsController.fetchedObjects;
    CGFloat amount = 0.0f;
    for (ExpenseData *anExpense in expenses) {
        amount += [anExpense.amount floatValue];
    }

    NSString *today = NSLocalizedString(@"Today", @"Today in title for header ins section");

    return [NSString stringWithFormat:@"%@: %@", today, [NSString formatAmount:@(amount)]];
}

#pragma mark - UITableViewDelegate -

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configureCell:(MainViewCell *)cell atIndexPath:indexPath];

    UIView *separator = [[UIView alloc]initWithFrame: CGRectMake(15.0f, kTableViewRowHeight - 0.5f,tableView.bounds.size.width - 15.0f, 0.5f)];
    separator.backgroundColor = tableView.separatorColor;

    [cell addSubview:separator];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if ([self noNewTransactionsToday]) {
        return 0.0f;
    }
    
    return self.tableView.sectionHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if ([self noNewTransactionsToday]) {
        return nil;
    }

    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(15.0f, tableView.sectionHeaderHeight - 21.0f, CGRectGetWidth(tableView.bounds) - 30.0f, 21.0f)];
    label.font = [UIFont fontWithName:@".SFUIText-Light" size:17.0f];
    label.shadowOffset = CGSizeMake(0, 1);
    label.shadowColor = [UIColor whiteColor];

    NSAttributedString *attributedText = [self colorAttributedStringForTableHeaderView];
    if (!attributedText) {
        return nil;
    }
    label.attributedText = attributedText;
    label.textAlignment = NSTextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];

    _tableViewHeaderLabel = label;

    UIView *separator = [[UIView alloc]initWithFrame: CGRectMake(15.0f, tableView.sectionHeaderHeight - 0.5f,tableView.bounds.size.width - 15.0f, 0.5f)];
    separator.backgroundColor = tableView.separatorColor;

    UIView *view = [[UIView alloc]initWithFrame:CGRectMake(0.0f, 0.0f, tableView.bounds.size.width,tableView.sectionHeaderHeight)];
    view.backgroundColor = tableView.backgroundColor;

    [view addSubview:label];
    [view addSubview:separator];

    return view;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UIScrollViewDelegate -

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat sectionHeaderHeight = self.tableView.sectionHeaderHeight;

    //49.0f tabBar height
    if (scrollView.contentOffset.y <= sectionHeaderHeight && scrollView.contentOffset.y >= 0.0f) {
        scrollView.contentInset = UIEdgeInsetsMake(-scrollView.contentOffset.y, 0.0f, 48.0f, 0.0f);
    } else if (scrollView.contentOffset.y >= sectionHeaderHeight) {
        scrollView.contentInset = UIEdgeInsetsMake(-sectionHeaderHeight, 0.0f, 48.0f, 0.0f);
    }

    ScrollDirection scrollDirection = ScrollDirectionNone;

    if (_lastContentOffset > scrollView.contentOffset.y) {
        scrollDirection = ScrollDirectionDown;
    } else if (self.lastContentOffset < scrollView.contentOffset.y) {
        scrollDirection = ScrollDirectionUp;
    }

    self.lastContentOffset = scrollView.contentOffset.y;

    if (scrollDirection == ScrollDirectionDown && scrollView.contentOffset.y == sectionHeaderHeight) {
        [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0.0f) animated:YES];
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
            [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;

        case NSFetchedResultsChangeMove: {
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
        // The fetch controller has sent all current change notifications, so tell the table view to process all updates.
    if ([self isCurrentMonthShowing]) {
        _tableViewHeaderLabel.attributedText = [self colorAttributedStringForTableHeaderView];
    }

    [self.tableView endUpdates];
}

@end
