    //AppDelegate
#import "AppDelegate.h"
    //ViewControllers
#import "MainViewController.h"
#import "AddExpenseTableViewController.h"
#import "DetailExpenseTableViewController.h"
#import "CategoriesContainerViewController.h"
#import "MainTableViewProtocolsImplementer.h"
#import "SelectTimePeriodViewController.h"
#import "ManageCategoryTableViewController.h"
#import "CategoriesTableViewController.h"
#import "PieChartTableViewController.h"
#import "MotionEffectWithTiltAlongVerticalAndHorizontalAxis.h"
    //View
#import "TitleViewButton.h"
    //CoreData
#import "Expense.h"
#import "ExpenseData+Fetch.h"
#import "CategoryData+Fetch.h"
#import "Fetch.h"
#import "CategoriesInfo.h"
    //Categories
#import "NSDate+StartAndEndDatesOfTheCurrentDate.h"
#import "NSDate+FirstAndLastDaysOfMonth.m"
#import "NSDate+IsDateBetweenCurrentMonth.h"
#import "NSDate+IsDatesWithEqualMonth.h"
#import "NSDate+IsDatesWithEqualYear.h"
#import "NSDate+NextMonthFirstDate.h"
#import "NSDate+TomorrowDate.h"
#import "NSString+FormatAmount.h"
    //Transition
#import "ZFModalTransitionAnimator.h"
    //SmileTouchID
#import <SmileTouchID/SmileAuthenticator.h>

static const CGFloat kMotionEffectMagnitudeValue = 10.0f;

static NSString * const kAddExpenseOnStartupKey = @"AddExpenseOnStartup";
NSString * const SmileTouchIdUserSuccessAuthenticationNotification = @"smileTouchIdUserSuccessAuthentication";

static NSString * const kDetailExpenseTableViewControllerSegueIdentifier = @"MoreInfo";

/*!
 * The default constant value of info view height equals to 227.0f.
 */
static const CGFloat kDefaultInfoViewHeightValue = 227.0f;

/*!
 * The reduced constant value of info view height equals to 158.0f. 
 * This value uses when categories count <= 4.
 */
static const CGFloat kReducedInfoViewHeightValue = 158.0f;

NSString * const ContinuingActivityRepresentsSearchableExpenseNotification = @"ContinuingActivityRepresentsSearchableExpense";


@interface MainViewController () <NSFetchedResultsControllerDelegate>

@property (weak, nonatomic) CategoriesContainerViewController *containerView;

@property (weak, nonatomic) IBOutlet UILabel *totalExpensesLabel;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *addTransactionRoundedButton;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *containerViewHeightConstraint;

@property (nonatomic, strong) NSFetchedResultsController *todayFetchedResultsController;
@property (nonatomic, strong) NSFetchedResultsController *monthFetchedResultsController;
@property (nonatomic, strong) MainTableViewProtocolsImplementer *tableViewProtocolsImplementer;

@property (nonatomic, strong) ZFModalTransitionAnimator *transitionAnimator;

@end

#pragma mark - Implementation -

@implementation MainViewController {
    CGFloat _totalExpenses;
    NSMutableArray *_categoriesInfo;

    SelectTimePeriodViewController *_selectTimePeriodViewController;
    TitleViewButton *_titleViewButton;
    NSDate *_dateToShow;

    //BOOL _isFirstTimeFetchForCategoriesInfo;
    BOOL _selectMonthIsVisible;
}

#pragma mark - ViewController life cycle -

- (void)viewDidLoad {
    [super viewDidLoad];

    [self assertionCheck];

        //Present table view with smooth animation at start up
    if (!_isShowExpenseDetailFromExtension &&
        ![[NSUserDefaults standardUserDefaults]boolForKey:kAddExpenseOnStartupKey]) {
        self.tableView.alpha = 0.0f;
    }

    [self initializeLocalVariables];
    [self configurateTimer];

    [self configurateTableAndFetchedControllers];
    [self configurateTitleViewButton];

    [MotionEffectWithTiltAlongVerticalAndHorizontalAxis addMotionEffectToView:self.tableView magnitude:kMotionEffectMagnitudeValue];
    [MotionEffectWithTiltAlongVerticalAndHorizontalAxis addMotionEffectToView:_addTransactionRoundedButton magnitude:kMotionEffectMagnitudeValue];
    [self addNotificationSubscribes];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.addTransactionRoundedButton.accessibilityIdentifier = @"add_button";
    self.totalExpensesLabel.accessibilityIdentifier = @"total_expenses_amount";
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusBarTappedAction:) name:StatusBarTappedNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([SmileAuthenticator hasPassword]) {
        [SmileAuthenticator sharedInstance].securityType = INPUT_TOUCHID;
        [[SmileAuthenticator sharedInstance] presentAuthViewControllerAnimated:YES];
    }

    if (self.tableView.alpha == 0.0f) {
        [UIView animateWithDuration:1.0 animations:^{
            self.tableView.alpha = 1.0f;
        }];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:StatusBarTappedNotification object:nil];
}

