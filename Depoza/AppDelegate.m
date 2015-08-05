    //
    //  AppDelegate.m
    //  Depoza
    //
    //  Created by Ivan Magda on 20.11.14.
    //  Copyright (c) 2014 Ivan Magda. All rights reserved.
    //

    //AppDelegate
#import "AppDelegate.h"
    //Crashlytics
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
    //ViewControllers
#import "CustomTabBarController.h"
#import "MainViewController.h"
#import "SearchTableViewController.h"
#import "DetailExpenseTableViewController.h"
#import "SettingsTableViewController.h"
#import <KVNProgress/KVNProgress.h>
    //CoreData
#import "ExpenseData+Fetch.h"
#import "CategoryData+Fetch.h"
#import "Fetch.h"
    //iRate
#import "iRate.h"
    //TouchID
#import <SmileTouchID/SmileAuthenticator.h>

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

typedef void(^SmileTouchIdUserSuccessAuthenticationBlock)();

static NSString * const kAppGroupSharedContainer = @"group.com.vanyaland.depoza";
static NSString * const kAddExpenseOnStartupKey = @"AddExpenseOnStartup";
static NSString * const kLoginWithTouchId = @"LoginWithTouchId";
static NSString * const kDetailViewControllerPresentingFromExtensionKey = @"DetailViewPresenting";
static NSString * const kSmileTouchIdUserSuccessAuthenticationNotification = @"smileTouchIdUserSuccessAuthentication";

NSString * const StatusBarTappedNotification = @"statusBarTappedNotification";

@interface AppDelegate () <SmileAuthenticatorDelegate>

@property (nonatomic, strong) UIVisualEffectView *visualEffectViewWithBlurAndVibrancyEffects;

@property (nonatomic, copy) SmileTouchIdUserSuccessAuthenticationBlock successAuthenticationHandler;

@end

@implementation AppDelegate {
    CustomTabBarController *_tabBarController;
    MainViewController *_mainViewController;
    SearchTableViewController *_allExpensesTableViewController;
    SettingsTableViewController *_settingsTableViewController;

    NSUserDefaults *_appGroupUserDefaults;
    
    UIColor *_mainColor;
    
    BOOL _authViewControllerPresented;
    BOOL _userSuccessAuthentication;
    BOOL _visualEffectViewWithBlurAndVibrancyEffectsPresented;
}

#pragma mark - Persistent Stack

- (void)spreadManagedObjectContext {
    _tabBarController = (CustomTabBarController *)self.window.rootViewController;

        //Get the MainViewController and set it's as a observer for creating context
    UINavigationController *navigationController = (UINavigationController *)_tabBarController.viewControllers[0];
    _mainViewController = (MainViewController *)navigationController.viewControllers[0];

        //Get the AllExpensesViewController
    navigationController = (UINavigationController *)_tabBarController.viewControllers[1];
    _allExpensesTableViewController = (SearchTableViewController *)navigationController.viewControllers[0];

        //Get the SettingsTableViewController
    navigationController = (UINavigationController *)_tabBarController.viewControllers[2];
    _settingsTableViewController = (SettingsTableViewController *)navigationController.viewControllers[0];

    NSParameterAssert(_managedObjectContext);
    _mainViewController.managedObjectContext = _managedObjectContext;
    _allExpensesTableViewController.managedObjectContext = _managedObjectContext;
    _settingsTableViewController.managedObjectContext = _managedObjectContext;
}

- (NSURL *)storeURL {
    NSURL *documentsDirectory = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:NULL];
    return [documentsDirectory URLByAppendingPathComponent:@"DataStore.sqlite"];
}

- (NSURL*)modelURL {
    return [[NSBundle mainBundle] URLForResource:@"DataModel" withExtension:@"momd"];
}

#pragma mark PersistenceDelegate

- (void)persistenceStore:(Persistence *)persistence didChangeNotification:(NSNotification *)notification {
    [_mainViewController updateUserInterfaceWithNewFetch:YES];
}

- (void)persistenceStore:(Persistence *)persistence didImportUbiquitousContentChanges:(NSNotification *)notification {
    [_mainViewController updateUserInterfaceWithNewFetch:NO];
}

- (void)persistenceStore:(Persistence *)persistence willChangeNotification:(NSNotification *)notification {
    BOOL animated = YES;
    [_mainViewController.navigationController popToRootViewControllerAnimated:animated];
    [_allExpensesTableViewController.navigationController popToRootViewControllerAnimated:animated];
    [_settingsTableViewController.navigationController popToRootViewControllerAnimated:animated];
}

#pragma mark - KVNProgress

- (void)setKVNDisplayTime {
    KVNProgressConfiguration *configuration = [KVNProgressConfiguration defaultConfiguration];
    configuration.minimumSuccessDisplayTime = 0.75f;
    configuration.minimumErrorDisplayTime   = 1.0f;

    configuration.statusFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:19.0f];
    configuration.circleSize = 100.0f;
    configuration.lineWidth = 1.0f;

    [KVNProgress setConfiguration:configuration];
}

#pragma mark - UI -

