#import "GSKTableView+DelegateHelper.h"
#import "GSKTableView_Private.h"
#import "GSKMacros.h"

@implementation GSKTableView (DelegateHelper)

#pragma mark - GSKTableViewDelegate redirections

- (void)notifyDelegateWillDisplayCell:(GSKTableViewCell*)cell
                            inSection:(NSUInteger)section
                                atRow:(NSUInteger)row {
    if([self.delegate respondsToSelector:@selector(tableView:willDisplayCell:inSection:atRow:)]) {
        [self.delegate tableView:self willDisplayCell:cell inSection:section atRow:row];
    }
}

- (BOOL)canHighlightCellInSection:(NSUInteger)section
                            atRow:(NSUInteger)row {
    if([self.delegate respondsToSelector:@selector(tableView:canHighlightCellInSection:atRow:)]) {
        return [self.delegate tableView:self
              canHighlightCellInSection:section
                                  atRow:row];
    }
    return NO;
}

- (void)notifyWillHighlightCellInSection:(NSUInteger)section
                                   atRow:(NSUInteger)row {
    if([self.delegate respondsToSelector:@selector(tableView:willHighlightCellInSection:atRow:)]) {
        [self.delegate tableView:self
      willHighlightCellInSection:section
                           atRow:row];
    }
}

- (void)notifyWillUnhighlightCellInSection:(NSUInteger)section
                                   atRow:(NSUInteger)row {
    if([self.delegate respondsToSelector:@selector(tableView:willUnhighlightCellInSection:atRow:)]) {
        [self.delegate tableView:self
      willHighlightCellInSection:section
                           atRow:row];
    }
}

- (void)notifyDidTapCellInSection:(NSUInteger)section
                            atRow:(NSUInteger)row {
    if([self.delegate respondsToSelector:@selector(tableView:didTapCellInSection:atRow:)]) {
        [self.delegate tableView:self
             didTapCellInSection:section
                           atRow:row];
    }
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect visibleRect = self.bounds;
    visibleRect.origin.y -= self.contentInset.top;

    [self layoutVisibleRect:visibleRect];


    if([self.delegate respondsToSelector:@selector(scrollViewDidScroll:)]) {
        [self.delegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewDidZoom:),
                                 [self.delegate scrollViewDidZoom:scrollView]);
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewWillBeginDragging:),
                                 [self.delegate scrollViewWillBeginDragging:scrollView]);

}

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:),
                                 [self.delegate scrollViewWillEndDragging:scrollView
                                                                  withVelocity:velocity
                                                           targetContentOffset:targetContentOffset]);

}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewDidEndDragging:willDecelerate:),
                                 [self.delegate scrollViewDidEndDragging:scrollView
                                                               willDecelerate:decelerate]);

}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewWillBeginDecelerating:),
                                 [self.delegate scrollViewWillBeginDecelerating:scrollView]);

}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewDidEndDecelerating:),
                                 [self.delegate scrollViewDidEndDecelerating:scrollView]);

}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewDidEndScrollingAnimation:),
                                 [self.delegate scrollViewDidEndScrollingAnimation:scrollView]);

}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    RETURN_FROM_DELEGATE_IF_RESPONDS(self.delegate,
                                     @selector(viewForZoomingInScrollView:),
                                     [self.delegate viewForZoomingInScrollView:scrollView],
                                     nil);

}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView
                          withView:(UIView *)view {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewWillBeginZooming:withView:),
                                 [self.delegate scrollViewWillBeginZooming:scrollView
                                                                       withView:view]);

}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(CGFloat)scale {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewDidEndZooming:withView:atScale:),
                                 [self.delegate scrollViewDidEndZooming:scrollView
                                                                    withView:view
                                                                     atScale:scale]);

}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    RETURN_FROM_DELEGATE_IF_RESPONDS(self.delegate,
                                     @selector(scrollViewShouldScrollToTop:),
                                     [self.delegate scrollViewShouldScrollToTop:scrollView],
                                     NO);

}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(self.delegate,
                                 @selector(scrollViewDidScrollToTop:),
                                 [self.delegate scrollViewDidScrollToTop:scrollView]);
    
}

@end
