//
//  CategoryData+Fetch.m
//  Depoza
//
//  Created by Ivan Magda on 16.02.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoryData+Fetch.h"

@implementation CategoryData (Fetch)

+ (CategoryData *)categoryFromTitle:(NSString *)category context:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];

    NSExpression *title = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(title))];
    NSExpression *categoryName = [NSExpression expressionForConstantValue:category];
    NSPredicate *predicate = [NSComparisonPredicate
                              predicateWithLeftExpression:title
                              rightExpression:categoryName
                              modifier:NSDirectPredicateModifier
                              type:NSEqualToPredicateOperatorType
                              options:0];
    fetchRequest.predicate = predicate;

    NSError *error;
    NSArray *foundCategory = [context executeFetchRequest:fetchRequest error:&error];
    if (error) {
        NSLog(@"***Error: %@", [error localizedDescription]);
    }

    NSParameterAssert([foundCategory count] == 1);
    NSParameterAssert([[foundCategory firstObject]isKindOfClass:[CategoryData class]]);

    return [foundCategory firstObject];
}

@end
