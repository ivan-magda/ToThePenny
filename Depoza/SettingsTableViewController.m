//
//  SettingsTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewControllers
#import "SettingsTableViewController.h"
#import "CategoriesTableViewController.h"
#import "ManageCategoryTableViewController.h"
#import "ZFModalTransitionAnimator.h"
    //CoreData
#import "CategoryData+Fetch.h"

static NSString * const kAddExpenseOnStartupKey = @"AddExpenseOnStartup";

@interface SettingsTableViewController ()

@property (weak, nonatomic) IBOutlet UISwitch *startupScreenSwitch;

@end

@implementation SettingsTableViewController {
    BOOL _addExpenseOnStartup;

    ZFModalTransitionAnimator *_transitionAnimator;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);

    _addExpenseOnStartup = [[NSUserDefaults standardUserDefaults]boolForKey:kAddExpenseOnStartupKey];
    [self.startupScreenSwitch setOn:_addExpenseOnStartup];
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    NSParameterAssert(self.managedObjectContext != nil);

    if ([segue.identifier isEqualToString:@"AddCategory"]) {
        UINavigationController *navC = segue.destinationViewController;
        ManageCategoryTableViewController *controller = (ManageCategoryTableViewController *)navC.topViewController;
        controller.managedObjectContext = self.managedObjectContext;
        controller.categoryToEdit = nil;

            // create animator object with instance of modal view controller
            // we need to keep it in property with strong reference so it will not get release
        _transitionAnimator = [[ZFModalTransitionAnimator alloc] initWithModalViewController:navC];
        _transitionAnimator.transitionDuration = 0.7f;
        _transitionAnimator.bounces = NO;
        _transitionAnimator.behindViewAlpha = 0.5f;
        _transitionAnimator.behindViewScale = 0.7f;
        _transitionAnimator.direction = ZFModalTransitonDirectionRight;

            // set transition delegate of modal view controller to our object
        navC.transitioningDelegate = _transitionAnimator;
        navC.modalPresentationStyle = UIModalPresentationCustom;

    } else if ([segue.identifier isEqualToString:@"Categories"]) {
        CategoriesTableViewController *controller = segue.destinationViewController;
        controller.managedObjectContext = _managedObjectContext;
    }
}

#pragma mark - UITableViewDelegate -

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 2 && indexPath.row == 0) {
        return nil;
    }
    return indexPath;
}

- (void)tableView:(UITableView *)tableView willDisplayFooterView:(UIView *)view forSection:(NSInteger)section {
        // Set the text color of our header/footer text.
    UITableViewHeaderFooterView *footer = (UITableViewHeaderFooterView *)view;
    [footer.textLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:14]];
}

#pragma mark - IBAction -

- (IBAction)startupSwitchDidChangeValue:(UISwitch *)sender {
    _addExpenseOnStartup = sender.on;

    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:_addExpenseOnStartup forKey:kAddExpenseOnStartupKey];
    [userDefaults synchronize];
}

@end
