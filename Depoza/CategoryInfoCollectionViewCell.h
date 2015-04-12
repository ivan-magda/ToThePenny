//
//  CustomCollectionCell.h
//  Depoza
//
//  Created by Ivan Magda on 23.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoryInfoCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UIImageView *categoryImage;
@property (nonatomic, weak) IBOutlet UILabel *amountLabel;

@end
