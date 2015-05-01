//
//  CustomTabBarController.m
//  Depoza
//
//  Created by Ivan Magda on 01.05.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CustomTabBarController.h"

@interface TransitioningObject : NSObject <UIViewControllerAnimatedTransitioning>

@property (nonatomic, weak) CustomTabBarController *tabBarController;

@end

@implementation TransitioningObject

- (NSTimeInterval)transitionDuration:(id <UIViewControllerContextTransitioning>)transitionContext {
    return 0.25;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
        // Get the "from" and "to" views
    UIView *fromView = [transitionContext viewForKey:UITransitionContextFromViewKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIView *toView = [transitionContext viewForKey:UITransitionContextToViewKey];
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];

    [transitionContext.containerView addSubview:fromView];
    [transitionContext.containerView addSubview:toView];

    __block NSInteger fromViewControllerIndex;
    __block NSInteger toViewControllerIndex;
    [self.tabBarController.viewControllers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIViewController *controller = obj;
        if ([controller isEqual:fromViewController]) {
            fromViewControllerIndex = idx;
        } else if ([controller isEqual:toViewController]) {
            toViewControllerIndex = idx;
        }
    }];

        // 1 will slide left, -1 will slide right
    CGFloat directionInteger;
    if (fromViewControllerIndex < toViewControllerIndex) {
        directionInteger = 1;
    } else {
        directionInteger = -1;
    }
        //The "to" view with start "off screen" and slide left pushing the "from" view "off screen"
    toView.frame = CGRectMake(directionInteger * CGRectGetWidth(toView.frame), 0, CGRectGetWidth(toView.frame), CGRectGetHeight(toView.frame));
    CGRect fromNewFrame = CGRectMake(-1 * directionInteger * CGRectGetWidth(fromView.frame), 0, CGRectGetWidth(fromView.frame), CGRectGetHeight(fromView.frame));

    [UIView animateWithDuration:[self transitionDuration:transitionContext] animations:^{
        toView.frame = fromView.frame;
        fromView.frame = fromNewFrame;
    } completion:^(BOOL finished) {
            // update internal view - must always be called
        [transitionContext completeTransition:YES];
    }];
}

@end


@implementation CustomTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.delegate = self;
}

- (id<UIViewControllerAnimatedTransitioning>)tabBarController:(UITabBarController *)tabBarController animationControllerForTransitionFromViewController:(UIViewController *)fromVC toViewController:(UIViewController *)toVC {
    TransitioningObject *transitioningObject = [TransitioningObject new];
        // set the reference to self so it can get the indexes of the to and from view controllers
    transitioningObject.tabBarController = self;
    return transitioningObject;
}

@end
