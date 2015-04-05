    //
    //  SharedManagedObjectContext.m
    //  Depoza
    //
    //  Created by Ivan Magda on 22/12/14.
    //  Copyright (c) 2014 Ivan Magda. All rights reserved.
    //

#import "Persistence.h"
#import "AppDelegate.h"
#import "CategoryData+Fetch.h"
#import "ExpenseData+Fetch.h"

static NSString * const kAppGroupSharedContainer = @"group.com.vanyaland.depoza";
static NSString * const kUbiquitousKeyValueStoreSeedDataKey = @"seedData";

@interface Persistence ()

@property (nonatomic,strong,readwrite) NSManagedObjectContext* managedObjectContext;
@property (nonatomic,strong) NSURL* modelURL;
@property (nonatomic,strong) NSURL* storeURL;

@end

@implementation Persistence {
    NSDictionary *_iCloudOptions;
}

+ (instancetype)sharedInstance {
    static Persistence *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        sharedInstance = appDelegate.persistence;
    });
    return sharedInstance;
}

- (id)initWithStoreURL:(NSURL*)storeURL modelURL:(NSURL*)modelURL {
    self = [super init];
    if (self) {
        self.storeURL = storeURL;
        self.modelURL = modelURL;
        NSParameterAssert(_storeURL && _modelURL);

        _iCloudOptions = @{NSPersistentStoreUbiquitousContentNameKey: @"DepozaCloudStore"};

        [self managedObjectContext];
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
        _managedObjectModel = [[NSManagedObjectModel alloc]initWithContentsOfURL:_modelURL];
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    if (!_persistentStoreCoordinator) {
        _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:self.managedObjectModel];

        [self addPersistentStoreNotificationSubscribes];

        NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
        if (![kvStore boolForKey:kUbiquitousKeyValueStoreSeedDataKey]) {
            [self seedInitialData:_persistentStoreCoordinator];
        } else {
            NSError *error = nil;
            if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:self.storeURL options:_iCloudOptions error:&error]) {
                NSLog(@"Error adding persistent store %@, %@", error, [error userInfo]);
                abort();
            }
            NSLog(@"The original seed is't needed, the is a backing store");
        }
    }
    return _persistentStoreCoordinator;
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

#pragma mark - SeedInitialData -

- (void)seedInitialData:(NSPersistentStoreCoordinator *)coordinator {
    NSURL *storeURL = self.storeURL;

    NSString *countryCode = [[NSLocale currentLocale]objectForKey: NSLocaleCountryCode];
    NSString *seedName = [NSString stringWithFormat:@"seed%@", countryCode];
    NSURL *seedStoreURL = [[NSBundle mainBundle]URLForResource:seedName withExtension:@"sqlite"];

    NSError *seedStoreError = nil;
    NSDictionary *seedStoreOptions = @{NSReadOnlyPersistentStoreOption: @YES};

    NSPersistentStore *seedStore = [coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:seedStoreURL options:seedStoreOptions error:&seedStoreError];

    NSError *error = nil;
    if (![coordinator migratePersistentStore:seedStore toURL:storeURL options:_iCloudOptions withType:NSSQLiteStoreType error:&error]) {
        NSLog(@"Error adding seed persistent store %@, %@", error, [error userInfo]);
    }
    NSLog(@"Store succesfully initialized using the original seed");

    NSUbiquitousKeyValueStore *kvStore = [NSUbiquitousKeyValueStore defaultStore];
    [kvStore setBool:YES forKey:kUbiquitousKeyValueStoreSeedDataKey];
}

- (void)insertNecessaryCategoryData {
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
    } else {
        [CategoryData categoryDataWithTitle:@"Communication" iconName:@"SimCard" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        [CategoryData categoryDataWithTitle:@"Clothes" iconName:@"Clothes" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        [CategoryData categoryDataWithTitle:@"Healthcare" iconName:@"Hearts" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        [CategoryData categoryDataWithTitle:@"Foodstuffs" iconName:@"Ingredients" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        [CategoryData categoryDataWithTitle:@"EatingOut" iconName:@"Cutlery" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        [CategoryData categoryDataWithTitle:@"Housing" iconName:@"Exterior" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        [CategoryData categoryDataWithTitle:@"Trip" iconName:@"Beach" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        [CategoryData categoryDataWithTitle:@"Electronics" iconName:@"SmartphoneTablet" andExpenses:nil inManagedObjectContext:_managedObjectContext];
        [CategoryData categoryDataWithTitle:@"Entertainment" iconName:@"Controller" andExpenses:nil inManagedObjectContext:_managedObjectContext];
    }
    [CategoryData setNextIdValueToUbiquitousKeyValueStore:9];
    [self saveContext];
}

#pragma mark - Handle iCloud Notifications -

- (void)removePersistentStoreNotificationSubscribes {
    NSLog(@"Persistence remove observers");
    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

- (void)addPersistentStoreNotificationSubscribes {
    NSLog(@"Persistence add observers");
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [notificationCenter addObserver:self selector:@selector(storeDidChange:) name:NSPersistentStoreCoordinatorStoresDidChangeNotification object:_persistentStoreCoordinator];
    [notificationCenter addObserver:self selector:@selector(storeDidImportUbiquitousContentChanges:) name:NSPersistentStoreDidImportUbiquitousContentChangesNotification object:_persistentStoreCoordinator];
    [notificationCenter addObserver:self selector:@selector(storeWillChange:) name:NSPersistentStoreCoordinatorStoresWillChangeNotification object:_persistentStoreCoordinator];
}

- (void)storeDidChange:(NSNotification *)notification {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, notification.userInfo.description);
        // At this point it's official, the change has happened. Tell your
        // user interface to refresh itself
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(persistenceStore:didChangeNotification:)]) {
            [self.delegate persistenceStore:self didChangeNotification:notification];
        }
    });
}

- (void)storeDidImportUbiquitousContentChanges:(NSNotification *)notification {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, notification.userInfo.description);
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.managedObjectContext mergeChangesFromContextDidSaveNotification:notification];

        if ([self.delegate respondsToSelector:@selector(persistenceStore:didImportUbiquitousContentChanges:)]) {
            [self.delegate persistenceStore:self didImportUbiquitousContentChanges:notification];
        }
    });
}

