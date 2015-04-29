#import <UIKit/UIKit.h>
#import "AddExpenseTableViewControllerDelegate.h"

@interface AddExpenseTableViewController : UITableViewController

@property (nonatomic, weak) id<AddExpenseTableViewControllerDelegate> delegate;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, copy) NSArray *categoriesInfo;

@end