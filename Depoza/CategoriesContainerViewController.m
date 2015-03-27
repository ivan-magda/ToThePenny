//
//  CategoriesContainerView.m
//  Depoza
//
//  Created by Ivan Magda on 23.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //View
#import "CategoriesContainerViewController.h"
#import "CategoryInfoCollectionViewCell.h"
    //CoreData
#import "CategoriesInfo.h"

static const CGFloat kCellHeight = 46.0f;

@interface CategoriesContainerViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@end


@implementation CategoriesContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

#pragma mark - MainViewControllerDelegate -

- (void)updateCategories:(NSArray *)categoriesData {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"amount" ascending:NO];
    self.categories = [categoriesData sortedArrayUsingDescriptors:@[sortDescriptor]];
    [self.collectionView reloadData];
}

- (void)mainViewController:(MainViewController *)mainViewController didLoadCategoriesInfo:(NSArray *)categoriesData {
    [self updateCategories:categoriesData];
}

- (void)mainViewController:(MainViewController *)mainViewController didUpdateCategoriesInfo:(NSArray *)categoriesData {
    [self updateCategories:categoriesData];
}

#pragma mark - UICollectionViewDataSource -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (self.categories) {
        return [self.categories count];
    } else {
        return 0;
    }
}

- (void)configureCell:(CategoryInfoCollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    CategoriesInfo *categoryInfo = _categories[indexPath.row];

    cell.categoryNameLabel.text = categoryInfo.title;
    cell.amountLabel.text = [NSString stringWithFormat:@"%@", categoryInfo.amount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CategoryInfoCollectionViewCell *cell = (CategoryInfoCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionCell" forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

#pragma mark - UICollectionViewDelegateFlowLayout - 

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    CategoriesInfo *categoryInfo = _categories[indexPath.row];
    NSString *categoryName = categoryInfo.title;
    NSString *amount = [NSString stringWithFormat:@"%@", categoryInfo.amount];

    CGSize size = [((categoryName.length > amount.length) ? categoryName : amount) sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:17]}];
    size.width = roundf(size.width + 0.5f);
    size.height = kCellHeight;

    return size;
}

#pragma mark - UICollectionViewDelegate -

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Select %ld", (long)indexPath.row);
}


@end
