#import "GSKTableView.h"

@interface GSKTableView (DelegateHelper)

- (void)notifyDelegateWillDisplayCell:(GSKTableViewCell*)cell
                            inSection:(NSUInteger)section
                                atRow:(NSUInteger)row;

- (BOOL)canHighlightCellInSection:(NSUInteger)section
                            atRow:(NSUInteger)row;
- (void)notifyWillHighlightCellInSection:(NSUInteger)section
                                atRow:(NSUInteger)row;
- (void)notifyWillUnhighlightCellInSection:(NSUInteger)section
                                     atRow:(NSUInteger)row;
- (void)notifyDidTapCellInSection:(NSUInteger)section
                            atRow:(NSUInteger)row;


@end
