    //
    //  AppDelegate.m
    //  Depoza
    //
    //  Created by Ivan Magda on 20.11.14.
    //  Copyright (c) 2014 Ivan Magda. All rights reserved.
    //

    //ViewControllers
#import "AppDelegate.h"
#import "MainViewController.h"
#import "SearchExpensesTableViewController.h"
#import "SettingsTableViewController.h"
#import "MoreInfoTableViewController.h"
#import <KVNProgress/KVNProgress.h>

    //CoreData
#import "ExpenseData+Fetch.h"
#import "CategoryData+Fetch.h"
#import "Fetch.h"

@interface AppDelegate ()

@end

@implementation AppDelegate {
    MainViewController *_mainViewController;
    SearchExpensesTableViewController *_allExpensesTableViewController;
    SettingsTableViewController *_settingsTableViewController;
}

#pragma mark - Persistent Stack

- (void)spreadManagedObjectContext {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;

        //Get the MainViewController and set it's as a observer for creating context
    UINavigationController *navigationController = (UINavigationController *)tabBarController.viewControllers[0];
    _mainViewController = (MainViewController *)navigationController.viewControllers[0];

        //Get the AllExpensesViewController
    navigationController = (UINavigationController *)tabBarController.viewControllers[1];
    _allExpensesTableViewController = (SearchExpensesTableViewController *)navigationController.viewControllers[0];

        //Get the SettingsTableViewController
    navigationController = (UINavigationController *)tabBarController.viewControllers[2];
    _settingsTableViewController = (SettingsTableViewController *)navigationController.viewControllers[0];

    NSParameterAssert(_managedObjectContext);
    _mainViewController.managedObjectContext = _managedObjectContext;
    _allExpensesTableViewController.managedObjectContext = _managedObjectContext;
    _settingsTableViewController.managedObjectContext = _managedObjectContext;
}

- (NSURL *)storeURL {
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
    return [documentsDirectory URLByAppendingPathComponent:@"DataStore.sqlite"];
}

- (NSURL*)modelURL {
    return [[NSBundle mainBundle] URLForResource:@"DataModel" withExtension:@"momd"];
}

- (void)checkForMinimalData {
    __weak NSManagedObjectContext *context = self.managedObjectContext;
    __weak Persistence *persistence = self.persistence;
    __weak MainViewController *controller = _mainViewController;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSInteger categoriesCount = [CategoryData countForCategoriesInContext:context];
        NSInteger expensesCount = [ExpenseData countForExpensesInContext:context];
        if (categoriesCount + expensesCount == 0) {
            NSLog(@"%s insert categories Data", __PRETTY_FUNCTION__);
            [persistence insertNecessaryCategoryData];
            [controller updateUserInterfaceWithNewFetch:NO];
        }
    });
}

#pragma mark PersistenceDelegate

- (void)persistenceStore:(Persistence *)persistence didChangeNotification:(NSNotification *)notification {
    [_mainViewController updateUserInterfaceWithNewFetch:YES];
}

- (void)persistenceStore:(Persistence *)persistence didImportUbiquitousContentChanges:(NSNotification *)notification {
    [_mainViewController updateUserInterfaceWithNewFetch:NO];
}

- (void)persistenceStore:(Persistence *)persistence willChangeNotification:(NSNotification *)notification {
    BOOL animated = YES;
    [_mainViewController.navigationController popToRootViewControllerAnimated:animated];
    [_allExpensesTableViewController.navigationController popToRootViewControllerAnimated:animated];
    [_settingsTableViewController.navigationController popToRootViewControllerAnimated:animated];
}

#pragma mark - KVNProgress

- (void)setKVNDisplayTime {
    KVNProgressConfiguration *configuration = [KVNProgressConfiguration defaultConfiguration];
    configuration.minimumSuccessDisplayTime = 0.55f;
    configuration.minimumErrorDisplayTime   = 0.75f;
    [KVNProgress setConfiguration:configuration];
}

#pragma mark - AppDelegate -

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.persistence = [[Persistence alloc]initWithStoreURL:self.storeURL modelURL:self.modelURL];
    self.managedObjectContext = self.persistence.managedObjectContext;
    self.persistence.delegate = self;

    [self spreadManagedObjectContext];
    [self setKVNDisplayTime];

    [self checkForMinimalData];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [Fetch updateTodayExpensesDictionary:self.managedObjectContext];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *query = url.query;
    if (query != nil) {
        if ([query hasPrefix:@"q="]) {
                // If we have a query string, strip out the "q=" part so we're just left with the identifier
            NSRange range = [query rangeOfString:@"q="];
            NSString *identifier = [query stringByReplacingOccurrencesOfString:@"^q=" withString:@"" options:NSRegularExpressionSearch range:range];

            ExpenseData *selectedExpense = [ExpenseData getExpenseFromIdValue:identifier.integerValue inManagedObjectContext:_managedObjectContext];

                //Manage navigation stack of MainViewControler navigationController
            NSInteger numberControllers = [_mainViewController.navigationController viewControllers].count;
            if (numberControllers > 1) {
                MoreInfoTableViewController *moreInfoController = [[_mainViewController.navigationController viewControllers]objectAtIndex:1];
                if ([moreInfoController.expenseToShow isEqual:selectedExpense]) {
                    return YES;
                } else {
                    [_mainViewController.navigationController popToRootViewControllerAnimated:NO];
                }
            }
            [_mainViewController performSegueWithIdentifier:@"MoreInfo" sender:selectedExpense];
            
            return YES;
        }
    }
    return NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore]synchronize];
    [self.persistence removePersistentStoreNotificationSubscribes];
    [self.persistence saveContext];
}

@end