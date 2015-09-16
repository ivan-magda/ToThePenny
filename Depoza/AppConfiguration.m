//
//  AppAppearance.m
//  Depoza
//
//  Created by Ivan Magda on 16.09.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

#import "AppConfiguration.h"
#import <KVNProgress/KVNProgress.h>
@import UIKit;

@interface AppConfiguration ()

@property (nonatomic, strong, readwrite) UIColor *mainColor;

@end

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@implementation AppConfiguration

#pragma mark - Life Cycle -

- (instancetype)init {
    if (self = [super init]) {
        _smileAuthenticator = [SmileAuthenticator sharedInstance];
        //008CC7
        _mainColor = UIColorFromRGB(0x067AB5);
    }
    return self;
}

#pragma mark - Appearance -

- (void)applyAppAppearance {
    [[UINavigationBar appearance]setBarTintColor:_mainColor];
    [[UINavigationBar appearance]setTintColor:[UIColor whiteColor]];
    
    [[UINavigationBar appearance]setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName, [UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:21.0], NSFontAttributeName, nil]];
    
    [[UINavigationBar appearance]setTranslucent:NO];
    [[UITabBar appearance]setTranslucent:YES];
    
    [[UITabBar appearance]setTintColor:_mainColor];
    
    [[UIBarButtonItem appearance]setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:17]} forState:UIControlStateNormal];
    
    [[UISegmentedControl appearance]setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Light" size:14]} forState:UIControlStateNormal];
    
    //When contained in UISearchBar
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor whiteColor]];
    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil]setDefaultTextAttributes:@{                  NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Light" size:14]}];
}

#pragma mark - SmileAuthenticator -

- (void)setSmileAuthenticatorDelegate:(id<SmileAuthenticatorDelegate>)smileAuthenticatorDelegate {
    if (_smileAuthenticatorDelegate != smileAuthenticatorDelegate) {
        _smileAuthenticatorDelegate = smileAuthenticatorDelegate;
        _smileAuthenticator.delegate = smileAuthenticatorDelegate;
    }
}

- (void)configurateSmileTouchIdWithRootViewController:(UIViewController *)rootViewController {
    _smileAuthenticator.rootVC = rootViewController;
    _smileAuthenticator.passcodeDigit = 4;
    _smileAuthenticator.tintColor = _mainColor;
    _smileAuthenticator.touchIDIconName = @"TouchIDIcon.jpg";
    _smileAuthenticator.navibarTranslucent = NO;
}

#pragma mark - KVNProgress -

- (void)setKVNProgressConfiguration {
    KVNProgressConfiguration *configuration = [KVNProgressConfiguration defaultConfiguration];
    configuration.minimumSuccessDisplayTime = 0.75f;
    configuration.minimumErrorDisplayTime   = 1.0f;
    
    configuration.statusFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:19.0f];
    configuration.circleSize = 100.0f;
    configuration.lineWidth = 1.0f;
    
    [KVNProgress setConfiguration:configuration];
}


@end
