//
//  AppAppearance.h
//  Depoza
//
//  Created by Ivan Magda on 16.09.15.
//  Copyright © 2015 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SmileTouchID/SmileAuthenticator.h>

@class UIColor;
@class UIViewController;

@interface AppConfiguration : NSObject

/*!
 * Strong blue color.
 */
@property (nonatomic, strong, readonly, nonnull) UIColor *mainColor;

@property (nonatomic, strong, readonly, nonnull) SmileAuthenticator *smileAuthenticator;
@property (nonatomic, strong, nullable) id<SmileAuthenticatorDelegate> smileAuthenticatorDelegate;

- (void)applyAppAppearance;

- (void)configurateSmileTouchIdWithRootViewController:(UIViewController * _Nonnull)rootViewController;

- (void)setUpKVNProgressConfiguration;

- (void)setUpIrate;

@end
