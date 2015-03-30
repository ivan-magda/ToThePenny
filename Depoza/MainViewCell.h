//
//  MainViewCell.h
//  Depoza
//
//  Created by Ivan Magda on 28.03.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

/*!
 * The default constant value of category label top space layout constraint equal to 6.
 */
extern const CGFloat DefaultCategoryLabelTopSpaceValue;

/*!
 * The increased constant value of category label top space layout contraint so that category label becomes vertical center in container.
 */
extern const CGFloat IncreasedCategoryLabelTopSpaceValue;

@interface MainViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *categoryLabelTopSpaceConstraint;

@property (nonatomic, weak) IBOutlet UILabel *categoryLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UILabel *amountLabel;
@property (nonatomic, weak) IBOutlet UIImageView *categoryIcon;


@end
