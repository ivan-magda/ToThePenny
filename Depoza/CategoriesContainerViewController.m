//
//  CategoriesContainerView.m
//  Depoza
//
//  Created by Ivan Magda on 23.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

    //ViewController's
#import "CategoriesContainerViewController.h"
#import "SelectedCategoryTableViewController.h"
#import "ExpandedCollectionViewFlowLayout.h"
    //View
#import "CategoryInfoCollectionViewCell.h"
    //CoreData
#import "CategoriesInfo.h"
    //Categories
#import "NSString+FormatAmount.h"
#import "NSDate+FirstAndLastDaysOfMonth.h"

const CGFloat DefaultContainerViewHeightValue = 175.0f;
const CGFloat ReducedContainerViewHeightValue = 106.0f;

const CGFloat DefaultCollectionViewHeightValue = 138.0f;
const CGFloat ReducedCollectionViewHeightValue = 69.0f;

const CGFloat DefaultPageControlHeightValue = 37.0f;

NSString * const ContinuingActivityRepresentsSearchableCategoryNotification = @"ContinuingActivityRepresentsSearchableCategory";

static NSString * const kCategorySelectedSegueIdentifier = @"CategorySelected";

@interface CategoriesContainerViewController ()

@property (nonatomic, weak) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *pageControlHeightConstraint;

@end


@implementation CategoriesContainerViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_managedObjectContext);
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(presentSearchedCategoryFromSpotlight:) name:ContinuingActivityRepresentsSearchableCategoryNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Private -

- (NSInteger)numberOfPages {
    return self.pageControl.numberOfPages;
}

- (void)presentSearchedCategoryFromSpotlight:(NSNotification *)notification {
    CategoryData *category = (CategoryData *)notification.object;
    [self performSegueWithIdentifier:kCategorySelectedSegueIdentifier sender:[CategoriesInfo categoryInfoFromCategoryData:category]];
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:kCategorySelectedSegueIdentifier]) {
        SelectedCategoryTableViewController *controller = segue.destinationViewController;
        controller.managedObjectContext = _managedObjectContext;

        CategoriesInfo *category = nil;
        if ([sender isKindOfClass:[CategoryInfoCollectionViewCell class]]) {
            NSIndexPath *indexPath = [self.collectionView indexPathForCell:sender];

            category = _categories[indexPath.row];
        } else if ([sender isKindOfClass:[CategoriesInfo class]]) {
            category = (CategoriesInfo *)sender;
        }
        [self.delegate categoriesContainerViewController:self didChooseCategory:category];
        
        controller.selectedCategory = category;
        controller.timePeriodDates = [_timePeriod getFirstAndLastDatesFromMonth];
    }
}

#pragma mark - MainViewControllerDelegate -

- (void)updateCategories:(NSArray *)categoriesData {
    self.pageControl.hidden = (self.collectionViewHeightConstraint.constant == 0.0f);

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"amount" ascending:NO];
    self.categories = [categoriesData sortedArrayUsingDescriptors:@[sortDescriptor]];

    [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
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

    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    NSInteger pages = ceil(itemCount / 8.0);
    [self.pageControl setNumberOfPages:pages];

    self.pageControlHeightConstraint.constant = (pages == 1 ? 0.0f : DefaultPageControlHeightValue);
    self.pageControl.hidden = pages == 1;

    return cell;
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
