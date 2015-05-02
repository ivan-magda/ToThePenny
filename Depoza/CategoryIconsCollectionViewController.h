//
//  MIACollectionViewController.h
//  Depoza
//
//  Created by Ivan Magda on 30.03.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CategoryIconsCollectionViewController : UICollectionViewController

@property (nonatomic, copy) NSString *selectedIconName;

@property (nonatomic, copy, readonly) NSArray *iconNames;

@property (nonatomic, assign) BOOL isAddingNewCategoryMode;

@end