- (void)dealloc {
    _todayFetchedResultsController.delegate = nil;
    _monthFetchedResultsController.delegate = nil;

    [[NSNotificationCenter defaultCenter]removeObserver:self];
}

#pragma mark - Helper methods -
#pragma mark Private

- (void)assertionCheck {
    NSParameterAssert(_managedObjectContext);
    NSParameterAssert(self.delegate);
}

- (void)initializeLocalVariables {
    _isAddExpensePresenting = NO;
    _selectMonthIsVisible = NO;

    _dateToShow = [NSDate date];

    self.totalExpensesLabel.text = @"";
}

- (void)configurateTableAndFetchedControllers {
    self.tableViewProtocolsImplementer = [[MainTableViewProtocolsImplementer alloc]initWithTableView:self.tableView fetchedResultsController:self.todayFetchedResultsController];

    self.todayFetchedResultsController.delegate = _tableViewProtocolsImplementer;
    self.monthFetchedResultsController.delegate = self;

    self.tableView.dataSource = _tableViewProtocolsImplementer;
    self.tableView.delegate   = _tableViewProtocolsImplementer;

    [NSFetchedResultsController deleteCacheWithName:@"todayFetchedResultsController"];
    [NSFetchedResultsController deleteCacheWithName:@"monthFetchedResultsController"];
}

- (void)setScrollViewContentOffsetToZeroWithAnimation:(BOOL)animated {
    UIScrollView *scrollView = (UIScrollView *)self.tableView;
    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, 0.0f) animated:animated];
}

- (void)performAddExpense {
    if (_categoriesInfo.count == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.05 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self performAddExpense];
        });
    } else {
        if (_selectMonthIsVisible) {
            NSParameterAssert(_selectTimePeriodViewController != nil);
            
            _selectMonthIsVisible = NO;
            
            [_selectTimePeriodViewController dismissFromParentViewController];
            [self changeMonthToShowFromDate:[NSDate date]];
        }
        [self performSegueWithIdentifier:@"AddExpense" sender:nil];
    }
}

#pragma mark FetchCategoriesData

- (void)updateUserInterfaceWithNewFetch:(BOOL)fetch {
    [self loadCategoriesDataBetweenDate:[NSDate date]];

    [self presentAddExpenseViewControllerIfNeeded];

    [self notificateCategoriesContainerViewControllerWithNewCategoriesInfo:_categoriesInfo];

    if (fetch) {
        [self performFetches];
        [self.tableView reloadData];
    }

    [self updateAmountLabel];
}

- (void)performFetches {
    [self todayPerformFetch];
    [self monthPerformFetch];
}

- (void)loadCategoriesDataBetweenDate:(NSDate *)date {
    _categoriesInfo = [Fetch loadCategoriesInfoInContext:self.managedObjectContext totalExpenses:& _totalExpenses andBetweenMonthDate:date];
}

- (void)notificateCategoriesContainerViewControllerWithNewCategoriesInfo:(NSArray *)categoriesInfo {
    NSArray *categories = [self cleanUpCategoriesInfoWithInfo:categoriesInfo];

    [self updateTableHeaderViewLayoutFromNumberOfCategories:categories.count];

    [self.delegate mainViewController:self didLoadCategoriesInfo:categories];
}

- (NSArray *)cleanUpCategoriesInfoWithInfo:(NSArray *)categories {
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc]initWithKey:@"amount" ascending:NO];
    NSMutableArray *categoriesInfo = [[categories sortedArrayUsingDescriptors:@[sortDescriptor]]mutableCopy];

    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (CategoriesInfo *anInfo in categoriesInfo) {
        if ([anInfo.amount floatValue] == 0) {
            [indexSet addIndex:[categoriesInfo indexOfObject:anInfo]];
        }
    }

    [categoriesInfo removeObjectsAtIndexes:indexSet];

    return [categoriesInfo copy];
}

