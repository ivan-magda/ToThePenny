//
//  PieChartTableViewCell.h
//  Depoza
//
//  Created by Ivan Magda on 11.07.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PieChartTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIView *coloredCategoryView;
@property (weak, nonatomic) IBOutlet UILabel *categoryTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *amountLabel;
@property (weak, nonatomic) IBOutlet UILabel *percentLabel;
@property (weak, nonatomic) IBOutlet UIImageView *categoryIcon;

@end
