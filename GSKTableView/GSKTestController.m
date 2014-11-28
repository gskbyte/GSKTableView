#import "GSKTestController.h"
#import "GSKTableViewCellRed.h"
#import "GSKTableViewCellBlue.h"

@interface GSKTestController ()

@property (nonatomic) NSMutableArray *heights;

@end

@implementation GSKTestController


#pragma mark - GSKTableViewDataSource

- (void)viewDidLoad {
    [super viewDidLoad];

    self.heights = [NSMutableArray array];
    NSUInteger numSections = 2 + arc4random_uniform(10); // 2 to 5 sections
    for(NSUInteger s=0; s<numSections; ++s) {
        NSMutableArray *sectionHeights = [NSMutableArray array];
        NSUInteger numItems = 10 + arc4random_uniform(30); // between 10 and 20
        for(NSUInteger i=0; i<numItems; ++i) {
            NSUInteger height = 50 + arc4random_uniform(200);
            [sectionHeights addObject:@(height)];
        }

        [self.heights addObject:sectionHeights];
    }
}

- (NSInteger)numberOfSectionsInTableView:(GSKTableView *)tableView {
    return self.heights.count;
}

- (NSInteger)tableView:(GSKTableView *)tableView
 numberOfRowsInSection:(NSInteger)section {
    return [self.heights[section] count];
}

- (GSKTableViewCell *)tableView:(GSKTableView *)tableView
            cellForRowInSection:(NSUInteger)section
                          atRow:(NSUInteger)row {
    GSKTableViewCell * cell;
    if(row % 2 == 0) {
        cell = [tableView dequeueCellWithClass:GSKTableViewCellRed.class];
    } else {
        cell = [tableView dequeueCellWithClass:GSKTableViewCellBlue.class];
    }

    CGRect frame = cell.frame;
    frame.size.height = [[self.heights[section] objectAtIndex:row] floatValue];
    cell.frame = frame;

    NSLog(@"cellForRowInSection:%zd atRow:%zd", section, row);

    return cell;
}

@end
