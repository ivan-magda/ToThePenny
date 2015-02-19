//
//  SettingsTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "AddCategoryViewController.h"

@implementation SettingsTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - Segues -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSParameterAssert(self.managedObjectContext != nil);

    if ([segue.identifier isEqualToString:@"AddCategory"]) {
        UINavigationController *navigationController = segue.destinationViewController;

        AddCategoryViewController *controller = (AddCategoryViewController *)navigationController.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
    }
}

@end
