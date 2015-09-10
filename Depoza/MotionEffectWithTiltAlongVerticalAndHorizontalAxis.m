//
// Created by Ivan Magda on 10.09.15.
// Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "MotionEffectWithTiltAlongVerticalAndHorizontalAxis.h"
#import <UIKit/UIKit.h>

@implementation MotionEffectWithTiltAlongVerticalAndHorizontalAxis

+ (void)addMotionEffectToView:(UIView *)view magnitude:(CGFloat)magnitude {
    UIInterpolatingMotionEffect *xMotion = [[UIInterpolatingMotionEffect alloc]
            initWithKeyPath:@"center.x"
                       type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    xMotion.minimumRelativeValue = @(-magnitude);
    xMotion.maximumRelativeValue = @(magnitude);

    UIInterpolatingMotionEffect *yMotion = [[UIInterpolatingMotionEffect alloc]
            initWithKeyPath:@"center.y"
                       type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    yMotion.minimumRelativeValue = @(-magnitude);
    yMotion.maximumRelativeValue = @(magnitude);

    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[xMotion, yMotion];
    [view addMotionEffect:group];
}

@end