- (void)addCategoryToCategoriesInfo:(CategoryData *)category {
    CategoriesInfo *info = [[CategoriesInfo alloc]initWithTitle:category.title iconName:category.iconName idValue:category.idValue andAmount:@0];
    [_categoriesInfo addObject:info];

    [self notificateCategoriesContainerViewControllerWithNewCategoriesInfo:_categoriesInfo];
}

#pragma mark UIUpdates

- (void)updateAmountLabel {
    self.totalExpensesLabel.text = [NSString formatAmount:@(_totalExpenses)];
}

- (void)updateTableHeaderViewLayoutFromNumberOfCategories:(NSInteger)categoriesCount{
    [self.view layoutIfNeeded];

    BOOL isTwoCollumns = (categoriesCount >= 5);
    BOOL isEmpty = (categoriesCount == 0);

        //Hide page control if numberOfPages == 1(categoriesCount > 8)
    CGFloat spaceBetweenCollectionView = 8.0f;
    CGFloat adjustment = (categoriesCount <= 8 ? DefaultPageControlHeightValue - spaceBetweenCollectionView : 0);

    if (isEmpty) {
        self.containerViewHeightConstraint.constant = ReducedContainerViewHeightValue;
        self.containerView.collectionViewHeightConstraint.constant = 0.0f;
    } else if (isTwoCollumns) {
        self.containerViewHeightConstraint.constant = DefaultContainerViewHeightValue - adjustment;
        self.containerView.collectionViewHeightConstraint.constant = DefaultCollectionViewHeightValue;
    } else {
        self.containerViewHeightConstraint.constant = ReducedContainerViewHeightValue - adjustment;
        self.containerView.collectionViewHeightConstraint.constant = ReducedCollectionViewHeightValue;
    }

    [self.view layoutIfNeeded];
    self.containerView.collectionView.alpha = 0.0f;

    if (isTwoCollumns) {
        CGRect frame =  CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), kDefaultInfoViewHeightValue - adjustment);
        [self changeHeightTableHeaderViewWithAnimationFromFrame:frame];
    } else {
        CGRect frame =  CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), kReducedInfoViewHeightValue - adjustment);
        [self changeHeightTableHeaderViewWithAnimationFromFrame:frame];
    }
}

- (void)changeHeightTableHeaderViewWithAnimationFromFrame:(CGRect)frame {
    dispatch_async(dispatch_get_main_queue(), ^{
        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.25];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        self.tableView.tableHeaderView.frame = frame;
        self.tableView.tableHeaderView = self.tableView.tableHeaderView;
        [UIView commitAnimations];

        [UIView beginAnimations:nil context:nil];
        [UIView setAnimationDuration:0.5f];
        [UIView setAnimationCurve:UIViewAnimationCurveLinear];
        self.containerView.collectionView.alpha = 1.0f;
        [UIView commitAnimations];
    });
}

- (NSString *)formatDateForMonthLabel:(NSDate *)theDate {
    static NSDateFormatter *month = nil;
    
    if (month == nil) {
        month = [NSDateFormatter new];
        [month setDateFormat:@"MMMM"];
        
        if ([[[NSLocale currentLocale]objectForKey:NSLocaleCountryCode]isEqualToString:@"RU"]) {
            [month setMonthSymbols:@[@"Январь", @"Февраль", @"Март", @"Апрель", @"Май", @"Июнь", @"Июль", @"Август", @"Сентябрь", @"Октябрь", @"Ноябрь", @"Декабрь"]];
        }
        
    }
    
    NSDate *date = [NSDate date];
    if (![date isDatesWithEqualYear:theDate]) {
        static NSDateFormatter *year = nil;
        
        if (!year) {
            year = [NSDateFormatter new];
            [year setDateFormat:@"YYYY"];
        }
        
        NSString *monthString = [month stringFromDate:theDate];
        NSString *yearString  = [year stringFromDate:theDate];
        
        return [NSString stringWithFormat:@"%@ %@", monthString, yearString];
    }
    
    return [month stringFromDate:theDate];
}

#pragma mark ChangeMonth

- (void)changeMonthToShowFromDate:(NSDate *)date {
    if ([_dateToShow isDatesWithEqualMonth:date]) {
        _titleViewButton.imageView.transform = CGAffineTransformMakeRotation(0);
        return;
    }

    [self reloadMonthDataWithDate:date];
}

