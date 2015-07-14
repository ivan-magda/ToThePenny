//
//  BouncePresentAnimationController.m
//  Depoza
//
//  Created by Ivan Magda on 14.07.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "BouncePresentAnimationController.h"

@implementation BouncePresentAnimationController

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.4;
}

- (void)animateTransition:(id <UIViewControllerContextTransitioning>)transitionContext {
    UIViewController *toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController *fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    CGRect finalFrame = [transitionContext finalFrameForViewController:toViewController];
    
    
    UIView *containerView = [transitionContext containerView];
    
    [containerView addSubview:toViewController.view];
    
    toViewController.view.frame = finalFrame;
    
    NSTimeInterval duration = [self transitionDuration:transitionContext];
    
    CAKeyframeAnimation *bounceAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform.scale"];
    
    bounceAnimation.duration = duration;
    
    bounceAnimation.values = @[@0.7, @1.2, @0.9, @1.0];
    bounceAnimation.keyTimes = @[@0.0, @0.334, @0.666, @1.0];
    
    bounceAnimation.timingFunctions = @[
                                        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut],
                                        [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
    
    [UIView animateWithDuration:duration animations:^{
        [toViewController.view.layer addAnimation:bounceAnimation forKey:@"bounceAnimation"];
    } completion:^(BOOL finished) {
        fromViewController.view.alpha = 1.0;
        [transitionContext completeTransition:YES];
    }];
}

@end