- (void)customiseAppearance {
    _mainColor = UIColorFromRGB(0x067AB5);
    //008CC7
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

#pragma mark - SmileTouchID -

- (void)configurateSmileTouchId {
    NSParameterAssert(_tabBarController != nil);
    
    [SmileAuthenticator sharedInstance].delegate = self;
    [SmileAuthenticator sharedInstance].rootVC = self.window.rootViewController;
    
    [SmileAuthenticator sharedInstance].passcodeDigit = 4;
    [SmileAuthenticator sharedInstance].tintColor = _mainColor;
    [SmileAuthenticator sharedInstance].touchIDIconName = @"TouchIDIcon.jpg";
    [SmileAuthenticator sharedInstance].navibarTranslucent = NO;
}

#pragma mark - AppDelegate -

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [Fabric with:@[CrashlyticsKit]];

    [self customiseAppearance];

    self.persistence = [[Persistence alloc]initWithStoreURL:self.storeURL modelURL:self.modelURL];
    self.managedObjectContext = self.persistence.managedObjectContext;
    self.persistence.delegate = self;

    [self spreadManagedObjectContext];
    [self setKVNDisplayTime];
    [self configurateSmileTouchId];

    _appGroupUserDefaults = [[NSUserDefaults alloc]initWithSuiteName:kAppGroupSharedContainer];
    
    [iRate sharedInstance].appStoreID = 994476075;
    [iRate sharedInstance].previewMode = NO;

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (_visualEffectViewWithBlurAndVibrancyEffectsPresented) {
        [self hideVisualEffectViewWithBlurAndVibrancyEffects];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application {
    if (!_authViewControllerPresented) {
        [self presentVisualEffectViewWithBlurAndVibrancyEffects];
    }
    
    [Fetch updateTodayExpensesDictionary:self.managedObjectContext];
    [[NSUbiquitousKeyValueStore defaultStore]synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self hideVisualEffectViewWithBlurAndVibrancyEffects];
    
    if ([_appGroupUserDefaults boolForKey:kDetailViewControllerPresentingFromExtensionKey]) {
        _tabBarController.selectedIndex = 0;
        
        [_appGroupUserDefaults setBool:NO forKey:kDetailViewControllerPresentingFromExtensionKey];
        [_appGroupUserDefaults synchronize];
        
        if (_mainViewController.isAddExpensePresenting) {
            [_mainViewController dismissViewControllerAnimated:YES completion:nil];
        }
    } else if ([[NSUserDefaults standardUserDefaults]boolForKey:kAddExpenseOnStartupKey]) {
        _tabBarController.selectedIndex = 0;
        
        if (_mainViewController.isAddExpensePresenting && ![SmileAuthenticator hasPassword]) {
            return;
        }
        
        if (_mainViewController.isAddExpensePresenting) {
            [_mainViewController dismissViewControllerAnimated:YES completion:nil];
            _mainViewController.isAddExpensePresenting = NO;
        }
        
        [_mainViewController.navigationController popToRootViewControllerAnimated:YES];
        [_mainViewController presentAddExpenseViewControllerIfNeeded];
    }
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    NSString *query = url.query;
    if (query != nil) {
        if ([query hasPrefix:@"q="]) {
                // If we have a query string, strip out the "q=" part so we're just left with the identifier
            NSRange range = [query rangeOfString:@"q="];
            NSString *identifier = [query stringByReplacingOccurrencesOfString:@"^q=" withString:@"" options:NSRegularExpressionSearch range:range];

            _tabBarController.selectedIndex = 0;

            [_appGroupUserDefaults setBool:NO forKey:kDetailViewControllerPresentingFromExtensionKey];
            [_appGroupUserDefaults synchronize];

            ExpenseData *selectedExpense = [ExpenseData getExpenseFromIdValue:identifier.integerValue inManagedObjectContext:_managedObjectContext];

                //Manage navigation stack of MainViewControler navigationController
            NSInteger numberControllers = [_mainViewController.navigationController viewControllers].count;
            if (numberControllers > 1) {
                UIViewController *viewController = [[_mainViewController.navigationController viewControllers]objectAtIndex:1];
                if ([viewController isKindOfClass:[DetailExpenseTableViewController class]]) {
                    DetailExpenseTableViewController *controller = [[_mainViewController.navigationController viewControllers]objectAtIndex:1];
                    if ([controller.expenseToShow isEqual:selectedExpense]) {
                        return YES;
                    }
                }
                [_mainViewController.navigationController popToRootViewControllerAnimated:YES];
            }

            __weak MainViewController *weakMainVC = _mainViewController;
            if (_mainViewController.isAddExpensePresenting) {
                if ([self isNeedForWaitingAuthenticator]) {
                    self.successAuthenticationHandler = [^{
                        [weakMainVC dismissViewControllerAnimated:YES completion:nil];
                        [weakMainVC performSegueWithIdentifier:@"MoreInfo" sender:selectedExpense];
                    } copy];
                } else {
                    [_mainViewController dismissViewControllerAnimated:YES completion:^{
                        [weakMainVC performSegueWithIdentifier:@"MoreInfo" sender:selectedExpense];
                    }];
                }
                
                return YES;
            }

            if (_mainViewController.isSelectMonthIsPresenting) {
                [_mainViewController dismissSelectMonthViewController];
            }

            _mainViewController.isShowExpenseDetailFromExtension = YES;
            
            if ([self isNeedForWaitingAuthenticator]) {
                self.successAuthenticationHandler = [^{
                    [weakMainVC performSegueWithIdentifier:@"MoreInfo" sender:selectedExpense];
                } copy];
                
                return YES;
            }
            
            [_mainViewController performSegueWithIdentifier:@"MoreInfo" sender:selectedExpense];
            
            return YES;
        }
    }
    
    return NO;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [[NSUbiquitousKeyValueStore defaultStore]synchronize];
    [_appGroupUserDefaults synchronize];
    
    [self.persistence saveContext];
    [self.persistence removePersistentStoreNotificationSubscribes];
}

#pragma mark - StatusBarTouchTracking -

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

    CGPoint location = [[[event allTouches]anyObject]locationInView:[self window]];
    CGRect statusBarFrame = [UIApplication sharedApplication].statusBarFrame;

    if (CGRectContainsPoint(statusBarFrame, location)) {
        [self statusBarTouchedAction];
    }
}

- (void)statusBarTouchedAction {
    [[NSNotificationCenter defaultCenter]postNotificationName:StatusBarTappedNotification
                                                        object:nil];
}

#pragma mark - SmileAuthenticatorDelegate -

- (void)updateTouchIdState:(BOOL)use {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:use forKey:kLoginWithTouchId];
    [userDefaults synchronize];
}

