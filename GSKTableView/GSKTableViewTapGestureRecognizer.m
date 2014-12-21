#import "GSKTableViewTapGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface GSKTableViewTapGestureRecognizer ()

@property (nonatomic) CGPoint beginPoint;

@end

@implementation GSKTableViewTapGestureRecognizer

static const CGFloat GSKTableViewTapGestureRecognizerThreshold = 8;

- (CGPoint)locationForTouches:(NSSet*)touches {
    UITouch *firstTouch = nil;
    for(UITouch *touch in touches) {
        firstTouch = touch;
        break;
    }
    return [firstTouch locationInView:firstTouch.view];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if([self.delegate respondsToSelector:@selector(gestureRecognizerShouldBegin:)]) {
        BOOL shouldBegin = [self.delegate gestureRecognizerShouldBegin:self];
        if(!shouldBegin) {
            self.state = UIGestureRecognizerStateFailed;
        } else {
            self.beginPoint = [self locationForTouches:touches];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesMoved:touches withEvent:event];
    CGPoint point = [self locationForTouches:touches];
    if(ABS(point.x-self.beginPoint.x) > GSKTableViewTapGestureRecognizerThreshold ||
       ABS(point.y-self.beginPoint.y) > GSKTableViewTapGestureRecognizerThreshold) {
        [self fail];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesCancelled:touches withEvent:event];
    [self fail];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];
    if(self.state != UIGestureRecognizerStateFailed) {
        self.state = UIGestureRecognizerStateEnded;
    } else {
        [self reset];
    }
}

- (id<GSKTableViewTapGestureRecognizerDelegate>)extendedDelegate {
    return (id<GSKTableViewTapGestureRecognizerDelegate>)self.delegate;
}

- (void)fail {
    self.state = UIGestureRecognizerStateFailed;
    if([self.extendedDelegate respondsToSelector:@selector(gestureRecognizerDidFail:)]) {
        [self.extendedDelegate gestureRecognizerDidFail:self];
    }
}

@end
