//
//  EditDescriptionViewController.h
//  Depoza
//
//  Created by Ivan Magda on 26.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^EditDescriprionDidSaveWithCompletionHandler)(NSString *text);

@interface EditDescriptionViewController : UIViewController

- (void)setExpenseDescription:(NSString *)expenseDescription withDidSaveCompletionHandler:(EditDescriprionDidSaveWithCompletionHandler)completionHandler;

@end
