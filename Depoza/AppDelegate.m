//
//  AppDelegate.m
//  Depoza
//
//  Created by Ivan Magda on 20.11.14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "AllExpensesTableViewController.h"
#import "SettingsTableViewController.h"
#import <KVNProgress/KVNProgress.h>

    //CoreData
#import "Persistence.h"

@interface AppDelegate ()

@property (strong, nonatomic) Persistence *persistence;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end

@implementation AppDelegate

- (void)spreadManagedObjectContext {
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;

        //Get the MainViewController and set it's as a observer for creating context
    UINavigationController *navigationController = (UINavigationController *)tabBarController.viewControllers[0];
    MainViewController *mainViewController = (MainViewController *)navigationController.viewControllers[0];

        //Get the AllExpensesViewController
    navigationController = (UINavigationController *)tabBarController.viewControllers[1];
    AllExpensesTableViewController *allExpensesController = (AllExpensesTableViewController *)navigationController.viewControllers[0];

        //Get the SettingsTableViewController
    navigationController = (UINavigationController *)tabBarController.viewControllers[2];
    SettingsTableViewController *settingsViewController = (SettingsTableViewController *)navigationController.viewControllers[0];

    self.persistence = [Persistence sharedInstance];
    self.managedObjectContext = [self.persistence managedObjectContext];

    NSParameterAssert(_managedObjectContext);
    mainViewController.managedObjectContext = _managedObjectContext;
    allExpensesController.managedObjectContext = _managedObjectContext;
    settingsViewController.managedObjectContext = _managedObjectContext;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self spreadManagedObjectContext];

    KVNProgressConfiguration *configuration = [KVNProgressConfiguration defaultConfiguration];
    configuration.minimumSuccessDisplayTime = 0.55f;
    configuration.minimumErrorDisplayTime   = 0.75f;
    [KVNProgress setConfiguration:configuration];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    
    [_persistence saveContext];
}

@end