- (void)reloadMonthDataWithDate:(NSDate *)date {
    _dateToShow = date;
    
    [self loadCategoriesDataBetweenDate:_dateToShow];
    [self notificateCategoriesContainerViewControllerWithNewCategoriesInfo:_categoriesInfo];
    
    [NSFetchedResultsController deleteCacheWithName:@"todayFetchedResultsController"];
    [NSFetchedResultsController deleteCacheWithName:@"monthFetchedResultsController"];
    
    NSArray *todayDates = nil;
    NSPredicate *todayPredicate = nil;
    NSArray *monthDates = [_dateToShow getFirstAndLastDatesFromMonth];
    NSPredicate *monthPredicate = [ExpenseData compoundPredicateBetweenDates:monthDates];
    
    if ([NSDate isDateBetweenCurrentMonth:_dateToShow]) {
        todayDates = [NSDate getStartAndEndDatesOfTheCurrentDate];
        todayPredicate = [ExpenseData compoundPredicateBetweenDates:todayDates];
    } else {
        todayDates = [_dateToShow getFirstAndLastDatesFromMonth];
        todayPredicate = [ExpenseData compoundPredicateBetweenDates:todayDates];
    }
    
    self.todayFetchedResultsController.fetchRequest.predicate = todayPredicate;
    self.monthFetchedResultsController.fetchRequest.predicate = monthPredicate;
    [self performFetches];
    
    [self.tableView reloadData];
    
    [self updateAmountLabel];
    
    _titleViewButton = nil;
    [self configurateTitleViewButton];
}

#pragma mark NSTimer

- (void)configurateTimer {
    NSDate *fireDate = [[NSDate date]tomorrowDate];
    NSTimer *timer = [[NSTimer alloc]initWithFireDate:fireDate interval:0 target:self selector:@selector(timerDidFire:) userInfo:nil repeats:NO];
    
    NSRunLoop *runner = [NSRunLoop currentRunLoop];
    [runner addTimer:timer forMode:NSDefaultRunLoopMode];
}

- (void)timerDidFire:(NSTimer *)timer {
        //next day
    if ([timer.fireDate isDateBetweenMonth:_dateToShow]) {
        _dateToShow = [NSDate date];
        NSArray *todayDates = [NSDate getStartAndEndDatesOfTheCurrentDate];
        
        [NSFetchedResultsController deleteCacheWithName:@"todayFetchedResultsController"];
        self.todayFetchedResultsController.fetchRequest.predicate = [ExpenseData compoundPredicateBetweenDates:todayDates];
        
        [self todayPerformFetch];
        [self.tableView reloadData];
        
        //next month
    } else if ([[NSDate date]isDatesWithEqualMonth:_dateToShow] &&
               [timer.fireDate isDatesWithEqualMonth:[_dateToShow nextMonthFirstDate]]) {
        [self reloadMonthDataWithDate:timer.fireDate];
    }
    
    [self configurateTimer];
}

#pragma mark Public

- (void)presentAddExpenseViewControllerIfNeeded {
    if ([[NSUserDefaults standardUserDefaults]boolForKey:kAddExpenseOnStartupKey]) {
        if (!_isShowExpenseDetailFromExtension && ![SmileAuthenticator hasPassword]) {
            [self performAddExpense];
        } else {
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(smileTouchIdUserSuccessAuthentication) name:SmileTouchIdUserSuccessAuthenticationNotification object:nil];
        }
    }
    _isShowExpenseDetailFromExtension = NO;
}

- (BOOL)isAddExpensePresenting {
    return _isAddExpensePresenting;
}

- (BOOL)isSelectMonthIsPresenting {
    return _selectMonthIsVisible;
}

- (void)dismissSelectMonthViewController {
    NSParameterAssert(_selectTimePeriodViewController != nil);

    [_selectTimePeriodViewController dismissFromParentViewController];
    _selectMonthIsVisible = NO;
}

#pragma mark - TitleViewButton -

