//
//  NSURL+InternalExtensions.m
//  iOSCoreLibrary
//
//  Created by Iain McManus on 5/06/2014.
//  Copyright (c) 2014 Iain McManus. All rights reserved.
//

#import "NSURL+InternalExtensions.h"

@implementation NSURL (InternalExtensions)

/*
Check if the file has been downloaded
If the query succeeds and reports that the file as downloaded then we’re done. Report back that the file exists.
Otherwise, check if the file is downloading.
If the query succeeds and reports that the file is not downloading OR if the query failed then request it to start downloading.
If the request to start downloading fails then we’re done. Report back that the file does not exist.
If the file is downloading OR if the downloading query failed OR if we have requested it to download.
Wait for a brief time and start at the first step again.
 */
- (void)forceSyncFile:(dispatch_queue_t)dispatchQueue completion:(void (^)(BOOL syncCompleted, NSError *))completionHandler {
    NSError* error;
    
    // Query if the file has been downloaded. We can exit if the query succeeds and the file is reported as downloaded.
    NSString* isDownloaded;
    if ([self getResourceValue:&isDownloaded forKey:NSURLUbiquitousItemDownloadingStatusKey error:&error] &&
        [isDownloaded isEqualToString:NSURLUbiquitousItemDownloadingStatusCurrent]) {
        completionHandler(YES, nil);
        return;
    }
    
    // Query if the file is downloading
    NSNumber* isDownloading;
    if (![self getResourceValue:&isDownloading forKey:NSURLUbiquitousItemIsDownloadingKey error:&error]) {
        isDownloading = nil;
    }
    
    // Start the file downloading if it is not already downloading
    if (!isDownloading || ![isDownloading boolValue]) {
        if (![[NSFileManager defaultManager] startDownloadingUbiquitousItemAtURL:self error:&error]) {
            completionHandler(NO, error);
            return;
        }
    }
    
    // Check again after a small delay
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatchQueue, ^{
        [self forceSyncFile:dispatchQueue completion:[completionHandler copy]];
    });
}

@end