- (void)userTurnPasswordOn {
    [self updateTouchIdState:YES];
}

- (void)userTurnPasswordOff {
    [self updateTouchIdState:NO];
}

- (void)AuthViewControllerDismssed {
    _authViewControllerPresented = NO;
    
    if (_userSuccessAuthentication) {
        _userSuccessAuthentication = NO;
        
        [[NSNotificationCenter defaultCenter]postNotificationName:kSmileTouchIdUserSuccessAuthenticationNotification object:nil];

        if (self.successAuthenticationHandler) {
            self.successAuthenticationHandler();
            self.successAuthenticationHandler = nil;
        }
    }
}

- (void)AuthViewControllerPresented {
    _authViewControllerPresented = YES;
}

- (void)userSuccessAuthentication {
    _userSuccessAuthentication = YES;
}

- (void)userFailAuthenticationWithCount:(NSInteger)failCount {
    _userSuccessAuthentication = NO;
}

- (BOOL)isNeedForWaitingAuthenticator {
    return ([SmileAuthenticator hasPassword] && !_visualEffectViewWithBlurAndVibrancyEffectsPresented);
}

#pragma mark - UIVisualEffectView -

- (UIVisualEffectView *)visualEffectViewWithBlurAndVibrancyEffects {
    if (_visualEffectViewWithBlurAndVibrancyEffects == nil) {
            // Blur effect
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc]initWithEffect:blurEffect];
        [blurEffectView setFrame:_tabBarController.view.bounds];
        
            // Vibrancy effect
        UIVibrancyEffect *vibrancyEffect = [UIVibrancyEffect effectForBlurEffect:blurEffect];
        UIVisualEffectView *vibrancyEffectView = [[UIVisualEffectView alloc]initWithEffect:vibrancyEffect];
        [vibrancyEffectView setFrame:_tabBarController.view.bounds];
        
        // Label for vibrant text
        UILabel *vibrantLabel = [UILabel new];
        [vibrantLabel setText:NSLocalizedString(@"ToThePenny", @"App name for vibrant label")];
        [vibrantLabel setFont:[UIFont fontWithName:@"HelveticaNeue-CondensedBold" size:21.0]];
        [vibrantLabel sizeToFit];
        
        CGPoint location = _tabBarController.view.center;
        location.y = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame) + 22.0f;
        [vibrantLabel setCenter:location];
        
        // Add label to the vibrancy view
        [[vibrancyEffectView contentView]addSubview:vibrantLabel];
        
            // Add the vibrancy view to the blur view
        [[blurEffectView contentView]addSubview:vibrancyEffectView];
        
        _visualEffectViewWithBlurAndVibrancyEffects = blurEffectView;
    }
    
    return _visualEffectViewWithBlurAndVibrancyEffects;
}

- (void)presentVisualEffectViewWithBlurAndVibrancyEffects {
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kLoginWithTouchId]) {
        _visualEffectViewWithBlurAndVibrancyEffectsPresented = YES;
        [_tabBarController.view addSubview:self.visualEffectViewWithBlurAndVibrancyEffects];
    }
}

- (void)hideVisualEffectViewWithBlurAndVibrancyEffects {
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kLoginWithTouchId]) {
        _visualEffectViewWithBlurAndVibrancyEffectsPresented = NO;
        [self.visualEffectViewWithBlurAndVibrancyEffects removeFromSuperview];
    }
}

@end