- (void)configurateTitleViewButton {
    _titleViewButton = [TitleViewButton buttonWithType:UIButtonTypeCustom];

    NSString *text = [NSString stringWithFormat:@"%@ ",[self formatDateForMonthLabel:_dateToShow]];
    [_titleViewButton setTitle:text forState:UIControlStateNormal];
    _titleViewButton.titleLabel.font = [UIFont boldSystemFontOfSize:18.0];
    _titleViewButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    [_titleViewButton setTitleColor:[UIColor colorWithRed:245.0/255.0 green:245.0/255.0 blue:245.0/255.0 alpha:1.0] forState:UIControlStateNormal];

    UIImage *image = [UIImage imageNamed:@"Down.png"];
    [_titleViewButton setImage:image forState:UIControlStateNormal];
    [_titleViewButton sizeToFit];

    [_titleViewButton addTarget:self action:@selector(titleViewButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.titleView = _titleViewButton;
}

- (void)titleViewButtonPressed:(UIButton *)button {
    [UIView animateWithDuration:0.25 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        _titleViewButton.imageView.transform = CGAffineTransformMakeRotation((CGFloat)180.0 * M_PI/180.0);
    } completion:nil];

    _selectTimePeriodViewController = [[SelectTimePeriodViewController alloc]initWithNibName:NSStringFromClass([SelectTimePeriodViewController class]) bundle:nil];

    _selectTimePeriodViewController.managedObjectContext = self.managedObjectContext;
    _selectTimePeriodViewController.delegate = self;
    _selectTimePeriodViewController.isSelectMonthMode = YES;

    [_selectTimePeriodViewController presentInParentViewController:self.tabBarController];

    _selectMonthIsVisible = YES;
}

#pragma mark - Segues -

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"AddExpense"]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self changeMonthToShowFromDate:[NSDate date]];
        });

        _isAddExpensePresenting = YES;

        UINavigationController *navigationController = segue.destinationViewController;

        AddExpenseTableViewController *controller = (AddExpenseTableViewController *)navigationController.topViewController;
        controller.delegate = self;
        controller.managedObjectContext = _managedObjectContext;
        controller.categoriesInfo = _categoriesInfo;

            // create animator object with instance of modal view controller
            // we need to keep it in property with strong reference so it will not get release
        self.transitionAnimator = [[ZFModalTransitionAnimator alloc] initWithModalViewController:navigationController];
        self.transitionAnimator.transitionDuration = 0.7f;
        self.transitionAnimator.bounces = NO;
        self.transitionAnimator.behindViewAlpha = 0.5f;
        self.transitionAnimator.behindViewScale = 0.7f;
        self.transitionAnimator.direction = ZFModalTransitonDirectionRight;

            // set transition delegate of modal view controller to our object
        navigationController.transitioningDelegate = _transitionAnimator;
        navigationController.modalPresentationStyle = UIModalPresentationCustom;

    } else if ([segue.identifier isEqualToString:kDetailExpenseTableViewControllerSegueIdentifier]) {
        DetailExpenseTableViewController *controller = segue.destinationViewController;
        controller.managedObjectContext = _managedObjectContext;

        if ([sender isKindOfClass:[UITableViewCell class]]) {
            UITableViewCell *cell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];

            ExpenseData *expense = [_todayFetchedResultsController objectAtIndexPath:indexPath];
            controller.expenseToShow = expense;
        } else if ([sender isKindOfClass:[ExpenseData class]]) {
            ExpenseData *expense = sender;
            controller.expenseToShow = expense;
        }
        _isAddExpensePresenting = NO;
    } else if ([segue.identifier isEqualToString:@"CategoriesInfo"]) {
        CategoriesContainerViewController *controller = segue.destinationViewController;
        controller.managedObjectContext = self.managedObjectContext;
        controller.timePeriod = _dateToShow;
        controller.delegate = self;

        self.delegate = controller;
        self.containerView = controller;
    } else if ([segue.identifier isEqualToString:@"PieChart"]) {
        PieChartTableViewController *controller = segue.destinationViewController;
        controller.managedObjectContext = _managedObjectContext;
        controller.dateToShow = _dateToShow;
    }
}

#pragma mark - Delegate -
#pragma mark AddExpenseTableViewControllerDelegate

- (void)addExpenseTableViewController:(AddExpenseTableViewController *)controller didFinishAddingExpense:(Expense *)expense {
    _isAddExpensePresenting = NO;

    if (![[NSDate date]isDatesWithEqualMonth:expense.dateOfExpense]) {
        return;
    }

    _totalExpenses += [expense.amount floatValue];

    [_categoriesInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        NSParameterAssert([obj isKindOfClass:[CategoriesInfo class]]);
        CategoriesInfo *anInfo = obj;

        if ([anInfo.title isEqualToString:expense.category]) {
            [self updateCategoriesExpensesDataAtIndex:idx withValue:expense.amount.floatValue];

            *stop = YES;
        }

    }];

    [self notificateCategoriesContainerViewControllerWithNewCategoriesInfo:_categoriesInfo];

    [self updateAmountLabel];
}

