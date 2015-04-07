//
//  ICLCoreDataDeviceList.h
//  iOSCoreLibrary
//
//  Created by Iain McManus on 5/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataDeviceList : NSObject <NSFilePresenter>

- (id)initWithURLAndQueue:(NSURL *)fileURL queue:(NSOperationQueue *)queue;

@end
