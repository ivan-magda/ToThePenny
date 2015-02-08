#import <UIKit/UIKit.h>
#import "AddExpenseViewControllerProtocol.h"

@class NSManagedObjectContext;

@interface MainViewController : UIViewController <AddExpenseViewControllerProtocol>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@end