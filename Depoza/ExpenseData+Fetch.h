//
//  ExpenseData+Fetch.h
//  Depoza
//
//  Created by Ivan Magda on 17.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "ExpenseData.h"

@class NSManagedObjectContext;

@interface ExpenseData (Fetch)

+ (NSInteger)nextId;

+ (NSArray *)expensesWithEqualDayWithDate:(NSDate *)date managedObjectContext:(NSManagedObjectContext *)context;

@end
