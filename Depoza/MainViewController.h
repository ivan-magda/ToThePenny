#import <UIKit/UIKit.h>
    //Delegate
#import "AddExpenseViewControllerDelegate.h"
#import "EditExpenseTableViewControllerDelegate.h"
#import "AddCategoryViewControllerDelegate.h"
#import "MainViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface MainViewController : UIViewController <AddExpenseViewControllerDelegate, EditExpenseTableViewControllerDelegate, AddCategoryViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) id<MainViewControllerDelegate> delegate;

@end