//
//  FrontViewController.m
//  Depoza
//
//  Created by Ivan Magda on 20.11.14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import "MainViewController.h"
#import "SWRevealViewController.h"

@interface MainViewController ()

@property (weak, nonatomic) IBOutlet UIBarButtonItem *revealBarButton;

@end

@implementation MainViewController

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    [self customSetUp];
}

- (void)customSetUp {
    self.revealBarButton.target = self.revealViewController;
    self.revealBarButton.action = @selector(revealToggle:);

    [self.view addGestureRecognizer:self.revealViewController.panGestureRecognizer];
}

@end