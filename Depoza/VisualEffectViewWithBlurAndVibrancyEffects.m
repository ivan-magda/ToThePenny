//
//  VisualEffectViewWithBlurAndVibrancyEffects.m
//  Depoza
//
//  Created by Ivan Magda on 16.09.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

#import "VisualEffectViewWithBlurAndVibrancyEffects.h"

@implementation VisualEffectViewWithBlurAndVibrancyEffects

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setUpVisualEffectViewWithBlurAndVibrancyEffectsFromFrame:frame];
    }
    return self;
}

- (void)setUpVisualEffectViewWithBlurAndVibrancyEffectsFromFrame:(CGRect)frame {
    // Blur effect
    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
    UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
    [blurEffectView setFrame:frame];
    
    // Vibrancy effect
    UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
    UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc]initWithEffect:vibrancyEffect];
    [vibrancyEffectView setFrame:frame];
    
    // Label for vibrant text
    UILabel *vibrantLabel = [UILabel new];
    [vibrantLabel setText:NSLocalizedString(@"ToThePenny", @"App name for vibrant label")];
    [vibrantLabel setFont:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:21.0]];
    [vibrantLabel sizeToFit];
    
    CGPoint location = CGPointMake(frame.origin.x + (frame.size.width / 2 ), frame.origin.y + (frame.size.height / 2));
    location.y = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) + 22.0f;
    [vibrantLabel setCenter:location];
    
    // Add label to the vibrancy view
    [[vibrancyEffectView contentView]addSubview:vibrantLabel];
    
    // Add the vibrancy view to the blur view
    [[blurEffectView contentView]addSubview:vibrancyEffectView];
    
    [[self contentView]addSubview:blurEffectView];
}

@end
