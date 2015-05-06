//
//  FoundExpenseCell.h
//  Depoza
//
//  Created by Ivan Magda on 06.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FoundExpenseCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *categoryTitleLabel;
@property (nonatomic, weak) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, weak) IBOutlet UILabel *amountLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *amountLabelTrailingSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *dateLabelTrailingSpaceConstraint;

@end
