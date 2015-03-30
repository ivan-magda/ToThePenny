#import <UIKit/UIKit.h>
#import "AddExpenseViewControllerDelegate.h"

@interface AddExpenseViewController : UIViewController

@property (nonatomic, weak) id<AddExpenseViewControllerDelegate> delegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) NSArray *categories;

@end