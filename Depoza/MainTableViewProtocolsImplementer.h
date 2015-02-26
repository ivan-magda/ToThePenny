//
//  MainTableViewProtocolsImplementer.h
//  Depoza
//
//  Created by Ivan Magda on 26.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UITableView.h>
#import <CoreData/NSFetchedResultsController.h>

@interface MainTableViewProtocolsImplementer : NSObject <UITableViewDataSource, UITableViewDelegate, NSFetchedResultsControllerDelegate>

@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

- (instancetype)initWithTableView:(UITableView *)tableView fetchedResultsController:(NSFetchedResultsController *)fetchedResultsController;

@end