- (void)storeWillChange:(NSNotification *)notification {
    NSLog(@"%s %@", __PRETTY_FUNCTION__, notification.description);
    dispatch_async(dispatch_get_main_queue(), ^{
        NSUInteger persistentStoreUbiquitousTransitionType = [[notification.userInfo objectForKey:NSPersistentStoreUbiquitousTransitionTypeKey]unsignedIntegerValue];
        if (persistentStoreUbiquitousTransitionType == NSPersistentStoreUbiquitousTransitionTypeAccountRemoved) {
            NSLog(@"NSPersistentStoreUbiquitousTransitionTypeAccountRemoved");
            NSError *saveError;
            if (![self.managedObjectContext save:&saveError]) {
                NSLog(@"Save error: %@", [saveError localizedDescription]);
            }
            [self.managedObjectContext reset];
            return;
        }

        if ([self.managedObjectContext hasChanges]) {
            NSError *saveError;
            if (![self.managedObjectContext save:&saveError]) {
                NSLog(@"Save error: %@", [saveError localizedDescription]);
            }
        } else {
            [self.managedObjectContext reset];
        }
            // This is a good place to let your UI know it needs to get ready
            // to adjust to the change and deal with new data. This might include
            // invalidating UI caches, reloading data, resetting views, etc...

        if ([self.delegate respondsToSelector:@selector(persistenceStore:willChangeNotification:)]) {
            [self.delegate persistenceStore:self willChangeNotification:notification];
        }
    });
}

#pragma mark - Deduplication -

- (void)deduplication {
    [self deduplicationCategories];
    [self deduplicationExpenses];

    NSInteger categoryMaxID = [self findMaxIdValueInEntity:NSStringFromClass([CategoryData class])];
    NSInteger expenseMaxID  = [self findMaxIdValueInEntity:NSStringFromClass([ExpenseData class])];

    [CategoryData setNextIdValueToUbiquitousKeyValueStore:categoryMaxID + 1];
    [ExpenseData setNextIdValueToUbiquitousKeyValueStore:expenseMaxID + 1];
}

