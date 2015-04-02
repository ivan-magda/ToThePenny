    //
    //  SharedManagedObjectContext.m
    //  Depoza
    //
    //  Created by Ivan Magda on 22/12/14.
    //  Copyright (c) 2014 Ivan Magda. All rights reserved.
    //

#import "Persistence.h"
#import "CategoryData+Fetch.h"
#import "ExpenseData+Fetch.h"

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
        NSURL *modelURL = [[NSBundle mainBundle]URLForResource:@"DataModel" withExtension:@"momd"];

        _managedObjectModel = [[NSManagedObjectModel alloc]initWithContentsOfURL:modelURL];
    }
    return _managedObjectModel;
}

- (NSURL *)documentsDirectory {
    NSURL *url = [[[NSFileManager defaultManager]URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask]lastObject];
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
        [self addPersistentStoreNotificationSubscribes:_persistentStoreCoordinator];

        NSError *error = nil;
        NSDictionary *iCloudOptions = @{NSPersistentStoreUbiquitousContentNameKey: @"DepozaCloudStore"};

        NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
        NSAssert(kvStore, @"Key Value Store must exist!!!");

        if (![kvStore boolForKey:@"SEEDED_DATA"]) {
            NSString *countryCode = [[NSLocale currentLocale]objectForKey: NSLocaleCountryCode];
            NSString *seedName = [NSString stringWithFormat:@"seed%@", countryCode];
            NSURL *seedStoreURL = [[NSBundle mainBundle]URLForResource:seedName withExtension:@"sqlite"];

            NSError *seedStoreError = nil;
            NSDictionary *seedStoreOptions = @{NSReadOnlyPersistentStoreOption: @YES};

            NSPersistentStore *seedStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:seedStoreURL options:seedStoreOptions error:&seedStoreError];

            if (![_persistentStoreCoordinator migratePersistentStore:seedStore toURL:storeURL options:iCloudOptions withType:NSSQLiteStoreType error:&error]) {
                NSLog(@"Error adding seed persistent store %@, %@", error, [error userInfo]);
            }
            NSLog(@"Store succesfully initialized using the original seed");

            [kvStore setBool:YES forKey:@"SEEDED_DATA"];
        } else {
            if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:iCloudOptions error:&error]) {
                NSLog(@"Error adding persistent store %@, %@", error, [error userInfo]);
                abort();
            }
            NSLog(@"The original seed is't needed, the is a backing store");
        }
    }

    NSLog(@"%@", _persistentStoreCoordinator.persistentStores);

    return _persistentStoreCoordinator;
}

