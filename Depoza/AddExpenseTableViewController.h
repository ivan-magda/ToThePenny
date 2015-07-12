#import <UIKit/UIKit.h>
#import "AddExpenseTableViewControllerDelegate.h"

@interface AddExpenseTableViewController : UITableViewController

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) NSArray *categoriesInfo;

@property (nonatomic, strong) id<AddExpenseTableViewControllerDelegate> delegate;

@end