//
//  NSString+FormatAmount.h
//  Depoza
//
//  Created by Ivan Magda on 27.03.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (FormatAmount)

+ (NSString *)formatAmount:(NSNumber *)amount;

@end
