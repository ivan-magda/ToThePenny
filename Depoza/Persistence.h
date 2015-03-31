//
//  SharedManagedObjectContext.h
//  Depoza
//
//  Created by Ivan Magda on 22/12/14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@protocol PersistenceDelegate <NSObject>

- (void)storeDidChange:(NSNotification*)notification;
- (void)storeWillChange:(NSNotification *)notification;

@end

@interface Persistence : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) id<PersistenceDelegate> delegate;

+ (instancetype)sharedInstance;

- (void)saveContext;
- (void)seedDataIfNeeded;

@end
