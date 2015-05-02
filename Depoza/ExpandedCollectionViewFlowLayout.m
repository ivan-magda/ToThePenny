//
//  ExpandedCollectionViewFlowLayout.m
//  Depoza
//
//  Created by Ivan Magda on 02.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "ExpandedCollectionViewFlowLayout.h"

@implementation ExpandedCollectionViewFlowLayout

- (CGSize)collectionViewContentSize {
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    NSInteger pages = ceil(itemCount / 8.0);

    return CGSizeMake(320 * pages, self.collectionView.frame.size.height);
}

@end
