#import <UIKit/UIKit.h>
    //Delegate
#import "AddExpenseViewControllerDelegate.h"
#import "EditExpenseTableViewControllerDelegate.h"
#import "AddCategoryViewControllerDelegate.h"
#import "MainViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface MIAMainViewController : UIViewController <MIAAddExpenseViewControllerDelegate, MIAEditExpenseTableViewControllerDelegate, MIAAddCategoryViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) id<MIAMainViewControllerDelegate> delegate;

@end