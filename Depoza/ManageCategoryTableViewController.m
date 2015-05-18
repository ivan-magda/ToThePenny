//
//  AddCategoryViewController.m
//  Depoza
//
//  Created by Ivan Magda on 19.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewControllers
#import "ManageCategoryTableViewController.h"
#import "CategoryIconsCollectionViewController.h"
    //CoreData
#import "CategoryData+Fetch.h"
    //KVNProgress
#import <KVNProgress/KVNProgress.h>

NSString * const ManageCategoryTableViewControllerDidAddCategoryNotification = @"AddCategoryTableViewControllerDidAddCategory";
NSString * const ManageCategoryTableViewControllerDidUpdateCategoryNotification = @"AddCategoryTableViewControllerDidUpdateCategory";

@interface ManageCategoryTableViewController () <UITextFieldDelegate>

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender;

@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIImageView *iconImage;

@end

@implementation ManageCategoryTableViewController {
    NSString *_categoryName;
    NSString *_iconName;

    NSString *_originalCategoryName;
    NSString *_originalIconName;
}

#pragma mark - LifeCycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(self.managedObjectContext != nil);

    if (_categoryToEdit) {
        self.title = NSLocalizedString(@"Edit Category", @"Navigation item title text, ManageCategoryVC");
    } else {
        self.title = NSLocalizedString(@"Add Category", @"Navigation item title text, add category ManageCAtegoryVC");
    }

    _categoryName = _categoryToEdit.title;
    _iconName = _categoryToEdit.iconName;

    _originalCategoryName = _categoryName;
    _originalIconName = _iconName;

    self.textField.delegate = self;
    if (_categoryName.length > 0) {
        self.textField.text = _categoryName;
        self.doneButton.enabled = YES;
    } else {
        self.textField.text = nil;
    }
    [self.textField becomeFirstResponder];

    if (_iconName == nil) {
        _iconName = @"Puzzle";
    }
    self.iconImage.image = [UIImage imageNamed:_iconName];
}

#pragma mark - IBActions -

- (IBAction)cancelButtonPressed:(UIBarButtonItem *)sender {
    [self.textField resignFirstResponder];

    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)done:(id)sender {
    [self.textField resignFirstResponder];

    [self adjustmentOfText];

    if (!_categoryToEdit) {
        if ([self isUniqueName:_categoryName]) {
            CategoryData *category = [CategoryData categoryDataWithTitle:_categoryName iconName:_iconName andExpenses:nil inManagedObjectContext:_managedObjectContext];

            NSError *error = nil;
            if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
                NSLog(@"Error when save %@", [error localizedDescription]);
            }

            [[NSNotificationCenter defaultCenter]postNotificationName:ManageCategoryTableViewControllerDidAddCategoryNotification object:category];

            [KVNProgress showSuccessWithStatus:NSLocalizedString(@"Added", @"AddCategoryVC succes text for show") completion:^{
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        } else {
            [KVNProgress showErrorWithStatus:NSLocalizedString(@"Category already exist", @"AddCategorVC message for KVNProgress showWithError") completion:^{
                self.textField.text = @"";
                [self.textField becomeFirstResponder];
            }];
        }
    } else if (_categoryToEdit) {
        if (![_categoryName isEqualToString:_originalCategoryName] ||
            ![_iconName isEqualToString:_originalIconName]) {

            self.categoryToEdit.iconName = _iconName;
            self.categoryToEdit.title = _categoryName;

            NSError *error = nil;
            if ([self.managedObjectContext hasChanges] && ![self.managedObjectContext save:&error]) {
                NSLog(@"Error when save %@", [error localizedDescription]);
            }

            [[NSNotificationCenter defaultCenter]postNotificationName:ManageCategoryTableViewControllerDidUpdateCategoryNotification object:self.categoryToEdit];

            [KVNProgress showSuccessWithStatus:NSLocalizedString(@"Updated", @"AddCategoryVC update category text") completion:^{
                [self dismissViewControllerAnimated:YES completion:nil];
            }];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

#pragma mark - Helpers -

- (void)adjustmentOfText {
    _categoryName = [_categoryName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isUniqueName:(NSString *)name {
    return [CategoryData checkForUniqueName:name managedObjectContext:_managedObjectContext];
}

#pragma mark - UITextFieldDelegate -

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSString *stringFromTextField = [textField.text stringByReplacingCharactersInRange:range withString:string];

    self.doneButton.enabled = (stringFromTextField.length > 0);

    _categoryName = stringFromTextField;

    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    _categoryName = textField.text;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.textField resignFirstResponder];

    [self done:nil];

    return YES;
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ChooseIcon"]) {
        CategoryIconsCollectionViewController *controller = segue.destinationViewController;
        controller.selectedIconName = _iconName;
        controller.isAddingNewCategoryMode = YES;
    }
}

- (IBAction)didPickIcon:(UIStoryboardSegue *)unwindSegue {
    UIViewController *sourceVC = unwindSegue.sourceViewController;
    if ([sourceVC isKindOfClass:[CategoryIconsCollectionViewController class]]) {
        CategoryIconsCollectionViewController *controller = (CategoryIconsCollectionViewController *)sourceVC;
        NSString *iconName = controller.selectedIconName;
        self.iconImage.image = [UIImage imageNamed:iconName];
        _iconName = iconName;
    }
}

@end
