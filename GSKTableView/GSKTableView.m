#import "GSKTableView.h"
#import "GSKMacros.h"
#import "GSKTableViewCell.h"
#import "GSKTableViewCell_Protected.h"

const static CGFloat GSKInvalidCellHeight = -1;

@interface GSKTableView () <UIScrollViewDelegate> {
    id<GSKTableViewDelegate> _overridenDelegate;
    BOOL _delegateRespondsToDidScroll;
    NSMutableArray *_visibleCells;
}

@property (nonatomic, readonly) NSMutableArray *cellHeights;
@property (nonatomic, readonly) NSCache *cellCache;
@property (nonatomic, readonly) CGFloat estimatedCellHeight;
@property (nonatomic, readonly) NSUInteger totalCells;

@end

@implementation GSKTableView

@synthesize estimatedCellHeight=_estimatedCellHeight, totalCells=_totalCells;

#pragma mark - setup

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    _visibleCells = [NSMutableArray array];
    _cellHeights = [NSMutableArray array];
    _cellCache = [[NSCache alloc] init];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if(super.delegate == nil) {
        [super setDelegate:self];
        [self scrollViewDidScroll:self];
    }
}

#pragma mark - Properties

- (NSArray *)visibleCells {
    return _visibleCells;
}

#pragma mark - Rows and sections

- (NSUInteger)numberOfSections {
    RETURN_FROM_DELEGATE_IF_RESPONDS(_dataSource,
                                     @selector(numberOfSectionsInTableView:),
                                     [_dataSource numberOfSectionsInTableView:self],
                                     1);
}

