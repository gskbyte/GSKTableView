#import "GSKTableViewController.h"

@interface GSKTableViewController ()

@end

@implementation GSKTableViewController

- (GSKTableView *)tableView {
    return (GSKTableView*)self.view;
}

- (void)loadView {
    CGRect frame = [UIScreen mainScreen].bounds;
    self.view = [[GSKTableView alloc] initWithFrame:frame];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
}

#pragma mark - DataSource methods just to silent warnings

- (NSInteger)tableView:(GSKTableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSAssert(NO, @"Implement -tableView:numberOfRowsInSection: in subclasses of GSKTableViewController");
    return 0;
}

- (GSKTableViewCell *)tableView:(GSKTableView *)tableView
            cellForRowInSection:(NSUInteger)section
                          atRow:(NSUInteger)row {
    NSAssert(NO, @"Implement -tableView:cellForRowInSection:atRow: in subclasses of GSKTableViewController");
    return nil;
}



@end