- (void)updateCategoriesExpensesDataAtIndex:(NSInteger)index withValue:(CGFloat)amount {
    CategoriesInfo *info = _categoriesInfo[(NSInteger)index];
    CGFloat value = [[info amount] floatValue] + amount;

    info.amount = @(value);
}

- (void)addExpenseTableViewControllerDidCancel:(AddExpenseTableViewController *)controller {
    _isAddExpensePresenting = NO;
}

- (void)addExpenseTableViewController:(AddExpenseTableViewController *)controller didAddCategory:(CategoryData *)category {
    [self addCategoryToCategoriesInfo:category];
}

#pragma mark SelectTimePeriodViewControllerDelegate

- (void)selectTimePeriodViewController:(SelectTimePeriodViewController *)selectMonthViewController didSelectValue:(NSDictionary *)monthInfo {
    _selectMonthIsVisible = NO;

    NSDate *date = [self dateFromMonthInfo:monthInfo];

    [self changeMonthToShowFromDate:date];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setScrollViewContentOffsetToZeroWithAnimation:YES];
    });
}

- (NSDate *)dateFromMonthInfo:(NSDictionary *)monthInfo {
    NSCalendar *calendar = [NSCalendar currentCalendar];

    NSDateComponents *dayComponents = [NSDateComponents new];
    dayComponents.year = [monthInfo[@"year"]integerValue];
    dayComponents.month = [monthInfo[@"month"]integerValue];
    dayComponents.day = 10;
    NSDate *date = [calendar dateFromComponents:dayComponents];

    return date;
}

#pragma mark CategoriesContainerViewControllerDelegate

- (void)categoriesContainerViewController:(CategoriesContainerViewController *)controller didChooseCategory:(CategoriesInfo *)category {
    controller.timePeriod = _dateToShow;
}

#pragma mark - NSNotificationCenter -
#pragma mark AddSubscribes

- (void)addNotificationSubscribes {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(applicationWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(detailExpenseTableViewControllerDidFinishUpdateExpense:) name:DetailExpenseTableViewControllerDidUpdateNotification object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(manageCategoryTableViewControllerDidAddCategory:) name:ManageCategoryTableViewControllerDidAddCategoryNotification object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(manageCategoryTableViewControllerDidUpdateCategory:) name:ManageCategoryTableViewControllerDidUpdateCategoryNotification object:nil];

    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(categoriesTableViewControllerDidRemoveCategory:) name:CategoriesTableViewControllerDidRemoveCategoryNotification object:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(presentSearchedExpenseFromSpotlight:) name:ContinuingActivityRepresentsSearchableExpenseNotification object:nil];
}

#pragma mark - HandleNotifications

- (void)applicationWillResignActive {
    [self changeMonthToShowFromDate:[NSDate date]];
}

- (void)statusBarTappedAction:(NSNotification *)notification {
    [self setScrollViewContentOffsetToZeroWithAnimation:YES];
}

- (void)smileTouchIdUserSuccessAuthentication {
    [[NSNotificationCenter defaultCenter]removeObserver:self name:SmileTouchIdUserSuccessAuthenticationNotification object:nil];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self performAddExpense];
    });
}

- (void)presentSearchedExpenseFromSpotlight:(NSNotification *)notification {
    ExpenseData *expense = (ExpenseData *)notification.object;
    [self performSegueWithIdentifier:kDetailExpenseTableViewControllerSegueIdentifier sender:expense];
}

#pragma mark DetailExpenseTableViewControllerNotification

- (void)detailExpenseTableViewControllerDidFinishUpdateExpense:(NSNotification *)notification {
    [self loadCategoriesDataBetweenDate:_dateToShow];
    [self notificateCategoriesContainerViewControllerWithNewCategoriesInfo:_categoriesInfo];
    [self updateAmountLabel];
}

#pragma mark ManageCategoryTableViewControllerNotification

- (void)manageCategoryTableViewControllerDidAddCategory:(NSNotification *)notification {
    CategoryData *category = notification.object;
    [self addCategoryToCategoriesInfo:category];
}

