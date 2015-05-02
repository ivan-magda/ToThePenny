    //
    //  MIACollectionViewController.m
    //  Depoza
    //
    //  Created by Ivan Magda on 30.03.15.
    //  Copyright (c) 2015 Ivan Magda. All rights reserved.
    //

#import "CategoryIconsCollectionViewController.h"

#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:1.0]

@interface CategoryIconsCollectionViewController ()

@property (nonatomic, copy, readwrite) NSArray *iconNames;

@end

@implementation CategoryIconsCollectionViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    NSParameterAssert(_selectedIconName);
}

- (NSArray *)iconNames {
    if (_iconNames) {
        return _iconNames;
    } else {
        NSArray *names = @[
                           @"5StarHotel", @"Airplane", @"BabysRoom", @"Barbershop",
                           @"Beer", @"Bicycle", @"CarRental", @"Cars", @"Children",
                           @"Clinic", @"Clothes", @"Cocktail", @"CoffeeToGo",
                           @"Controller", @"CookingPot", @"CreditCard", @"Cutlery",
                           @"Documentary", @"Dumbbell", @"Exterior", @"GasStation",
                           @"Gift", @"Grapes", @"GroundTransportation", @"Hanger",
                           @"Hearts", @"Ingredients", @"Iphone", @"Jewelry",
                           @"Kitchenwares", @"Laptop", @"Literature", @"LivingRoom",
                           @"Mastercard", @"MoneyTransfer", @"Music", @"Puzzle",
                           @"Sale", @"ShoppingBag", @"ShoppingCartLoaded", @"SimCard",
                           @"SmartphoneTablet", @"Taxi", @"TheatreMask", @"Ticket",
                           @"Tomato", @"Truck", @"University", @"Visa", @"Beach"
                           ];

        return [names sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
    }
}

#pragma mark - UICollectionViewDataSource -

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.iconNames.count;
}

- (void)configureCell:(UICollectionViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSString *iconName = self.iconNames[indexPath.row];

    UIImageView *icon = (UIImageView *)[cell viewWithTag:5000];
    NSParameterAssert(icon);
    icon.image = [UIImage imageNamed:iconName];

    UIColor *color = [UIColorFromRGB(0x067AB5) colorWithAlphaComponent:0.5f];
    if ([iconName isEqualToString:_selectedIconName]) {
            //Background with Air Force Blue Color and corner radius
        cell.backgroundColor = color;
        cell.layer.cornerRadius = icon.bounds.size.width / 3.0f;
        icon.clipsToBounds = YES;
    } else if ([cell.backgroundColor isEqual:color] &&
               ![iconName isEqualToString:_selectedIconName]){
        cell.backgroundColor = [UIColor whiteColor];
        cell.layer.cornerRadius = 1;
        icon.clipsToBounds = NO;
    }
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CollectionCell" forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];

    return cell;
}

#pragma mark - UICollectionViewDelegate -

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];
    if (_isAddingNewCategoryMode) {
        [self performSegueWithIdentifier:@"IconPicked" sender:cell];
    } else {
        [self performSegueWithIdentifier:@"IconChanged" sender:cell];
    }
}

#pragma mark - Navigation -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    UICollectionViewCell *cell = sender;
    NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
    self.selectedIconName = self.iconNames[indexPath.row];
}

@end
