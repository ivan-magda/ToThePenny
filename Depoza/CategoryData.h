//
//  CategoryData.h
//  Depoza
//
//  Created by Ivan Magda on 28.03.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class ExpenseData;

@interface CategoryData : NSManagedObject

@property (nonatomic, retain) NSNumber * idValue;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * iconName;
@property (nonatomic, retain) NSSet *expense;
@end

@interface CategoryData (CoreDataGeneratedAccessors)

- (void)addExpenseObject:(ExpenseData *)value;
- (void)removeExpenseObject:(ExpenseData *)value;
- (void)addExpense:(NSSet *)values;
- (void)removeExpense:(NSSet *)values;

@end
