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
#import "NSString+FormatAmount.h"

@interface CategoriesContainerViewController ()

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;

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

    cell.categoryImage.image = [UIImage imageNamed:categoryInfo.iconName];
    cell.amountLabel.text = [NSString formatAmount:categoryInfo.amount];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CategoryInfoCollectionViewCell *cell = (CategoryInfoCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionCell" forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];

    int pages = floor(_collectionView.contentSize.width / _collectionView.frame.size.width) + 1;
    [self.pageControl setNumberOfPages:pages];

    return cell;
}

#pragma mark - UICollectionViewDelegate -

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Select %ld", (long)indexPath.row);
}

#pragma mark - UIScrollVewDelegate for UIPageControl

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat pageWidth = _collectionView.frame.size.width;
    float currentPage = _collectionView.contentOffset.x / pageWidth;

    if (0.0f != fmodf(currentPage, 1.0f)) {
        _pageControl.currentPage = currentPage + 1;
    } else {
        _pageControl.currentPage = currentPage;
    }
}

#pragma mark - IBActions -

- (IBAction)pageControlDidChangeValue:(UIPageControl *)sender {
    UIPageControl *pageControl = sender;
    CGFloat pageWidth = CGRectGetWidth(_collectionView.frame);
    CGPoint scrollTo = CGPointMake(pageWidth * pageControl.currentPage, 0);
    [self.collectionView setContentOffset:scrollTo animated:YES];
}


@end
