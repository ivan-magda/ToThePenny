    //
    //  AppDelegate.m
    //  Depoza
    //
    //  Created by Ivan Magda on 20.11.14.
    //  Copyright (c) 2014 Ivan Magda. All rights reserved.
    //

    //AppDelegate
#import "AppDelegate.h"
    //ViewControllers
#import "CustomTabBarController.h"
#import "MainViewController.h"
#import "SearchTableViewController.h"
#import "DetailExpenseTableViewController.h"
#import "SettingsTableViewController.h"
#import "SelectedCategoryTableViewController.h"
#import "CategoriesContainerViewController.h"
#import <KVNProgress/KVNProgress.h>
    //CoreData
#import "ExpenseData+Fetch.h"
#import "CategoryData+Fetch.h"
#import "Fetch.h"
    //CoreSearch
@import CoreSpotlight;
    //AppAppearance
#import "AppConfiguration.h"
    //View
#import "VisualEffectViewWithBlurAndVibrancyEffects.h"
//ThirdParty
    //Crashlytics
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
    //iRate
#import "iRate.h"
    //TouchID
#import <SmileTouchID/SmileAuthenticator.h>

typedef void(^SmileTouchIdUserSuccessAuthenticationBlock)();

static NSString * const kAppGroupSharedContainer = @"group.com.vanyaland.depoza";
static NSString * const kAddExpenseOnStartupKey = @"AddExpenseOnStartup";
static NSString * const kLoginWithTouchId = @"LoginWithTouchId";
static NSString * const kDetailViewControllerPresentingFromExtensionKey = @"DetailViewPresenting";
static NSString * const kSmileTouchIdUserSuccessAuthenticationNotification = @"smileTouchIdUserSuccessAuthentication";
static NSString * const kDetailExpenseTableViewControllerSegueIdentifier = @"MoreInfo";

NSString * const StatusBarTappedNotification = @"statusBarTappedNotification";

@interface AppDelegate () <SmileAuthenticatorDelegate>

@property (nonatomic, strong) VisualEffectViewWithBlurAndVibrancyEffects *visualEffectViewWithBlurAndVibrancyEffects;

@property (nonatomic, copy) SmileTouchIdUserSuccessAuthenticationBlock successAuthenticationHandler;

@end

@implementation AppDelegate {
    CustomTabBarController *_tabBarController;
    MainViewController *_mainViewController;
    SearchTableViewController *_allExpensesTableViewController;
    SettingsTableViewController *_settingsTableViewController;

    NSUserDefaults *_appGroupUserDefaults;
    
    UIColor *_mainColor;
    
    AppConfiguration *_appConfiguration;
    
    BOOL _authViewControllerPresented;
    BOOL _userSuccessAuthentication;
    BOOL _visualEffectViewWithBlurAndVibrancyEffectsPresented;
}

#pragma mark - Persistent Stack

- (void)setUpPersistence {
    self.persistence = [[Persistence alloc]initWithStoreURL:self.storeURL modelURL:self.modelURL];
    self.managedObjectContext = self.persistence.managedObjectContext;
    self.persistence.delegate = self;
    
    /// Spread context to all VC of TabBarVC.
    [self spreadManagedObjectContext];
    
    /// Expense checking.
    [ExpenseData checkForDataCorrectionInContext:_managedObjectContext];
}

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

#pragma mark - AppConfiguration -

- (void)setUpAppConfiguration {
    _appConfiguration = [AppConfiguration new];
    
    [self applyAppAppearance];
    [self setUpSmileTouchId];
    
    [_appConfiguration setUpKVNProgressConfiguration];
    [_appConfiguration setUpIrate];
}

- (void)applyAppAppearance {
    _mainColor = _appConfiguration.mainColor;
    [_appConfiguration applyAppAppearance];
}

- (void)setUpSmileTouchId {
    [_appConfiguration configurateSmileTouchIdWithRootViewController:self.window.rootViewController];
    _appConfiguration.smileAuthenticatorDelegate = self;
}

#pragma mark - AppDelegate -

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //check for UiTesting flag
    if ([[[NSProcessInfo processInfo] arguments] containsObject:@"isUITesting"]) {
        [self clearUserDefaults];
    }
    [Fabric with:@[CrashlyticsKit]];

    [self setUpPersistence];
    [self setUpAppConfiguration];

    _appGroupUserDefaults = [[NSUserDefaults alloc]initWithSuiteName:kAppGroupSharedContainer];
    
    [_persistence indexAllData];
    

    return YES;
}

