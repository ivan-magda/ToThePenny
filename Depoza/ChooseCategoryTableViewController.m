    //
    //  ChooseCategoryTableViewController.m
    //  Depoza
    //
    //  Created by Ivan Magda on 16.02.15.
    //  Copyright (c) 2015 Ivan Magda. All rights reserved.
    //

#import "ChooseCategoryTableViewController.h"
#import "CategoryIconsCollectionViewController.h"
#import "CategoryData+Fetch.h"

@implementation ChooseCategoryTableViewController {
    BOOL _isChangeIconPressed;
    NSString *_selectedCategoryName;
    NSDictionary *_categoriesIcons;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_titles && _iconName);

    _titles = [_titles sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    _categoriesIcons = [CategoryData getAllIconsNameInContext:_context];

    _selectedCategoryName = self.originalCategoryName;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    _isChangeIconPressed = NO;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (!_isChangeIconPressed) {
        if ([self.delegate respondsToSelector:@selector(chooseCategoryTableViewController:didFinishChooseCategoryName:andIconName:)]) {
            [self.delegate chooseCategoryTableViewController:self didFinishChooseCategoryName:_selectedCategoryName andIconName:_iconName];
        }
    }
}

#pragma mark - UITableView -
#pragma mark DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    }
    return _titles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        NSString *identifier = @"IconCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];

        if (cell == nil) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        cell.imageView.image = [UIImage imageNamed:_iconName];
        cell.textLabel.text = NSLocalizedString(@"Icon", @"ChooseCategoryVC icon label");
        cell.textLabel.font = [UIFont fontWithName:@".SFUIText-Light" size:17];

        return cell;
    } else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];
        cell.textLabel.text = _titles[indexPath.row];

        if (![_selectedCategoryName isEqualToString:cell.textLabel.text]) {
            cell.accessoryType = UITableViewCellAccessoryNone;
        } else {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }

        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && indexPath.row == 0) {
        return 54.0f;
    }
    return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (section == 0) {
        return NSLocalizedString(@"Change the icon of category.", @"ChooseCategoryVC header title for pick icon section");
    }
    return NSLocalizedString(@"Change the category of expense.", @"ChooseCategoryVC header title for change category section");
}

#pragma mark Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1) {
        _isChangeIconPressed  = NO;
        _selectedCategoryName = _titles[indexPath.row];
        _iconName = _categoriesIcons[_selectedCategoryName];

        [tableView reloadData];
    } else if (indexPath.section == 0) {
        _isChangeIconPressed = YES;
        [self performSegueWithIdentifier:@"ChangeIcon" sender:nil];
    }
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"ChangeIcon"]) {
        CategoryIconsCollectionViewController *controller = segue.destinationViewController;
        controller.selectedIconName = _iconName;
    }
}

- (IBAction)didChangeIcon:(UIStoryboardSegue *)unwindSegue {
    UIViewController *sourceVC = unwindSegue.sourceViewController;
    if ([sourceVC isKindOfClass:[CategoryIconsCollectionViewController class]]) {
        CategoryIconsCollectionViewController *controller = (CategoryIconsCollectionViewController *)sourceVC;
        self.iconName = controller.selectedIconName;

        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        cell.imageView.image = [UIImage imageNamed:_iconName];
    }
}

@end