- (void)manageCategoryTableViewControllerDidUpdateCategory:(NSNotification *)notification {
    CategoryData *updatedCategory = notification.object;

    [_categoriesInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        CategoriesInfo *anInfo = obj;
        if (anInfo.idValue == updatedCategory.idValue) {
            anInfo.title = updatedCategory.title;
            anInfo.iconName = updatedCategory.iconName;

            *stop = YES;
        }
    }];

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];

    [self notificateCategoriesContainerViewControllerWithNewCategoriesInfo:_categoriesInfo];
}

#pragma mark CategoriesTableViewControllerDidRemoveCategoryNotification

- (void)categoriesTableViewControllerDidRemoveCategory:(NSNotification *)notification {
    [self loadCategoriesDataBetweenDate:_dateToShow];
    [self notificateCategoriesContainerViewControllerWithNewCategoriesInfo:_categoriesInfo];
    [self updateAmountLabel];
}

#pragma mark - NSFetchedResultsController -
#pragma mark Today

- (NSFetchedResultsController *)todayFetchedResultsController {
    if (_todayFetchedResultsController) {
        return _todayFetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

        //Create compound predicate: dateOfExpense >= dates[0] AND dateOfExpense <= dates[1]
    NSArray *dates = [NSDate getStartAndEndDatesOfTheCurrentDate];
    NSPredicate *predicate = [ExpenseData compoundPredicateBetweenDates:dates];
    fetchRequest.predicate = predicate;

    NSSortDescriptor *dateSortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO];
    [fetchRequest setSortDescriptors:@[dateSortDescriptor]];
    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *theFetchedResultsController =
    [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                        managedObjectContext:_managedObjectContext
                                          sectionNameKeyPath:nil
                                                   cacheName:@"todayFetchedResultsController"];
    _todayFetchedResultsController = theFetchedResultsController;

    return _todayFetchedResultsController;
}

- (void)todayPerformFetch {
    NSError *todayError;
    if (![self.todayFetchedResultsController performFetch:&todayError]) {
        NSLog(@"Unresolved error %@, %@", todayError, [todayError userInfo]);
        exit(-1);  // Fail
    }
}

#pragma mark Month

- (NSFetchedResultsController *)monthFetchedResultsController {
    if (_monthFetchedResultsController) {
        return _monthFetchedResultsController;
    }
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass([ExpenseData class])];

        //Create compound predicate: dateOfExpense >= dates[0] AND dateOfExpense <= dates[1]
    NSArray *dates = [NSDate getFirstAndLastDatesFromCurrentMonth];
    NSPredicate *predicate = [ExpenseData compoundPredicateBetweenDates:dates];
    fetchRequest.predicate = predicate;

    NSSortDescriptor *dateSortDescriptor = [[NSSortDescriptor alloc]
                                            initWithKey:NSStringFromSelector(@selector(dateOfExpense)) ascending:NO];
    [fetchRequest setSortDescriptors:@[dateSortDescriptor]];
    [fetchRequest setFetchBatchSize:20];

    NSFetchedResultsController *theFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:_managedObjectContext sectionNameKeyPath:nil
                                                                                                             cacheName:@"monthFetchedResultsController"];
    _monthFetchedResultsController = theFetchedResultsController;

    return _monthFetchedResultsController;
}

- (void)monthPerformFetch {
    NSError *monthError;
    if (![self.monthFetchedResultsController performFetch:&monthError]) {
        NSLog(@"Unresolved error %@, %@", monthError, [monthError userInfo]);
        exit(-1);  // Fail
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
        case NSFetchedResultsChangeUpdate:
        case NSFetchedResultsChangeMove:
            break;

        case NSFetchedResultsChangeDelete: {
            ExpenseData *deletedExpense = (ExpenseData *)anObject;
            _totalExpenses -= [deletedExpense.amount floatValue];

            [_categoriesInfo enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                CategoriesInfo *info = obj;
                if (info.idValue == deletedExpense.categoryId) {
                    [self updateCategoriesExpensesDataAtIndex:idx withValue:-deletedExpense.amount.floatValue];

                    *stop = YES;
                }
            }];
            [self notificateCategoriesContainerViewControllerWithNewCategoriesInfo:_categoriesInfo];
            [self updateAmountLabel];
            return;
        }
    }
}

@end
