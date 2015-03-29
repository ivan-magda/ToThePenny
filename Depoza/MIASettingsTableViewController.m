//
//  SettingsTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "MIASettingsTableViewController.h"
#import "MIAAddCategoryViewController.h"
#import "MIAMainViewController.h"

@implementation MIASettingsTableViewController

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
        MIAMainViewController *mainViewController = (MIAMainViewController *)navigationController.viewControllers[0];

        MIAAddCategoryViewController *controller = (MIAAddCategoryViewController *)segue.destinationViewController;
        controller.managedObjectContext = self.managedObjectContext;
        controller.delegate = mainViewController;
    }
}

@end