- (NSManagedObjectContext *)managedObjectContext {
    if (!_managedObjectContext) {
        NSPersistentStoreCoordinator *coordinator = self.persistentStoreCoordinator;
        if (coordinator) {
            _managedObjectContext = [[NSManagedObjectContext alloc]init];
            [_managedObjectContext setPersistentStoreCoordinator:coordinator];

            NSInteger categoryMaxID = [self findMaxIdValueInEntity:NSStringFromClass([CategoryData class])];
            [CategoryData setNextIdValueToUbiquitousKeyValueStore:categoryMaxID + 1];
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

#pragma mark - Notifications -

- (void)removePersistentStoreNotificationSubscribes {
    NSLog(@"Persistence remove observers");
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)addPersistentStoreNotificationSubscribes:(NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    NSLog(@"Persistence add observers");
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self selector:@selector(storeDidImportUbiquitousContentChanges:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:persistentStoreCoordinator];
    [notificationCenter addObserver:self selector:@selector(storeWillChange:) name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:persistentStoreCoordinator];
}

- (void)storeDidImportUbiquitousContentChanges:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%@", notification.userInfo.description);
    
    [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];
    
    if ([self.delegate respondsToSelector:@selector(persistenceStore:didImportUbiquitousContentChanges:)]) {
        [self.delegate persistenceStore:self didImportUbiquitousContentChanges:notification];
    }
}

- (void)storeWillChange:(NSNotification *)notification {
    NSLog(@"%s", __PRETTY_FUNCTION__);
    NSLog(@"%@", notification.description);

    NSUInteger persistentStoreUbiquitousTransitionType = [[notification.userInfo objectForKey:NSPersistentStoreUbiquitousTransitionTypeKey]unsignedIntegerValue];
    switch (persistentStoreUbiquitousTransitionType) {
        case NSPersistentStoreUbiquitousTransitionTypeAccountAdded:
            NSLog(@"NSPersistentStoreUbiquitousTransitionTypeAccountAdded");
            break;
        case NSPersistentStoreUbiquitousTransitionTypeAccountRemoved: {
            NSLog(@"NSPersistentStoreUbiquitousTransitionTypeAccountRemoved");
            NSError *saveError;
            if (![self.managedObjectContext save:&saveError]) {
                NSLog(@"Save error: %@", [saveError localizedDescription]);
            }
            [self.managedObjectContext reset];
            return ;
        }
        case NSPersistentStoreUbiquitousTransitionTypeContentRemoved:
            NSLog(@"NSPersistentStoreUbiquitousTransitionTypeContentRemoved");
            break;
        case NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted:
            NSLog(@"NSPersistentStoreUbiquitousTransitionTypeInitialImportCompleted");
            break;
        default:
            NSParameterAssert(NO);
            break;
    }

    if ([self.managedObjectContext hasChanges]) {
        NSError *saveError;
        if (![self.managedObjectContext save:&saveError]) {
            NSLog(@"Save error: %@", [saveError localizedDescription]);
        }
    } else {
        [self.managedObjectContext reset];
    }
}

- (void)deduplication {
        //Choose a property or a hash of multiple properties to use as a unique ID for each record.
    NSString *uniquePropertyKey = NSStringFromSelector(@selector(title));
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:uniquePropertyKey];
    NSExpression *countExpression = [NSExpression expressionForFunction: @"count:" arguments:@[keyPathExpression]];
    NSExpressionDescription *countExpressionDescription = [NSExpressionDescription new];

    [countExpressionDescription setName:@"count"];
    [countExpressionDescription setExpression:countExpression];
    [countExpressionDescription setExpressionResultType:NSInteger64AttributeType];

    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:NSStringFromClass([CategoryData class]) inManagedObjectContext:context];

    NSAttributeDescription *uniqueAttribute = [[entity attributesByName]objectForKey:uniquePropertyKey];

        //Fetch the number of times each unique value appears in the store.
        //The context returns an array of dictionaries, each containing a unique value and the number of times that value appeared in the store.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
    [fetchRequest setPropertiesToFetch:@[uniqueAttribute, countExpressionDescription]];
    [fetchRequest setPropertiesToGroupBy:@[uniqueAttribute]];
    [fetchRequest setResultType:NSDictionaryResultType];
    NSArray *fetchedDictionaries = [context executeFetchRequest:fetchRequest error:nil];

        //Filter out unique values that have no duplicates.
    NSMutableArray *valuesWithDupes = [NSMutableArray array];
    for (NSDictionary *dict in fetchedDictionaries) {
        NSNumber *count = dict[@"count"];
        if ([count integerValue] > 1) {
            [valuesWithDupes addObject:dict[uniquePropertyKey]]; }
    }

    if (valuesWithDupes.count > 0) {
        NSLog(@"%s", __PRETTY_FUNCTION__);
        NSLog(@"Duplications found");
            //Use a predicate to fetch all of the records with duplicates.
            //Use a sort descriptor to properly order the results for the winner algorithm in the next step.
        NSFetchRequest *dupeFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
        [dupeFetchRequest setIncludesPendingChanges:NO];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title IN (%@)", valuesWithDupes];
        [dupeFetchRequest setPredicate:predicate];

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:uniquePropertyKey ascending:NO];
        [dupeFetchRequest setSortDescriptors:@[sortDescriptor]];

        NSArray *dupes = [context executeFetchRequest:dupeFetchRequest error:nil];

            //Choose the winner.
            //After retrieving all of the duplicates, your app decides which ones to keep. This decision must be deterministic, meaning that every peer should always choose the same winner. Among other methods, your app could store a created or last-changed timestamp for each record and then decide based on that.
        CategoryData *prevObject;
        for (CategoryData *duplicate in dupes) {
            if (prevObject) {
                if ([duplicate.title isEqualToString:prevObject.title]) {
                    if (duplicate.expense.count < prevObject.expense.count) {
                            //[self moveExpensesToCategory:prevObject fromCategory:duplicate];
                        [context deleteObject:duplicate];
                    } else {
                            //[self moveExpensesToCategory:duplicate fromCategory:prevObject];
                        [context deleteObject:prevObject];
                        prevObject = duplicate;
                    }
                } else {
                    prevObject = duplicate;
                }
            } else {
                prevObject = duplicate;
            }
        }
        NSInteger categoryMaxID = [self findMaxIdValueInEntity:NSStringFromClass([CategoryData class])];
        NSInteger expenseMaxID  = [self findMaxIdValueInEntity:NSStringFromClass([ExpenseData class])];

        [CategoryData setNextIdValueToUbiquitousKeyValueStore:categoryMaxID + 1];
        [ExpenseData setNextIdValueToUbiquitousKeyValueStore:expenseMaxID + 1];
    }
}

