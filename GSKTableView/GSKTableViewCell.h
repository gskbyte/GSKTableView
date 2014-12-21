#import <UIKit/UIKit.h>

@interface GSKTableViewCell : UIView

@property (nonatomic, readonly) NSUInteger section;
@property (nonatomic, readonly) NSUInteger row;
@property (nonatomic) BOOL highlighted;

@end
