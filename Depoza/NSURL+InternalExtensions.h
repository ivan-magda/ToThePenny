//
//  NSURL+InternalExtensions.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 5/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURL (InternalExtensions)

- (void)forceSyncFile:(dispatch_queue_t) dispatchQueue completion:(void (^)(BOOL syncCompleted, NSError *))completionHandler;

@end
