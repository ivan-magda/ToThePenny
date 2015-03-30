//
//  MIACollectionViewController.m
//  Depoza
//
//  Created by Ivan Magda on 30.03.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "MIACollectionViewController.h"

@interface MIACollectionViewController ()

@end

@implementation MIACollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_iconNames && _selectedIconName);
}

#pragma mark - UICollectionViewDataSource -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _iconNames.count;
}

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSString *iconName = _iconNames[indexPath.row];

    UIImageView *icon = (UIImageView *)[cell viewWithTag:5000];
    NSParameterAssert(icon);
    icon.image = [UIImage imageNamed:iconName];

    if ([iconName isEqualToString:_selectedIconName]) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionCenteredVertically | UICollectionViewScrollPositionCenteredHorizontally];

            //Background with Air Force Blue Color and corner radius
        cell.backgroundColor = [UIColor colorWithRed:0.33 green:0.55 blue:0.68 alpha:0.2];
        cell.layer.cornerRadius = icon.bounds.size.width / 3.0f;
        icon.clipsToBounds = YES;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionCell" forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"DidPickIcon"]) {
        UICollectionViewCell *cell = sender;
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        self.selectedIconName = _iconNames[indexPath.row];
    }
}

@end
