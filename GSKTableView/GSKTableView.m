#import "GSKTableView.h"
#import "GSKTableView_Private.h"
#import "GSKTableView+DelegateHelper.h"

#import "GSKMacros.h"
#import "GSKTableViewCell.h"
#import "GSKTableViewCell_Protected.h"
#import "UIView+Frame.h"
#import "GSKTableViewTapGestureRecognizer.h"

const static CGFloat GSKInvalidCellHeight = -1;

@interface GSKTableView () <UIScrollViewDelegate, GSKTableViewTapGestureRecognizerDelegate> {
    id<GSKTableViewDelegate> _overridenDelegate;
    NSMutableArray *_visibleCells;
}

@property (nonatomic, readonly) NSMutableArray *cellHeights;
@property (nonatomic, readonly) NSCache *cellCache;
@property (nonatomic, readonly) CGFloat estimatedCellHeight;
@property (nonatomic, readonly) NSUInteger totalCells;

@property (nonatomic) GSKTableViewTapGestureRecognizer *tapRecognizer;

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

    _tapRecognizer = [[GSKTableViewTapGestureRecognizer alloc] initWithTarget:self
                                                                       action:@selector(didTap:)];
    _tapRecognizer.delegate = self;
    [self addGestureRecognizer:_tapRecognizer];
}

- (void)didMoveToWindow {
    [super didMoveToWindow];
    if(super.delegate == nil) {
        [super setDelegate:self];
        [self scrollViewDidScroll:self];
    }
}

#pragma mark - public methods

- (NSUInteger)numberOfSections {
    RETURN_FROM_DELEGATE_IF_RESPONDS(self.dataSource,
                                     @selector(numberOfSectionsInTableView:),
                                     [self.dataSource numberOfSectionsInTableView:self],
                                     1);
}

- (NSUInteger)numberOfRowsInSection:(NSUInteger)section {
    if([self.dataSource respondsToSelector:@selector(tableView:numberOfRowsInSection:)]) {
        NSLog(@"");
    }

    RETURN_FROM_DELEGATE_OR_CRASH(self.dataSource,
                                  @selector(tableView:numberOfRowsInSection:),
                                  [self.dataSource tableView:self numberOfRowsInSection:section],
                                  @"Implement -tableView:numberOfRowsInSection: in tableView dataSource");
}

#pragma mark - Properties

- (NSArray *)visibleCells {
    return _visibleCells;
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

#pragma mark - invalidation 

- (void)notifyDataSourceChanged {
    [self invalidateEstimatedCellHeight];
    [self recomputeContentSize];
}

#pragma mark - Overriden properties

- (id<UIScrollViewDelegate>)delegate {
    return _overridenDelegate;
}

- (void)setDelegate:(id<GSKTableViewDelegate>)delegate {
    _overridenDelegate = delegate;
}

- (void)setDataSource:(id<GSKTableViewDataSource>)dataSource {
    _dataSource = dataSource;
    [self notifyDataSourceChanged];
}

#pragma mark - touch and selection

- (GSKTableViewCell *)cellForGestureRecognizer:(UIGestureRecognizer*)recognizer {
    CGPoint location = [recognizer locationInView:self];
    UIView *tappedSubview = [self hitTest:location withEvent:nil];
    if([tappedSubview isKindOfClass:GSKTableViewCell.class]) {
        return (GSKTableViewCell*) tappedSubview;
    } else {
        return nil;
    }
}


- (void)didTap:(UIGestureRecognizer*)tapRecognizer {
    GSKTableViewCell *cell = [self cellForGestureRecognizer:tapRecognizer];
    if(cell != nil) {
        [self notifyDidTapCellInSection:cell.section
                                  atRow:cell.row];
        if([self canHighlightCellInSection:cell.section atRow:cell.row]) {
            [self notifyWillUnhighlightCellInSection:cell.section atRow:cell.row];
            cell.highlighted = NO;
        }
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer != self.tapRecognizer) {
        return [super gestureRecognizerShouldBegin:gestureRecognizer];
    }

    GSKTableViewCell *cell = [self cellForGestureRecognizer:gestureRecognizer];
    if(cell != nil) {
        if([self canHighlightCellInSection:cell.section atRow:cell.row]) {
            [self notifyWillHighlightCellInSection:cell.section atRow:cell.row];
            cell.highlighted = YES;
        }
    }

    return YES;
}

- (void)gestureRecognizerDidFail:(UIGestureRecognizer *)gestureRecognizer {
    if(gestureRecognizer != self.tapRecognizer) {
        return;
    }

    GSKTableViewCell *cell = [self cellForGestureRecognizer:gestureRecognizer];
    if(cell != nil) {
        if([self canHighlightCellInSection:cell.section atRow:cell.row]) {
            [self notifyWillUnhighlightCellInSection:cell.section atRow:cell.row];
            cell.highlighted = NO;
        }
    }
}

#pragma mark - size calculation

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

    BOOL invalidateSize = NO;
    const NSUInteger numSections = self.numberOfSections;

    // try to fill back min
    if(minTop > visibleTop) {
        CGFloat y = minTop;
        for(NSInteger s=minTopSection; s>=0 && y>visibleTop; --s) {
            const NSUInteger numRows = [self numberOfRowsInSection:s];
            const NSInteger initialRow = (s==minTopSection) ? minTopRow-1 : numRows-1;
            for(NSInteger r=initialRow; r>=0 && y>visibleTop; --r) {
                CGFloat cachedHeight = [self cachedHeightForCellInSection:s atRow:r];
                GSKTableViewCell *cell = [self requestAndLayoutCellInSection:s atRow:r top:y-cachedHeight];
                y -= cell.height;
            }
        }
    }

    // and forth max
    if(maxTop < visibleBottom) {
        CGFloat y = maxTop;
        for(NSUInteger s=maxTopSection; s<numSections && y<visibleBottom; ++s) {
            const NSUInteger initialRow = (s==maxTopSection) ? maxTopRow+1 : 0;
            const NSUInteger numRows = [self numberOfRowsInSection:s];
            for(NSUInteger r=initialRow; r<numRows && y<visibleBottom; ++r) {
                CGFloat cachedHeight = [self cachedHeightForCellInSection:s atRow:r];
                GSKTableViewCell *cell = [self requestAndLayoutCellInSection:s atRow:r top:y];
                y += cell.height;
                if(cachedHeight != cell.height) {
                    invalidateSize = YES;
                }
            }
        }
    }

    if(invalidateSize) {
        [self invalidateEstimatedCellHeight];
        [self recomputeContentSize];
    }
}

- (GSKTableViewCell *)requestAndLayoutCellInSection:(NSUInteger)section
                                              atRow:(NSUInteger)row
                                                top:(CGFloat)top {
    GSKTableViewCell *cell = [self.dataSource tableView:self
                                    cellForRowInSection:section
                                                  atRow:row];
    [cell setNeedsLayout];
    [cell layoutIfNeeded];

    CGFloat cellHeight = cell.height;

    cell.frameInTableView = CGRectMake(0, top, self.width, cellHeight);
    cell.section = section;
    cell.row = row;

    [self addSubview:cell];
    [self bringSubviewToFront:cell];
    [_visibleCells addObject:cell];
    [self setCachedHeight:cellHeight forCellInSection:section atRow:row];

    [self notifyDelegateWillDisplayCell:cell inSection:section atRow:row];

    return cell;
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


@end
