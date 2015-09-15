    //Framework
#import <UIKit/UIKit.h>
    //Delegate
#import "AddExpenseTableViewControllerDelegate.h"
#import "MainViewControllerDelegate.h"
#import "SelectTimePeriodViewControllerDelegate.h"
#import "CategoriesContainerViewControllerDelegate.h"

@class NSManagedObjectContext;

extern NSString * const ContinuingActivityRepresentsSearchableExpenseNotification;

extern NSString * const SmileTouchIdUserSuccessAuthenticationNotification;

@interface MainViewController : UIViewController <AddExpenseTableViewControllerDelegate, SelectTimePeriodViewControllerDelegate, CategoriesContainerViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) id<MainViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL isShowExpenseDetailFromExtension;
@property (nonatomic,assign) BOOL isAddExpensePresenting;

- (void)updateUserInterfaceWithNewFetch:(BOOL)fetch;

- (void)presentAddExpenseViewControllerIfNeeded;

- (BOOL)isSelectMonthIsPresenting;

- (void)dismissSelectMonthViewController;

@end