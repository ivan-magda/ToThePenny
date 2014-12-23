//
//  ExpenseData.h
//  Depoza
//
//  Created by Ivan Magda on 22/12/14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface ExpenseData : NSManagedObject

@property (nonatomic, retain) NSNumber * sumOfExpense;
@property (nonatomic, retain) NSString * category;
@property (nonatomic, retain) NSString * descriptionOfExpense;
@property (nonatomic, retain) NSDate * dateOfExpense;

@end
