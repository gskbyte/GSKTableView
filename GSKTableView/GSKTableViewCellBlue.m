#import "GSKTableViewCellBlue.h"

@implementation GSKTableViewCellBlue

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        self.backgroundColor = [UIColor blueColor];
    }
    return self;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    self.backgroundColor = highlighted ? [UIColor cyanColor] : [UIColor blueColor];
}


@end
