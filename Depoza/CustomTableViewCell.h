//
//  CustomTableViewCell.h
//  Depoza
//
//  Created by Ivan Magda on 09.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *descriptionLabel;
@property (nonatomic, strong) IBOutlet UILabel *detailsLabel;
@property (nonatomic, strong) IBOutlet UILabel *categoryTitleLabel;

@end
