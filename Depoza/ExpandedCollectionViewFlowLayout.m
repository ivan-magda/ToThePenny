//
//  ExpandedCollectionViewFlowLayout.m
//  Depoza
//
//  Created by Ivan Magda on 02.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "ExpandedCollectionViewFlowLayout.h"

static const CGFloat kCollectionViewCellStandartHeight     = 64.0f;
static const CGFloat kCollectionViewCellStandartWidth      = 64.0f;
static const CGFloat kCollectionViewIphoneSixCellWidth     = 74.0f;
static const CGFloat kCollectionViewIphoneSixPlusCellWidth = 84.0f;

typedef NS_ENUM(NSInteger, DeviceType) {
    DeviceTypeUnknown,
    DeviceTypeBelowIphoneSix,
    DeviceTypeIphoneSix,
    DeviceTypeIphoneSixPlus
};

@implementation ExpandedCollectionViewFlowLayout

- (CGSize)collectionViewContentSize {
    NSInteger itemCount = [self.collectionView numberOfItemsInSection:0];
    NSInteger pages = ceil(itemCount / 8.0);

    CGFloat width = CGRectGetWidth(self.collectionView.bounds);
    CGFloat height = CGRectGetHeight(self.collectionView.bounds);

    return CGSizeMake(width * pages, height);
}

- (CGSize)itemSize {
    CGFloat width = CGFLOAT_MAX;
    DeviceType deviceType = [self deviceType];
    switch (deviceType) {
        case DeviceTypeBelowIphoneSix:
            width = kCollectionViewCellStandartWidth;
            break;
        case DeviceTypeIphoneSix:
            width = kCollectionViewIphoneSixCellWidth;
            break;
        case DeviceTypeIphoneSixPlus:
            width = kCollectionViewIphoneSixPlusCellWidth;
            break;
        default:
            NSAssert(NO, @"Device must be known");
            break;
    }
    CGFloat height = kCollectionViewCellStandartHeight;

    return CGSizeMake(width, height);
}

#pragma mark - Helper -

- (DeviceType)deviceType {
    CGFloat collectionViewWidth = CGRectGetWidth(self.collectionView.bounds);

    if (collectionViewWidth <= 320.0f) {
        return DeviceTypeBelowIphoneSix;
    } else if (collectionViewWidth > 320.0f &&
               collectionViewWidth <= 375.0f) {
        return DeviceTypeIphoneSix;
    } else if (collectionViewWidth > 320.0f &&
               collectionViewWidth <= 414.0f) {
        return DeviceTypeIphoneSixPlus;
    } else {
        return DeviceTypeUnknown;
    }
}

@end
