#import <UIKit/UIKit.h>
#import "Persistence.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate, PersistenceNotificationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) Persistence *persistence;

@end

