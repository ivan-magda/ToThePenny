    //Framework
#import <UIKit/UIKit.h>
    //Delegate
#import "AddExpenseViewControllerDelegate.h"
#import "AddCategoryViewControllerDelegate.h"
#import "MainViewControllerDelegate.h"
#import "SelectMonthViewControllerDelegate.h"
#import "CategoriesContainerViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface MainViewController : UIViewController <AddExpenseViewControllerDelegate, AddCategoryViewControllerDelegate, SelectMonthViewControllerDelegate, CategoriesContainerViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) id<MainViewControllerDelegate> delegate;

@property (nonatomic, assign) BOOL isShowExpenseDetailFromExtension;

- (void)updateUserInterfaceWithNewFetch:(BOOL)fetch;

- (void)performAddExpense;

- (BOOL)isAddExpensePresenting;
- (BOOL)isSelectMonthIsPresenting;

- (void)dismissSelectMonthViewController;

@end