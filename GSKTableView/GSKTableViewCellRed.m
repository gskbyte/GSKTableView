#import "GSKTableViewCellRed.h"

@implementation GSKTableViewCellRed

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor redColor];
    }
    return self;
}

@end
