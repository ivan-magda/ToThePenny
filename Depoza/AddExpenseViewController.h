#import <UIKit/UIKit.h>
#import "AddExpenseViewControllerProtocol.h"

@interface AddExpenseViewController : UIViewController

@property (nonatomic, weak) id<AddExpenseViewControllerProtocol> delegate;

@end