- (void)moveExpensesToCategory:(CategoryData *)toCategory fromCategory:(CategoryData *)fromCategory {
    for (ExpenseData *expense in fromCategory.expense) {
        [expense.category removeExpenseObject:expense];

        expense.category = toCategory;
        expense.categoryId = toCategory.idValue;
        [toCategory addExpenseObject:expense];
    }
}

- (NSInteger)findMaxIdValueInEntity:(NSString *)entityName {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];

        // Specify that the request should return dictionaries.
    [request setResultType:NSDictionaryResultType];

        // Create an expression for the key path.
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(idValue))];

        // Create an expression to represent the maximum value at the key path 'creationDate'
    NSExpression *maxExpression = [NSExpression expressionForFunction:@"max:" arguments:[NSArray arrayWithObject:keyPathExpression]];

        // Create an expression description using the maxExpression and returning a date.
    NSExpressionDescription *expressionDescription = [[NSExpressionDescription alloc] init];

        // The name is the key that will be used in the dictionary for the return value.
    [expressionDescription setName:@"maxID"];
    [expressionDescription setExpression:maxExpression];
    [expressionDescription setExpressionResultType:NSInteger64AttributeType];

        // Set the request's properties to fetch just the property represented by the expressions.
    [request setPropertiesToFetch:@[expressionDescription]];

        // Execute the fetch.
    NSInteger maxID = -1;
    NSError *error = nil;
    NSArray *objects = [self.managedObjectContext executeFetchRequest:request error:&error];
    if (objects == nil) {
        NSAssert(NO, @"Must be at least one object");
    } else {
        maxID = [[[objects objectAtIndex:0] valueForKey:@"maxID"]integerValue];
        NSLog(@"Maximum id in %@: %ld", entityName, (long)maxID);
    }
    NSParameterAssert(maxID != -1);
    return maxID;
}

    //- (void)seedDataIfNeeded {
    //    NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
    //        //    ![kvStore boolForKey:@"SEEDED_DATA"] ||
    //    if (YES) {
    //        NSString *countryCode = [[NSLocale currentLocale]objectForKey: NSLocaleCountryCode];
    //        if ([countryCode isEqualToString:@"RU"]) {
    //            [CategoryData categoryDataWithTitle:@"Связь" iconName:@"SimCard" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Одежда" iconName:@"Clothes" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Здоровье" iconName:@"Hearts" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Продукты" iconName:@"Ingredients" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Еда вне дома" iconName:@"Cutlery" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Жилье" iconName:@"Exterior" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Поездки" iconName:@"Beach" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Электроника" iconName:@"SmartphoneTablet" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Развлечения" iconName:@"Controller" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //        } else if ([countryCode isEqualToString:@"US"]) {
    //            [CategoryData categoryDataWithTitle:@"Communication" iconName:@"SimCard" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Clothes" iconName:@"Clothes" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Healthcare" iconName:@"Hearts" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Foodstuffs" iconName:@"Ingredients" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"EatingOut" iconName:@"Cutlery" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Housing" iconName:@"Exterior" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Trip" iconName:@"Beach" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Electronics" iconName:@"SmartphoneTablet" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //            [CategoryData categoryDataWithTitle:@"Entertainment" iconName:@"Controller" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    //        } else {
    //            NSParameterAssert(NO);
    //        }
    //        [kvStore setBool:YES forKey:@"SEEDED_DATA"];
    //        [kvStore synchronize];
    //        
    //        [self saveContext];
    //        [self setCategoryId];
    //    }
    //}

@end