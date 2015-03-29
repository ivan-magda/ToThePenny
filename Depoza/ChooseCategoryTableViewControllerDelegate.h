//
//  ChooseCategoryTableViewControllerDelegate.h
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIAChooseCategoryTableViewController;
@class NSString;

@protocol MIAChooseCategoryTableViewControllerDelegate <NSObject>

- (void)chooseCategoryTableViewController:(MIAChooseCategoryTableViewController *)controller didFinishChooseCategory:(NSString *)category;

@end
