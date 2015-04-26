//
//  EditDescriptionViewController.m
//  Depoza
//
//  Created by Ivan Magda on 26.04.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "EditDescriptionViewController.h"

@interface EditDescriptionViewController () <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property (nonatomic, copy) NSString *expenseDescription;

@property (nonatomic, copy) EditDescriprionDidSaveWithCompletionHandler handler;

@end

@implementation EditDescriptionViewController {
    NSString *_textViewText;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationItem setHidesBackButton:YES];

    _textView.delegate = self;
    self.textView.text = _expenseDescription;
    [_textView becomeFirstResponder];
}

- (void)setExpenseDescription:(NSString *)expenseDescription withDidSaveCompletionHandler:(EditDescriprionDidSaveWithCompletionHandler)completionHandler {

    if (completionHandler) {
        self.handler = [completionHandler copy];
    }

    self.expenseDescription = expenseDescription;
}

#pragma mark - UITextViewDelegate -

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    _textViewText = [textView.text stringByReplacingCharactersInRange:range withString:text];

    return YES;
}

#pragma mark - IBActions -

- (IBAction)cancelBarButtonPressed:(UIBarButtonItem *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveBarButtonPressed:(UIBarButtonItem *)sender {
    _textViewText = _textView.text;

    self.handler(_textViewText);

    [self.navigationController popViewControllerAnimated:YES];
}

@end
