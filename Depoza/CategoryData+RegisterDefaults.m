//
//  CategoryData+RegisterDefaults.m
//  Depoza
//
//  Created by Ivan Magda on 24.01.15.
//  Copyright (c) 2015 Ivan Magda. All rights reserved.
//

#import "CategoryData+RegisterDefaults.h"
#import "SharedManagedObjectContext.h"

@implementation CategoryData (RegisterDefaultsCategories)

+ (void)registerDefaultsCategoriesInSharedContext:(SharedManagedObjectContext *)context {
    BOOL firtsTime = ([[NSUserDefaults standardUserDefaults]boolForKey:@"firstTime"] == NO);
    if (firtsTime) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"firstTime"];

        NSArray *categories = @[
                                @"Связь"       ,
                                @"Вещи"        ,
                                @"Здоровье"    ,
                                @"Продукты"    ,
                                @"Еда вне дома",
                                @"Жилье"       ,
                                @"Поездки"     ,
                                @"Другое"      ,
                                @"Развлечения"
                                ];
        
        for (int i = 0; i < [categories count]; ++i) {
            CategoryData *categoryData = (CategoryData *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([CategoryData class]) inManagedObjectContext:context.managedObjectContext];

            categoryData.title = categories[i];

            NSInteger categoryId = [defaults integerForKey:@"categoryId"];
            categoryData.idValue = @(categoryId);

            [defaults setInteger:categoryId + 1 forKey:@"categoryId"];
            [defaults synchronize];
        }
        [context saveContext];
    }
}

@end