- (void)deduplicationCategories {
    NSString *uniquePropertyKey = NSStringFromSelector(@selector(title));
    NSArray *valuesWithDupes = [self valuesWithDupesInEntity:NSStringFromClass([CategoryData class]) uniquePropertyKey:uniquePropertyKey];

    if (valuesWithDupes.count > 0) {
        NSLog(@"%s duplications found in categories", __PRETTY_FUNCTION__);
            //Use a predicate to fetch all of the records with duplicates.
            //Use a sort descriptor to properly order the results for the winner algorithm in the next step.
        NSFetchRequest *dupeFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([CategoryData class])];
        [dupeFetchRequest setIncludesPendingChanges:NO];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"title IN (%@)", valuesWithDupes];
        [dupeFetchRequest setPredicate:predicate];

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:uniquePropertyKey ascending:NO];
        [dupeFetchRequest setSortDescriptors:@[sortDescriptor]];

        NSManagedObjectContext *context = self.managedObjectContext;

        NSArray *dupes = [context executeFetchRequest:dupeFetchRequest error:nil];
            //Choose the winner.
            //After retrieving all of the duplicates, your app decides which ones to keep. This decision must be deterministic, meaning that every peer should always choose the same winner. Among other methods, your app could store a created or last-changed timestamp for each record and then decide based on that.
        CategoryData *prevObject;
        for (CategoryData *duplicate in dupes) {
            if (prevObject) {
                if ([duplicate.title isEqualToString:prevObject.title]) {
                    if (duplicate.expense.count < prevObject.expense.count) {
                        if (duplicate.expense.count > 0) {
                            [self moveExpensesToCategory:prevObject fromCategory:duplicate];
                        }
                        [context deleteObject:duplicate];
                    } else {
                        if (prevObject.expense.count > 0) {
                            [self moveExpensesToCategory:duplicate fromCategory:prevObject];
                        }
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
    }
}

- (NSArray *)valuesWithDupesInEntity:(NSString *)entityName uniquePropertyKey:(NSString *)uniqueProperty {
        //Choose a property or a hash of multiple properties to use as a unique ID for each record.
    NSString *uniquePropertyKey = uniqueProperty;
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:uniquePropertyKey];
    NSExpression *countExpression = [NSExpression expressionForFunction: @"count:" arguments:@[keyPathExpression]];
    NSExpressionDescription *countExpressionDescription = [NSExpressionDescription new];

    [countExpressionDescription setName:@"count"];
    [countExpressionDescription setExpression:countExpression];
    [countExpressionDescription setExpressionResultType:NSInteger64AttributeType];

    NSManagedObjectContext *context = self.managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:entityName inManagedObjectContext:context];

    NSAttributeDescription *uniqueAttribute = [[entity attributesByName]objectForKey:uniquePropertyKey];

        //Fetch the number of times each unique value appears in the store.
        //The context returns an array of dictionaries, each containing a unique value and the number of times that value appeared in the store.
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:entityName];
    [fetchRequest setPropertiesToFetch:@[uniqueAttribute, countExpressionDescription]];
    [fetchRequest setPropertiesToGroupBy:@[uniqueAttribute]];
    [fetchRequest setResultType:NSDictionaryResultType];
    NSArray *fetchedDictionaries = [context executeFetchRequest:fetchRequest error:nil];

        //Filter out unique values that have no duplicates.
    NSMutableArray *valuesWithDupes = [NSMutableArray array];
    for (NSDictionary *dict in fetchedDictionaries) {
        NSNumber *count = dict[@"count"];
        if ([count integerValue] > 1) {
            [valuesWithDupes addObject:dict[uniquePropertyKey]];
        }
    }
    return [valuesWithDupes copy];
}

- (void)moveExpensesToCategory:(CategoryData *)toCategory fromCategory:(CategoryData *)fromCategory {
    for (ExpenseData *expense in fromCategory.expense) {
        [expense.category removeExpenseObject:expense];

        expense.category = toCategory;
        expense.categoryId = toCategory.idValue;
        [toCategory addExpenseObject:expense];
    }
}

- (void)deduplicationExpenses {
    NSString *uniquePropertyKey = NSStringFromSelector(@selector(idValue));
    NSArray *valuesWithDupes = [self valuesWithDupesInEntity:NSStringFromClass([ExpenseData class]) uniquePropertyKey:uniquePropertyKey];

    if (valuesWithDupes.count > 0) {
        NSLog(@"%s duplications found in expenses", __PRETTY_FUNCTION__);
            //Use a predicate to fetch all of the records with duplicates.
            //Use a sort descriptor to properly order the results for the winner algorithm in the next step.
        NSFetchRequest *dupeFetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];
        [dupeFetchRequest setIncludesPendingChanges:NO];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"idValue IN (%@)", valuesWithDupes];
        [dupeFetchRequest setPredicate:predicate];

        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:uniquePropertyKey ascending:NO];
        [dupeFetchRequest setSortDescriptors:@[sortDescriptor]];

        NSManagedObjectContext *context = self.managedObjectContext;

        NSArray *dupes = [context executeFetchRequest:dupeFetchRequest error:nil];
            //Choose the winner.
            //After retrieving all of the duplicates, your app decides which ones to keep. This decision must be deterministic, meaning that every peer should always choose the same winner. Among other methods, your app could store a created or last-changed timestamp for each record and then decide based on that.
        ExpenseData *prevObject;
        for (ExpenseData *duplicate in dupes) {
            if (prevObject) {
                if (duplicate.idValue == prevObject.idValue) {
                    if ([duplicate.categoryId integerValue] == [prevObject.categoryId integerValue] &&
                        [duplicate.amount floatValue] == [prevObject.amount floatValue] &&
                        [duplicate.descriptionOfExpense isEqualToString:prevObject.descriptionOfExpense]) {
                        [context deleteObject:duplicate];
                    } else {
                        NSInteger expenseNextId  = [self findMaxIdValueInEntity:NSStringFromClass([ExpenseData class])] + 1;
                        prevObject.idValue = @(expenseNextId);

                        prevObject = duplicate;
                    }
                } else {
                    prevObject = duplicate;
                }
            } else {
                prevObject = duplicate;
            }
        }
    }
}

- (NSInteger)findMaxIdValueInEntity:(NSString *)entityName {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:entityName];

        // Specify that the request should return dictionaries.
    [request setResultType:NSDictionaryResultType];

        // Create an expression for the key path.
    NSExpression *keyPathExpression = [NSExpression expressionForKeyPath:NSStringFromSelector(@selector(idValue))];

        // Create an expression to represent the maximum value at the key path 'creationDate'
    NSExpression *maxExpression = [NSExpression expressionForFunction:@"max:" arguments:@[keyPathExpression]];

        // Create an expression description using the maxExpression and returning a date.
    NSExpressionDescription *expressionDescription = [NSExpressionDescription new];

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