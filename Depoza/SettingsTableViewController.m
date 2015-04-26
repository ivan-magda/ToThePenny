//
//  SettingsTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "AddCategoryTableViewController.h"
#import "MainViewController.h"

static NSString * const kAddExpenseOnStartupKey = @"AddExpenseOnStartup";

@interface SettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *startupScreenSwitch;

@end

@implementation SettingsTableViewController {
    BOOL _addExpenseOnStartup;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);

    _addExpenseOnStartup = [[NSUserDefaults standardUserDefaults]boolForKey:kAddExpenseOnStartupKey];
    [self.startupScreenSwitch setOn:_addExpenseOnStartup];
}

#pragma mark - Segues -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSParameterAssert(self.managedObjectContext != nil);

    if ([segue.identifier isEqualToString:@"AddCategory"]) {
        UINavigationController *navigationController = self.navigationController;

        UITabBarController *tabBarController = (UITabBarController *)navigationController.parentViewController;
        navigationController = (UINavigationController *)tabBarController.viewControllers[0];
        MainViewController *mainViewController = (MainViewController *)navigationController.viewControllers[0];

        UINavigationController *navC = segue.destinationViewController;
        AddCategoryTableViewController *controller = (AddCategoryTableViewController *)navC.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
        controller.delegate = mainViewController;
        controller.iconName = nil;
    }
}

#pragma mark - UITableViewDelegate -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - IBAction -

- (IBAction)startupSwitchDidChangeValue:(UISwitch *)sender {
    _addExpenseOnStartup = sender.on;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:_addExpenseOnStartup forKey:kAddExpenseOnStartupKey];
    [userDefaults synchronize];
}

@end
