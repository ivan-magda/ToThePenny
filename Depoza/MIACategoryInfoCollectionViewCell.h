//
//  CustomCollectionCell.h
//  Depoza
//
//  Created by Ivan Magda on 23.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MIACategoryInfoCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *categoryNameLabel;
@property (nonatomic, weak) IBOutlet UILabel *amountLabel;

@end
