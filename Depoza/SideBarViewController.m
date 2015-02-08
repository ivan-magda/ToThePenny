#import "SideBarViewController.h"

@interface SideBarViewController ()

@end

@implementation SideBarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)dealloc {
    NSLog(@"Dealloc %@", self);
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 8;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];

    cell.textLabel.text = [NSString stringWithFormat:@"Test %ld", (long)indexPath.row];
    
    return cell;
}

@end