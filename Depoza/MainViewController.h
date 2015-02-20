#import <UIKit/UIKit.h>
#import "AddExpenseViewControllerDelegate.h"
#import "EditExpenseTableViewControllerDelegate.h"
#import "AddCategoryViewControllerDelegate.h"

@class NSManagedObjectContext;

@interface MainViewController : UIViewController <AddExpenseViewControllerDelegate, EditExpenseTableViewControllerDelegate, AddCategoryViewControllerDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end