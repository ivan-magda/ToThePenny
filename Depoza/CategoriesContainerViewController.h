//
//  CategoriesContainerView.h
//  Depoza
//
//  Created by Ivan Magda on 23.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewControllerDelegate.h"
#import "CategoriesContainerViewControllerDelegate.h"

/*!
 * The default constant value of container view height constant equal to 175.0f.
 */
extern const CGFloat DefaultContainerViewHeightValue;

/*!
 * The reduced constant value of container view height constant equal to 106.0f.
 */
extern const CGFloat ReducedContainerViewHeightValue;

/*!
 * The default constant value of collection view height constant equal to 138.0f.
 */
extern const CGFloat DefaultCollectionViewHeightValue;

/*!
 * The reduced constant value of collection view height constant equal to 69.0f.
 */
extern const CGFloat ReducedCollectionViewHeightValue;

/*!
 * The default constant value of page control height constant equal to 37.0f.
 */
extern const CGFloat DefaultPageControlHeightValue;

extern NSString * const ContinuingActivityRepresentsSearchableCategoryNotification;

@interface CategoriesContainerViewController : UIViewController <MainViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeightConstraint;

@property (nonatomic, copy) NSArray *categories;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, strong) NSDate *timePeriod;

@property (nonatomic, strong) id <CategoriesContainerViewControllerDelegate>delegate;

- (NSInteger)numberOfPages;

@end
