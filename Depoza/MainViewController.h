    //Framework
#import <UIKit/UIKit.h>
    //Delegate
#import "AddExpenseViewControllerDelegate.h"
#import "DetailExpenseTableViewControllerDelegate.h"
#import "AddCategoryViewControllerDelegate.h"
#import "MainViewControllerDelegate.h"
#import "SelectMonthViewControllerDelegate.h"
#import "CategoriesContainerViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface MainViewController : UIViewController <AddExpenseViewControllerDelegate, DetailExpenseTableViewControllerDelegate, AddCategoryViewControllerDelegate, SelectMonthViewControllerDelegate, CategoriesContainerViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) id<MainViewControllerDelegate> delegate;

- (void)updateUserInterfaceWithNewFetch:(BOOL)fetch;

@end