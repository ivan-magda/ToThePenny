//
//  CategoriesTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 02.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewControllers
#import "CategoriesTableViewController.h"
#import "ManageCategoryTableViewController.h"
    //ViewAnimations
#import "ZFModalTransitionAnimator.h"
#import <KVNProgress/KVNProgress.h>
    //CoreData
#import "CategoryData+Fetch.h"
#import "CategoriesInfo.h"

NSString * const CategoriesTableViewControllerDidRemoveCategoryNotification = @"CategoriesTableViewControllerDidRemoveCategory";

@interface CategoriesTableViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@end

@implementation CategoriesTableViewController {
    ZFModalTransitionAnimator *_transitionAnimator;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = self.editButtonItem;

    [NSFetchedResultsController deleteCacheWithName:@"CategoriesVC"];

    [self performFetch];
}

- (void)dealloc {
    _fetchedResultsController.delegate = nil;
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];

    [self configurateCell:cell indexPath:indexPath];

    return cell;
}

- (void)configurateCell:(UITableViewCell *)cell indexPath:(NSIndexPath *)indexPath {
    NSParameterAssert(cell);

    CategoryData *category = [self.fetchedResultsController objectAtIndexPath:indexPath];

    cell.textLabel.text = category.title;
    cell.imageView.image = [UIImage imageNamed:category.iconName];
}

#pragma mark UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - UITableViewDataSource -

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.fetchedResultsController.managedObjectContext deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];

        [[NSNotificationCenter defaultCenter]postNotificationName:CategoriesTableViewControllerDidRemoveCategoryNotification object:nil];

        NSError *error = nil;
        if (![self.fetchedResultsController.managedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }

        [KVNProgress showSuccessWithStatus:NSLocalizedString(@"Deleted", @"CategoriesVC show message when category deleted")];
    }
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EditCategory"]) {
        UINavigationController *navigationController = segue.destinationViewController;

        ManageCategoryTableViewController *controller = (ManageCategoryTableViewController *)navigationController.topViewController;
        controller.managedObjectContext = _managedObjectContext;

        CategoryData *category = nil;
        if ([sender isKindOfClass:[UITableViewCell class]]) {
            NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];

            category = [self.fetchedResultsController objectAtIndexPath:indexPath];
        }
        controller.categoryToEdit = category;

            // create animator object with instance of modal view controller
            // we need to keep it in property with strong reference so it will not get release
        _transitionAnimator = [[ZFModalTransitionAnimator alloc] initWithModalViewController:navigationController];
        _transitionAnimator.transitionDuration = 0.7f;
        _transitionAnimator.bounces = NO;
        _transitionAnimator.behindViewAlpha = 0.5f;
        _transitionAnimator.behindViewScale = 0.7f;
        _transitionAnimator.direction = ZFModalTransitonDirectionRight;

            // set transition delegate of modal view controller to our object
        navigationController.transitioningDelegate = _transitionAnimator;
        navigationController.modalPresentationStyle = UIModalPresentationCustom;
    }
}

#pragma mark - NSFetchedResultsController -

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }

    NSFetchRequest *fetchRequest = [NSFetchRequest new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([CategoryData class]) inManagedObjectContext:self.managedObjectContext];
    fetchRequest.entity = entity;

        // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];

        // Edit the sort key as appropriate.
    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:NSStringFromSelector(@selector(title)) ascending:YES];

    [fetchRequest setSortDescriptors:@[sort]];

        // Edit the section name key path and cache name if appropriate.
        // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"CategoriesVC"];

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
