//
//  SharedManagedObjectContext.h
//  Depoza
//
//  Created by Ivan Magda on 22/12/14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Persistence;

@protocol PersistenceNotificationDelegate <NSObject>

- (void)persistenceStore:(Persistence *)persistence didImportUbiquitousContentChanges:(NSNotification *)notification;

@end

@interface Persistence : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) id<PersistenceNotificationDelegate>delegate;

+ (instancetype)sharedInstance;

- (void)saveContext;

- (void)removePersistentStoreNotificationSubscribes;
- (void)addPersistentStoreNotificationSubscribes:(NSPersistentStoreCoordinator *)persistentStoreCoordinator;

- (void)deduplication;
- (NSInteger)findMaxIdValueInEntity:(NSString *)entityName;

@end
