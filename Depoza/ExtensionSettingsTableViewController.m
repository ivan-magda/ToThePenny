//
//  ExtensionSettingsTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 24.03.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "ExtensionSettingsTableViewController.h"

static NSString * const kAppGroupSharedContainer = @"group.com.vanyaland.depoza";
static NSString * const kNumberExpensesToShowUserDefaultsKey = @"numberExpenseToShow";

@interface ExtensionSettingsTableViewController () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UIPickerView *pickerView;

@end

@implementation ExtensionSettingsTableViewController {
    BOOL _pickerViewVisible;
    NSUserDefaults *_defaults;
    NSInteger _numberExpenseToShow;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self configurateUserDefaults];

    _pickerViewVisible = NO;
    self.pickerView.hidden = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self updateNumberExpenseToShowWithValue:_numberExpenseToShow];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)_numberExpenseToShow];
}

- (void)configurateUserDefaults {
    _defaults = [[NSUserDefaults alloc]initWithSuiteName:kAppGroupSharedContainer];

    NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];

    BOOL isFirst = ([kvStore boolForKey:@"first"] == NO ? YES : NO);
    if (isFirst) {
        [kvStore setBool:YES forKey:@"first"];
        
        [self updateNumberExpenseToShowWithValue:5];

        _numberExpenseToShow = 5;
    } else {
        _numberExpenseToShow = [_defaults integerForKey:kNumberExpensesToShowUserDefaultsKey];
    }
}

- (void)updateNumberExpenseToShowWithValue:(NSInteger)value {
    [_defaults setInteger:value forKey:kNumberExpensesToShowUserDefaultsKey];
    [_defaults synchronize];
}

#pragma mark - UITableView -

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 1) {
        return (_pickerViewVisible ? 163.0f : 0.0f);
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];

        if (!_pickerViewVisible) {
            [self showPickerView];
        } else {
            [self hidePickerView];
        }
        return;
    }
        // Also hide the date picker when tapped on any other row.
    [self hidePickerView];
}

#pragma mark - UIPickerView

- (void)showPickerView {
    NSIndexPath *numberExpenseIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:numberExpenseIndexPath];
    cell.detailTextLabel.textColor = cell.detailTextLabel.tintColor;

    [self.pickerView selectRow:_numberExpenseToShow - 1 inComponent:0 animated:NO];

    _pickerViewVisible = YES;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];

    self.pickerView.hidden = NO;
    self.pickerView.alpha = 0.0f;
    [UIView animateWithDuration:0.25
                     animations:^{
                         self.pickerView.alpha = 1.0f;
                     }];

    NSIndexPath *pickerViewIndexPath = [NSIndexPath indexPathForRow:numberExpenseIndexPath.row + 1 inSection:numberExpenseIndexPath.section];
    [self.tableView scrollToRowAtIndexPath:pickerViewIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
}

- (void)hidePickerView {
    if (_pickerViewVisible) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

            //Set default detailTextLabel textColor
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];

        UITableViewCell *defaultCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
        cell.detailTextLabel.textColor = [[defaultCell detailTextLabel] textColor];

        _pickerViewVisible = NO;
        [self.tableView beginUpdates];
        [self.tableView endUpdates];

        [UIView animateWithDuration:0.25
                         animations:^{
                             self.pickerView.alpha = 0.0f;
                         } completion:^(BOOL finished) {
                             self.pickerView.hidden = YES;
                         }];
    }
}

#pragma mark UIPickerViewDataSource

    // returns the number of 'columns' to display.
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

    // returns the # of rows in each component..
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 10;
}

#pragma mark UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [NSString stringWithFormat:@"%ld", (long)row + 1];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];

    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)row+1];

    _numberExpenseToShow = row + 1;
}

@end
