#import <UIKit/UIKit.h>
#import "AddExpenseViewControllerProtocol.h"

@interface AddExpenseViewController : UIViewController

@property (nonatomic, weak) id<AddExpenseViewControllerProtocol> delegate;

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, copy) NSArray *categories;

@end