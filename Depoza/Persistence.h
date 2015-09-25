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

- (void)persistenceStore:(Persistence *)persistence didChangeNotification:(NSNotification *)notification;

- (void)persistenceStore:(Persistence *)persistence didImportUbiquitousContentChanges:(NSNotification *)notification;

- (void)persistenceStore:(Persistence *)persistence willChangeNotification:(NSNotification *)notification;

@end

@interface Persistence : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) id<PersistenceNotificationDelegate>delegate;

+ (instancetype)sharedInstance;
- (id)initWithStoreURL:(NSURL *)storeURL modelURL:(NSURL *)modelURL;

- (void)saveContext;
- (void)deleteAllCategories;

- (NSManagedObjectContext *)createManagedObjectContext;

- (void)removePersistentStoreNotificationSubscribes;
- (void)addPersistentStoreNotificationSubscribes;

- (void)insertNecessaryCategoryData;

- (void)deduplication;
- (NSInteger)findMaxIdValueInEntity:(NSString *)entityName;

- (void)deviceListChanged:(NSNotification *)notification;

- (BOOL)iCloudEnabled;

//Indexing searcheble items only for current month.
- (void)indexAllData;
- (void)indexExpenses;
- (void)indexCategories;

@end
