//
//  CategoriesContainerView.h
//  Depoza
//
//  Created by Ivan Magda on 23.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MainViewControllerDelegate.h"

@interface MIACategoriesContainerViewController : UIViewController <MIAMainViewControllerDelegate>

@property (nonatomic, copy) NSArray *categories;

@end
