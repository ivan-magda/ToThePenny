    //Framework
#import <UIKit/UIKit.h>
    //Delegate
#import "AddExpenseTableViewControllerDelegate.h"
#import "MainViewControllerDelegate.h"
#import "SelectMonthViewControllerDelegate.h"
#import "CategoriesContainerViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface MainViewController : UIViewController <AddExpenseTableViewControllerDelegate, SelectMonthViewControllerDelegate, CategoriesContainerViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) id<MainViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL isShowExpenseDetailFromExtension;

- (void)updateUserInterfaceWithNewFetch:(BOOL)fetch;

- (void)performAddExpense;

- (BOOL)isAddExpensePresenting;
- (BOOL)isSelectMonthIsPresenting;

- (void)dismissSelectMonthViewController;

@end