#import <UIKit/UIKit.h>
#import "Persistence.h"

/*!
 * Status bar tapped tracking notification name.
 */
extern NSString * const StatusBarTappedNotification;

@interface AppDelegate : UIResponder <UIApplicationDelegate, PersistenceNotificationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) NSManagedObjectContext* managedObjectContext;
@property (nonatomic, strong) Persistence *persistence;

@end

