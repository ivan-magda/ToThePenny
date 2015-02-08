//
//  ExpenseData.h
//  Depoza
//
//  Created by Ivan Magda on 08.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class CategoryData;

@interface ExpenseData : NSManagedObject

@property (nonatomic, retain) NSNumber * amount;
@property (nonatomic, retain) NSNumber * categoryId;
@property (nonatomic, retain) NSDate * dateOfExpense;
@property (nonatomic, retain) NSString * descriptionOfExpense;
@property (nonatomic, retain) NSNumber * idValue;
@property (nonatomic, retain) CategoryData *category;

@end
