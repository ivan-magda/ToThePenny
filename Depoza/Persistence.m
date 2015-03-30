//
//  SharedManagedObjectContext.m
//  Depoza
//
//  Created by Ivan Magda on 22/12/14.
//  Copyright (c) 2014 Ivan Magda. All rights reserved.
//

#import "Persistence.h"
#import "CategoryData+Fetch.h"
#import "ExpenseData.h"

static NSString * const kAppGroupSharedContainer = @"group.com.vanyaland.depoza";

@implementation Persistence

+ (instancetype)sharedInstance {
    static Persistence *this = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        this = [Persistence new];
    });
    return this;
}

- (instancetype)init {
    if (self = [super init]) {
        NSLog(@"Allocate SharedManagedObjectContext");
        _persistentStoreCoordinator = [self persistentStoreCoordinator];
    }
    return self;
}

- (void)dealloc {
    NSParameterAssert(false);
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSManagedObjectModel *)managedObjectModel {
    if (!_managedObjectModel) {
        NSString *modelPath = [[NSBundle mainBundle]pathForResource:@"DataModel" ofType:@"momd"];
        NSURL *modelURL = [NSURL fileURLWithPath:modelPath];

        _managedObjectModel = [[NSManagedObjectModel alloc]initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSURL *)documentsDirectory {
    NSFileManager *fileManager = [NSFileManager defaultManager];

    NSURL *sharedContainerURL = [fileManager containerURLForSecurityApplicationGroupIdentifier:kAppGroupSharedContainer];
    NSParameterAssert(sharedContainerURL);

    return sharedContainerURL;
}

- (NSURL *)dataStorePath {
    return [[self documentsDirectory]
            URLByAppendingPathComponent:@"DataStore.sqlite"];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        NSURL *storeURL = [self dataStorePath];

        [self initStore:storeURL];

        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:self.managedObjectModel];

        NSError *error;
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            NSLog(@"Error adding persistent store %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
}

- (void)initStore:(NSURL *)storeURL {
    if (![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
        NSLocale *locale = [NSLocale currentLocale];
        NSString *path = nil;
        NSString *countryCode = [locale objectForKey: NSLocaleCountryCode];
        if ([countryCode isEqualToString:@"US"]) {
            path = @"seedUS";
        } else if ([countryCode isEqualToString:@"RU"]){
            path = @"seedRU";
        }

        NSURL *preloadURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:path ofType:@"sqlite"]];

        NSError* err;
        if (![[NSFileManager defaultManager] copyItemAtURL:preloadURL toURL:storeURL error:&err]) {
            NSLog(@"Oops, could copy preloaded data");
        } else {
            NSLog(@"Store successfully initialized using the original seed");

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self setCategoryId];
            });
        }
    } else {
        NSLog(@"The original seed isn't needed. There is already a backing store.");
    }
}

- (void)setCategoryId {
    NSUInteger numberOfCategories = [CategoryData countForCategoriesInContext:_managedObjectContext];

    NSParameterAssert(numberOfCategories > 0);

    NSLog(@"Number of categories: %lu", (unsigned long)numberOfCategories);

    [CategoryData synchronizeUserDefaultsWithNumberCategories:numberOfCategories];
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
        if (coordinator) {
            _managedObjectContext = [[NSManagedObjectContext alloc]init];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];
        }
    }
    return _managedObjectContext;
}

- (NSManagedObjectContext *)createManagedObjectContext {
    NSManagedObjectContext *managedObjectContext = [[NSManagedObjectContext alloc] init];

    [managedObjectContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];

    return managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end