- (void)clearUserDefaults {
    NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier];
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSArray *folders = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask,  YES);
    NSFileManager *fm = [[NSFileManager alloc] init];
    for (NSString *path in folders) {
        [fm removeItemAtPath:path error:nil];
    }
    
    NSArray *folders_document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask,  YES);
    NSFileManager *fm1 = [[NSFileManager alloc] init];
    for (NSString *path in folders_document) {
        [fm1 removeItemAtPath:path error:nil];
    }

    
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
    
    __weak Persistence *persistenceStack = _persistence;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
       [Fetch updateTodayExpensesDictionaryInContext:[persistenceStack createManagedObjectContext]];
    });
    
    [_persistence indexAllData];
    
    [[NSUbiquitousKeyValueStore defaultStore]synchronize];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self hideVisualEffectViewWithBlurAndVibrancyEffects];
    
    _tabBarController.selectedIndex = 0;
    
    if ([_appGroupUserDefaults boolForKey:kDetailViewControllerPresentingFromExtensionKey]) {
        [_appGroupUserDefaults setBool:NO forKey:kDetailViewControllerPresentingFromExtensionKey];
        [_appGroupUserDefaults synchronize];
        
        if (_mainViewController.isAddExpensePresenting) {
            [_mainViewController dismissViewControllerAnimated:YES completion:nil];
        }
        
    } else if ([[NSUserDefaults standardUserDefaults]boolForKey:kAddExpenseOnStartupKey]) {
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
                        [weakMainVC performSegueWithIdentifier:kDetailExpenseTableViewControllerSegueIdentifier sender:selectedExpense];
                    } copy];
                } else {
                    [_mainViewController dismissViewControllerAnimated:YES completion:^{
                        [weakMainVC performSegueWithIdentifier:kDetailExpenseTableViewControllerSegueIdentifier sender:selectedExpense];
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
                    [weakMainVC performSegueWithIdentifier:kDetailExpenseTableViewControllerSegueIdentifier sender:selectedExpense];
                } copy];
                
                return YES;
            }
            
            [_mainViewController performSegueWithIdentifier:kDetailExpenseTableViewControllerSegueIdentifier sender:selectedExpense];
            
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

- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray * _Nullable))restorationHandler {
    
    if ([userActivity.activityType isEqualToString:CSSearchableItemActionType]) {
        if (_mainViewController.isAddExpensePresenting) {
            [_mainViewController dismissViewControllerAnimated:YES completion:^{
                [self handlingResultSelectionWithUserActivity:userActivity];
            }];
            _mainViewController.isAddExpensePresenting = NO;
        } else {
            //Remove observer in MainVC, that listen to touch id success auth
            //if not, then AddExpenseVC may be present.
            if ([SmileAuthenticator hasPassword]) {
                [[NSNotificationCenter defaultCenter]removeObserver:_mainViewController name:SmileTouchIdUserSuccessAuthenticationNotification object:nil];
            }
            [_mainViewController.navigationController popToRootViewControllerAnimated:NO];
            
            [self handlingResultSelectionWithUserActivity:userActivity];
        }
        return YES;
    } else {
        return NO;
    }
}

- (void)handlingResultSelectionWithUserActivity:(NSUserActivity *)userActivity {
    // This activity represents an item indexed using Core Spotlight, so restore the context related to the unique identifier.
    // Note that the unique identifier of the Core Spotlight item is set in the activity’s userInfo property for the key CSSearchableItemActivityIdentifier.
    NSString *identifier = userActivity.userInfo[CSSearchableItemActivityIdentifier];
    // Next, find and open the item specified by uniqueIdentifer.
    NSArray *searchedItemInfo = [identifier componentsSeparatedByString:@"."];
    NSInteger idValue = [searchedItemInfo.lastObject integerValue];
    
    NSParameterAssert(searchedItemInfo.count == 2);

    if ([searchedItemInfo.firstObject isEqualToString:@"category"]) {
        CategoryData *category = [CategoryData getCategoryFromIdValue:idValue inManagedObjectContext:_managedObjectContext];
        
        [[NSNotificationCenter defaultCenter]postNotificationName:ContinuingActivityRepresentsSearchableCategoryNotification object:category];
    } else {
        ExpenseData *expense = [ExpenseData getExpenseFromIdValue:idValue inManagedObjectContext:_managedObjectContext];
        
        [[NSNotificationCenter defaultCenter]postNotificationName:ContinuingActivityRepresentsSearchableExpenseNotification object:expense];
    }
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

- (VisualEffectViewWithBlurAndVibrancyEffects *)visualEffectViewWithBlurAndVibrancyEffects {
    if (_visualEffectViewWithBlurAndVibrancyEffects == nil) {
        _visualEffectViewWithBlurAndVibrancyEffects = [[VisualEffectViewWithBlurAndVibrancyEffects alloc]initWithFrame:_tabBarController.view.bounds];
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
