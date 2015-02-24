//
//  SettingsTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "AddCategoryViewController.h"
#import "MainViewController.h"

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);
}

#pragma mark - Segues -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSParameterAssert(self.managedObjectContext != nil);

    if ([segue.identifier isEqualToString:@"AddCategory"]) {
        UINavigationController *navigationController = self.navigationController;

        UITabBarController *tabBarController = (UITabBarController *)navigationController.parentViewController;
        navigationController = (UINavigationController *)tabBarController.viewControllers[0];
        MainViewController *mainViewController = (MainViewController *)navigationController.viewControllers[0];

        AddCategoryViewController *controller = (AddCategoryViewController *)segue.destinationViewController;
        controller.managedObjectContext = self.managedObjectContext;
        controller.delegate = mainViewController;
    }
}

@end
