#import <UIKit/UIKit.h>

@class GSKTableView;
@class GSKTableViewCell;

@protocol GSKTableViewDelegate <UIScrollViewDelegate>

@optional
// display
- (void)tableView:(GSKTableView *)tableView
  willDisplayCell:(GSKTableViewCell *)cell
        inSection:(NSUInteger)section
            atRow:(NSUInteger)row;

// highlight
- (BOOL)        tableView:(GSKTableView *)tableView
canHighlightCellInSection:(NSUInteger)section
                    atRow:(NSUInteger)row; // default NO
- (void)         tableView:(GSKTableView *)tableView
willHighlightCellInSection:(NSUInteger)section
                     atRow:(NSUInteger)row;
- (void)           tableView:(GSKTableView *)tableView
willUnhighlightCellInSection:(NSUInteger)section
                       atRow:(NSUInteger)row;

// selection
- (void)  tableView:(GSKTableView *)tableView
didTapCellInSection:(NSUInteger)section
              atRow:(NSUInteger)row;


@end

@protocol GSKTableViewDataSource <NSObject>

@required

- (NSInteger)tableView:(GSKTableView *)tableView
 numberOfRowsInSection:(NSInteger)section;
- (GSKTableViewCell *)tableView:(GSKTableView *)tableView
            cellForRowInSection:(NSUInteger)section
                          atRow:(NSUInteger)row;

@optional

- (NSInteger)numberOfSectionsInTableView:(GSKTableView *)tableView; // Default is 1 if not implemented

@end


@interface GSKTableView : UIScrollView

@property (nonatomic, weak) id<GSKTableViewDataSource> dataSource;
@property (nonatomic, weak) id<GSKTableViewDelegate> delegate;

@property (nonatomic, readonly) NSArray *visibleCells;

@property (nonatomic, readonly) NSUInteger numberOfSections;

- (NSUInteger)numberOfRowsInSection:(NSUInteger)section;
- (GSKTableViewCell*)dequeueCellWithClass:(Class)cellClass;

@end

