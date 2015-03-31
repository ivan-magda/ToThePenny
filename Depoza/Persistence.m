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
        _managedObjectContext = [self managedObjectContext];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"Dealloc %@", self);
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
    NSURL *url = [[[NSFileManager defaultManager]URLsForDirectory:NSDocumentationDirectory inDomains:NSUserDomainMask]lastObject];
    NSParameterAssert(url);

    return url;
}

- (NSURL *)dataStorePath {
    return [[self documentsDirectory]
            URLByAppendingPathComponent:@"DataStore.sqlite"];
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        NSURL *storeURL = [self dataStorePath];

        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:self.managedObjectModel];

        NSDictionary *storeOptions = @{NSPersistentStoreUbiquitousContentNameKey: @"DepozaCloudStore"};
        NSError *error;

        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

        [notificationCenter addObserver:self selector:@selector(storeDidChange:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:self.managedObjectContext.persistentStoreCoordinator];

        [notificationCenter addObserver:self selector:@selector(storeWillChange:) name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:self.managedObjectContext.persistentStoreCoordinator];

        [[NSNotificationCenter defaultCenter]addObserverForName:NSPersistentStoreDidImportUbiquitousContentChangesNotification
                                                         object:self.managedObjectContext.persistentStoreCoordinator
                                                          queue:[NSOperationQueue mainQueue]
                                                     usingBlock:^(NSNotification *note) {
                                                         [self.managedObjectContext performBlock:^{
                                                             NSLog(@"DidImportUbiquitousContentChanges");
                                                             [self.managedObjectContext mergeChangesFromContextDidSaveNotification:note];
                                                         }];
                                                     }];

        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:storeOptions error:&error]) {
            NSLog(@"Error adding persistent store %@, %@", error, [error userInfo]);
            abort();
        }
    }
    return _persistentStoreCoordinator;
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

- (void)storeDidChange:(NSNotification*)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Store did change");
        if ([self.delegate respondsToSelector:@selector(storeDidChange:)]) {
            [self.delegate storeDidChange:notification];
        }
    });
}

- (void)storeWillChange:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Will change");
            // disable user interface with setEnabled: or an overlay
            if ([self.managedObjectContext hasChanges]) {
                NSError *saveError;
                if (![self.managedObjectContext save:&saveError]) {
                    NSLog(@"Save error: %@", saveError);
                }
            } else {
                    // drop any managed object references
                [self.managedObjectContext reset];
                if ([self.delegate respondsToSelector:@selector(storeWillChange:)]) {
                    [self.delegate storeWillChange:notification];
                }
            }
    });
}

#pragma mark - Seed Data -

- (void)seedDataIfNeeded {
    NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];

    if (![kvStore boolForKey:@"SEEDED_DATA"]) {
        NSString *countryCode = [[NSLocale currentLocale]objectForKey: NSLocaleCountryCode];
        if ([countryCode isEqualToString:@"RU"]) {
            [CategoryData categoryDataWithTitle:@"Связь" iconName:@"SimCard" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Одежда" iconName:@"Clothes" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Здоровье" iconName:@"Hearts" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Продукты" iconName:@"Ingredients" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Еда вне дома" iconName:@"Cutlery" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Жилье" iconName:@"Exterior" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Поездки" iconName:@"Beach" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Электроника" iconName:@"SmartphoneTablet" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Развлечения" iconName:@"Controller" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        } else if ([countryCode isEqualToString:@"US"]) {
            [CategoryData categoryDataWithTitle:@"Communication" iconName:@"SimCard" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Clothes" iconName:@"Clothes" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Healthcare" iconName:@"Hearts" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Foodstuffs" iconName:@"Ingredients" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"EatingOut" iconName:@"Cutlery" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Housing" iconName:@"Exterior" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Trip" iconName:@"Beach" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Electronics" iconName:@"SmartphoneTablet" andExpenses:nil inManagedObjectContext:_managedObjectContext];
            [CategoryData categoryDataWithTitle:@"Entertainment" iconName:@"Controller" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        } else {
            NSParameterAssert(NO);
        }
        [kvStore setBool:YES forKey:@"SEEDED_DATA"];
        [kvStore synchronize];

        [self saveContext];
        [self setCategoryId];
    }
}

@end