- (NSUInteger)numberOfRowsInSection:(NSUInteger)section {
    if([_dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
        NSLog(@"");
    }

    RETURN_FROM_DELEGATE_OR_CRASH(_dataSource,
                                  @selector(tableView:numberOfRowsInSection:),
                                  [_dataSource tableView:self numberOfRowsInSection:section],
                                  @"Implement -tableView:numberOfRowsInSection: in tableView dataSource");
}

#pragma mark - Queue management

- (GSKTableViewCell*)dequeueCellWithClass:(Class)cellClass {
    NSString *key = NSStringFromClass(cellClass);
    NSMutableArray *cacheArray = [self.cellCache objectForKey:key];
    GSKTableViewCell *cell = nil;
    if(cacheArray.count > 0) {
        cell = [cacheArray lastObject];
        [cacheArray removeLastObject];
    } else {
        CGRect frame = CGRectMake(0, 0, self.bounds.size.width, 0);
        cell = [[cellClass alloc] initWithFrame:frame];
    }
    [self addSubview:cell];
    return cell;
}

- (void)recycleCell:(GSKTableViewCell*)cell {
    NSString *key = NSStringFromClass(cell.class);
    NSMutableArray *cacheArray = [self.cellCache objectForKey:key];
    if(cacheArray == nil) {
        cacheArray = [NSMutableArray array];
        [self.cellCache setObject:cacheArray forKey:key];
    }
    [cacheArray addObject:cell];
    [cell removeFromSuperview];
}

#pragma mark - Overriden properties

- (id<UIScrollViewDelegate>)delegate {
    return _overridenDelegate;
}

- (void)setDelegate:(id<GSKTableViewDelegate>)delegate {
    _overridenDelegate = delegate;
    _delegateRespondsToDidScroll = [_overridenDelegate respondsToSelector:@selector(scrollViewDidScroll:)];
}

- (void)setDataSource:(id<GSKTableViewDataSource>)dataSource {
    _dataSource = dataSource;

    [self invalidateEstimatedCellHeight];
    [self recomputeContentSize];
}

#pragma mark - Protected stuff

- (CGFloat)estimatedCellHeight {
    if(_estimatedCellHeight == GSKInvalidCellHeight) {
        CGFloat heightSum = 0;
        NSUInteger numCells = 0;

        for (NSArray *section in _cellHeights) {
            for(NSNumber *n in section) {
                heightSum += n.floatValue;
            }
            numCells += section.count;
        }

        if(numCells == 0) {
            return GSKInvalidCellHeight;
        }

        _estimatedCellHeight = heightSum / numCells;
    }
    return _estimatedCellHeight;
}

- (void)invalidateEstimatedCellHeight {
    _estimatedCellHeight = GSKInvalidCellHeight;
}

- (NSUInteger)totalCells {
    if(_totalCells == 0) {
        _totalCells = 0;
        const NSUInteger numSections = self.numberOfSections;
        for (NSUInteger s=0; s<numSections; ++s) {
            _totalCells += [self numberOfRowsInSection:s];
        }
    }
    return _totalCells;
}

- (void)invalidateTotalCells {
    _totalCells = 0;
}

- (void)recomputeContentSize {
    CGSize contentSize = CGSizeMake(self.frame.size.width, 0);
    contentSize.height = self.estimatedCellHeight * self.totalCells;

    [self setContentSize:contentSize];
}


#pragma mark - layout

- (void)layoutSubviews {
    [super layoutSubviews];
    for (GSKTableViewCell* cell in self.visibleCells) {
        cell.frame = cell.frameInTableView;
    }
}

- (void)layoutVisibleRect:(CGRect)visibleRect {
    const CGFloat visibleTop = visibleRect.origin.y;
    const CGFloat visibleBottom = visibleRect.origin.y + visibleRect.size.height;

    // See if all visible cells intersect, if not, take out
    CGFloat minTop = GSKInvalidCellHeight;
    NSUInteger minTopSection = NSNotFound;
    NSUInteger minTopRow = NSNotFound;

    CGFloat maxTop = GSKInvalidCellHeight;
    NSUInteger maxTopSection = NSNotFound;
    NSInteger maxTopRow = NSNotFound;

    for(NSInteger i=(NSUInteger)_visibleCells.count-1; i>=0; --i) {
        GSKTableViewCell *cell = _visibleCells[i];
        CGRect cellFrame = cell.frameInTableView;
        CGFloat cellTop = cellFrame.origin.y;
        CGFloat cellBottom = cellTop + cellFrame.size.height;
        if( cellBottom < visibleTop  || cellTop > visibleBottom ) {
            [self recycleCell:cell];
            [_visibleCells removeObjectAtIndex:i];
        } else {
            if(cellTop < minTop || minTop == GSKInvalidCellHeight) {
                minTop = cellFrame.origin.y;
                minTopSection = cell.section;
                minTopRow = cell.row;
            }
            if(cellBottom > maxTop || maxTop == GSKInvalidCellHeight) {
                maxTop = cellBottom;
                maxTopSection = cell.section;
                maxTopRow = cell.row;
            }
        }
    }

    // Edge case, no visible cells
    if(maxTop == GSKInvalidCellHeight) {
        maxTop = 0;
        maxTopSection = 0;
        maxTopRow = -1;
    }

    const NSUInteger numSections = self.numberOfSections;
        // try to fill back min
        if(minTop > visibleTop) {
            CGFloat y = minTop;
            for(NSInteger s=minTopSection; s>=0 && y>visibleTop; --s) {
                const NSUInteger numRows = [self numberOfRowsInSection:s];
                const NSInteger initialRow = (s==minTopSection) ? minTopRow-1 : numRows-1;
                for(NSInteger r=initialRow; r>=0 && y>visibleTop; --r) {
                    CGFloat cachedHeight = [self cachedHeightForCellInSection:s atRow:r];
                    y -= [self requestAndDisplayCellInSection:s atRow:r top:y-cachedHeight];
                }


            }
            [self invalidateEstimatedCellHeight];
            [self recomputeContentSize];
        }

        // and forth max
        if(maxTop < visibleBottom) {
            CGFloat y = maxTop;
            for(NSUInteger s=maxTopSection; s<numSections && y<visibleBottom; ++s) {
                const NSUInteger initialRow = (s==maxTopSection) ? maxTopRow+1 : 0;
                const NSUInteger numRows = [self numberOfRowsInSection:s];
                for(NSUInteger r=initialRow; r<numRows && y<visibleBottom; ++r) {
                    y += [self requestAndDisplayCellInSection:s atRow:r top:y];
                }
            }
            [self invalidateEstimatedCellHeight];
            [self recomputeContentSize];
        }
}

- (CGFloat)requestAndDisplayCellInSection:(NSUInteger)section
                                    atRow:(NSUInteger)row
                                      top:(CGFloat)top {
    GSKTableViewCell *cell = [self.dataSource tableView:self
                                    cellForRowInSection:section
                                                  atRow:row];
    [cell setNeedsLayout];
    [cell layoutIfNeeded];

    CGFloat cellHeight = cell.frame.size.height;

    cell.frameInTableView = CGRectMake(0, top, self.frame.size.width, cellHeight);
    cell.section = section;
    cell.row = row;

    [self addSubview:cell];
    [self sendSubviewToBack:cell];
    [_visibleCells addObject:cell];
    [self setCachedHeight:cellHeight forCellInSection:section atRow:row];

    return cellHeight;
}

- (CGFloat)cachedHeightForCellInSection:(NSUInteger)section
                                  atRow:(NSUInteger)row {
    if(section >= self.cellHeights.count) {
        return GSKInvalidCellHeight;
    }

    NSPointerArray *sectionArray = self.cellHeights[section];
    if(row >= sectionArray.count) {
        return GSKInvalidCellHeight;
    }

    NSNumber *height = [sectionArray pointerAtIndex:row];
    if(height == nil) {
        return GSKInvalidCellHeight;
    } else {
        return [height floatValue];
    }
}

- (void)setCachedHeight:(CGFloat)height
       forCellInSection:(NSUInteger)section
                  atRow:(NSUInteger)row {
    NSPointerArray *sectionArray = nil;
    if(section < self.cellHeights.count) {
        sectionArray = self.cellHeights[section];
    } else {
        for(NSUInteger i=self.cellHeights.count; i<section+1; ++i) {
            sectionArray = [NSPointerArray strongObjectsPointerArray];
            [self.cellHeights addObject:sectionArray];
        }
    }

    if(row < sectionArray.count) {
        [sectionArray replacePointerAtIndex:row withPointer:(__bridge void *)(@(height))];
    } else {
        [sectionArray insertPointer:(__bridge void *)(@(height)) atIndex:row];
    }
}

#pragma mark - UIScrollViewDelegate methods



- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGRect visibleRect = self.bounds;
    visibleRect.origin.y -= self.contentInset.top;

    [self layoutVisibleRect:visibleRect];


    if(_delegateRespondsToDidScroll) {
        [_overridenDelegate scrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewDidZoom:),
                                 [_overridenDelegate scrollViewDidZoom:scrollView]);
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewWillBeginDragging:),
                                 [_overridenDelegate scrollViewWillBeginDragging:scrollView]);

}


- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView
                     withVelocity:(CGPoint)velocity
              targetContentOffset:(inout CGPoint *)targetContentOffset {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewWillEndDragging:withVelocity:targetContentOffset:),
                                 [_overridenDelegate scrollViewWillEndDragging:scrollView
                                                                  withVelocity:velocity
                                                           targetContentOffset:targetContentOffset]);

}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView
                  willDecelerate:(BOOL)decelerate {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewDidEndDragging:willDecelerate:),
                                 [_overridenDelegate scrollViewDidEndDragging:scrollView
                                                               willDecelerate:decelerate]);

}

- (void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewWillBeginDecelerating:),
                                 [_overridenDelegate scrollViewWillBeginDecelerating:scrollView]);

}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewDidEndDecelerating:),
                                 [_overridenDelegate scrollViewDidEndDecelerating:scrollView]);

}
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewDidEndScrollingAnimation:),
                                 [_overridenDelegate scrollViewDidEndScrollingAnimation:scrollView]);

}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    RETURN_FROM_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                     @selector(viewForZoomingInScrollView:),
                                     [_overridenDelegate viewForZoomingInScrollView:scrollView],
                                     nil);

}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView
                          withView:(UIView *)view {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewWillBeginZooming:withView:),
                                 [_overridenDelegate scrollViewWillBeginZooming:scrollView
                                                                       withView:view]);

}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView
                       withView:(UIView *)view
                        atScale:(CGFloat)scale {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewDidEndZooming:withView:atScale:),
                                 [_overridenDelegate scrollViewDidEndZooming:scrollView
                                                                    withView:view
                                                                     atScale:scale]);

}

- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView {
    RETURN_FROM_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                     @selector(scrollViewShouldScrollToTop:),
                                     [_overridenDelegate scrollViewShouldScrollToTop:scrollView],
                                     NO);
    
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    SEND_TO_DELEGATE_IF_RESPONDS(_overridenDelegate,
                                 @selector(scrollViewDidScrollToTop:),
                                 [_overridenDelegate scrollViewDidScrollToTop:scrollView]);
    
}


@end
