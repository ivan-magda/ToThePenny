#import <UIKit/UIKit.h>
#import "AddExpenseViewControllerDelegate.h"

@interface MIAAddExpenseViewController : UIViewController

@property (nonatomic, weak) id<MIAAddExpenseViewControllerDelegate> delegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) NSArray *categories;

@end