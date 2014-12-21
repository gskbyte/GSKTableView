#import <UIKit/UIKit.h>

@interface GSKTableViewTapGestureRecognizer : UIGestureRecognizer

@end

@protocol GSKTableViewTapGestureRecognizerDelegate <UIGestureRecognizerDelegate>

@optional

- (void)gestureRecognizerDidFail:(GSKTableViewTapGestureRecognizer *)gestureRecognizer;

@end
