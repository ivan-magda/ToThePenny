//
//  AppAppearance.m
//  Depoza
//
//  Created by Ivan Magda on 16.09.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

#import "AppConfiguration.h"
#import <KVNProgress/KVNProgress.h>
#import <iRate.h>
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
     [NSDictionary dictionaryWithObjectsAndKeys:[UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0], NSForegroundColorAttributeName, [UIFont boldSystemFontOfSize:18.0], NSFontAttributeName, nil]];
    
    [[UINavigationBar appearance]setTranslucent:NO];
    [[UITabBar appearance]setTranslucent:YES];
    
    [[UITabBar appearance]setTintColor:_mainColor];
    
    [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor whiteColor]];
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

- (void)setUpKVNProgressConfiguration {
    KVNProgressConfiguration *configuration = [KVNProgressConfiguration defaultConfiguration];
    configuration.minimumSuccessDisplayTime = 0.75f;
    configuration.minimumErrorDisplayTime   = 1.0f;
    
    configuration.statusFont = [UIFont systemFontOfSize:19.0];
    configuration.circleSize = 100.0f;
    configuration.lineWidth = 1.0f;
    
    [KVNProgress setConfiguration:configuration];
}

#pragma mark - iRate -

- (void)setUpIrate {
    [iRate sharedInstance].appStoreID = 994476075;
    [iRate sharedInstance].previewMode = NO;
}


@end
