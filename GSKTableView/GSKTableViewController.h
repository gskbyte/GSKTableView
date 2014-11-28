#import <UIKit/UIKit.h>
#import "GSKTableView.h"

@interface GSKTableViewController : UIViewController <GSKTableViewDataSource, GSKTableViewDelegate>

@property (nonatomic, readonly) GSKTableView *tableView;

@end
