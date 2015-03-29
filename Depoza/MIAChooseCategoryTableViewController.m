//
//  ChooseCategoryTableViewController.m
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "MIAChooseCategoryTableViewController.h"
#import "CategoryData.h"

@implementation MIAChooseCategoryTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);
    NSParameterAssert(_titles);
}

#pragma mark - UITableView -
#pragma mark DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _titles.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"CategoryCell"];
    cell.textLabel.text = _titles[indexPath.row];

    if (![_originalCategoryName isEqualToString:cell.textLabel.text]) {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }

    return cell;
}

#pragma mark Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([_delegate respondsToSelector:@selector(chooseCategoryTableViewController:didFinishChooseCategory:)]) {
        [self.delegate chooseCategoryTableViewController:self didFinishChooseCategory:_titles[indexPath.row]];
    }
}

@end
