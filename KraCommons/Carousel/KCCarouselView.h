//
//  KCCarouselView.h
//
//  Created by Olivier Larivain on 1/11/13.
//  Copyright 2012 kra All rights reserved.
//

#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <UIKit/UIKit.h>

#define CONTENT_PADDING 1 

@class KCTileFrames;

typedef enum 
{
	KCCarouselViewStyleHorizontal,
	KCCarouselViewStyleGrid,
    KCCarouselViewStyleStaggered
}
KCCarouselViewStyle;


@class KCCarouselView;

/* Tiles can implement a prepareForReuse method, so they can be cleaned up
when dequeued.
 * 
*/
@protocol KCCarouselTile <NSObject>

@optional
@property (nonatomic, retain) NSString *identifier;
- (BOOL)ignoreTapAtLocation:(CGPoint)location;
- (void)prepareForReuse;
- (void) highlightTile: (BOOL) highlight;

@end

/* Carousel delegate is responsible for interaction with the carousel.
 It gets notified of the following event:
 - Selection
 - Scrolling begin, goes on and ends
 - Page changed (if swiping enabled)
 - Wrapped to begining/end, when infinite swiping is on (not implemented yet)
 */
@protocol KCCarouselViewDelegate <NSObject>
@optional
- (void)carousel:(KCCarouselView *)carousel didSelectIndex:(NSUInteger)index;
- (void)carouselDidBeginDragging:(KCCarouselView *)carousel;
- (void)carouselIsScrolling:(KCCarouselView *)carousel;
- (void)carouselDidEndScrolling:(KCCarouselView *)carousel;

- (void)carousel:(KCCarouselView *)carousel didChangePage:(NSUInteger)newPage;

@end 

/*
 Similar to UITableDataSource, provides content for the carousel.
 */
@protocol KCCarouselViewDataSource <NSObject>
@required
// total number of tiles in the carousel
- (NSUInteger)numberOfTilesInCarousel:(KCCarouselView *)carousel;
// size at given index
- (CGSize)carousel:(KCCarouselView *)carousel sizeForTileAtIndex:(NSUInteger)index;
// tile at given index
- (UIView *)carousel:(KCCarouselView *)carousel tileForIndex:(NSUInteger)index;
@optional
// called when the size of the tile changes due to relayout.
- (UIView *)carousel:(KCCarouselView *)carousel updateTile:(UIView *)tile forIndex:(NSUInteger)index;
@end 

/*
 High performance carousel.
 A carousel can have three different layouts:
 - Horizontal (all tiles are layed out in a row)
 - Grid (all tiles are layed on a matrix)
 - Staggered: horizontal layout, over two lines. the second line is offset by half the width of the tile.
 
 A carousel can also be paged, and if paged, it can provide infinite swiping.
 Important Note: Because of technical limitations, infinite swiping can be turned on ONLY when 
 paging with a horizontal layout.
 
 Technical Notes:
 * Overall Design
 A carousel is *very* similar to a UITableView in its design. It implements a flyweight pattern
 for performance reason, and queues unused tiles as needed. One can think of the carousel as a table view rotated 90 degrees
 (horizontal layout).
 A carousel requires a data source and can have a delegate.
 The data source will provide the actual tile view instances and other information such as total 
 number of tiles, their sizes etc.
 The delegate will be notified of relevant events: selection, scrolling, page change etc.
 
 * Implementation
 Implementation wise, the carousel is a very standard flyweight pattern.
 
 Here's how the carousel works at a high level:
 - The carousel asks its data source for the number of tiles.
 - The carousel asks its data source for the size of ALL tiles. From there, it builds an index
 of KCTileFrames, which hold the frame for every tile in the scroll view.
 - When laying out its subviews (-layoutSubviews), the carousel will go through this index
 of KCTileFrames, figure out which tiles are currently on screen and determine if it already has a view on screen
 for these tiles.
 - If that's not the case, then the carousel queries its data source for a tile at that index, then positions it
 according to the KCTileFrame index.
 
 * Infinite Swiping:
 Infinite swiping works ONLY on HORIZONTAL layouts. It's not implemented on grid layouts, period.
 It is also technically impossible (or not without a significant amount of engineering) to implement it on free scrolling
 carousels, mostly because of scroll deceleration and bouncing at (0,0). Sorry about that.
 
 Infinite swiping has to be faked, since iOS scroll views don't provide anything for that and will get out of its way to
 prevent you from scrolling below (0,0).
 
 The idea is the following, when infinite swiping is on, the scroll view will:
 - allocate room for two extra tiles, on the at the beginning, one at the end
 - shift the whole layout one tile to the right.
 
 When the carousel displays the first tile, the last tile will be moved to the very beginning
 of the scroll view (i.e. the empty spot at (0,0). This is refered to as "warping a tile" in the code.
 
 Once (and if) the scroll view "pages" into that tile, the scroll view will then warp that tile back to its
 original location, and move the content offset to that same spot.
 
 The exact same process takes place if the carousel displays the last tile to the right: the first tile is warped
 in place, when paging to the right, it jumps back to the original location.
 
 This is the main reason why infinite swiping can't be turned on without paging, we need a safe place to reset those
 locations, and this place is when the scroll view notifies us of either scroll deceleration/animation end.
 
 Very Important Note: Due to implementation details (that turn out to be more than just details...) the infinite swiping
 will work well when the tile is the size of the screen. Behaviour when the tile is not exactly the size of the screen
 is completely unkown (and honnestly, I don't think it will work).
 Reader, feel free to fix this behaviour, but you'll be entering a world of pain and I'm not convinced by the
 business value of it.
 */
@interface KCCarouselView : UIScrollView <UIScrollViewDelegate, UIGestureRecognizerDelegate> {  
    
    // delegates
    IBOutlet __weak id<KCCarouselViewDelegate> carouselDelegate;
    IBOutlet __weak id<KCCarouselViewDataSource> carouselDataSource;
    IBOutlet __weak id<KCCarouselTile> nibTile;
    
    BOOL delegateSupportsDidBeginDragging;
    BOOL delegateSupportsIsScrolling;
    BOOL delegateSupportsEndDeceleration;
    
    // headers/footer view.
    __strong IBOutlet UIView *headerView;
    __strong IBOutlet UIView *footerView;
    
    // configuration
    // layout style: horizontal, in a line or vertically, in a grid.
    KCCarouselViewStyle style;
    CGFloat contentPadding;
    UIEdgeInsets tileDrawInset;
    
    // tile frames for ALL tiles
    __strong KCTileFrames *tileFrames;
    
    // tiles that are currently on screen (fully or partially)
    __strong NSMutableArray *visibleTiles;
    // queued tiles, ready for dequeuing
    __strong NSMutableDictionary *availableTilesByIdentifier;
    
    // global index of the first visible tile
    NSInteger firstVisibleIndex;
    
    // current index
    NSInteger index;
    
    // current page
    NSInteger page;
    
    // total number of tiles
    NSInteger count;
    
    // last known size
    CGSize lastSize;
    
    // whether selected tile should be highlighted
    BOOL highlightSelection;
    // global index of highlighted tile, or -1 if none
    NSInteger highlightedIndex;
    
    // tap recognizers
    __strong UITapGestureRecognizer *tileTapRecognizer;
    __strong UITapGestureRecognizer *doubleTapRecognizer;
    
    // whether inifite swiping is on
    BOOL infiniteSwiping;
    BOOL didWarp;
}

// delegate and data source 
@property(nonatomic, weak) id<KCCarouselViewDelegate> carouselDelegate;
@property(nonatomic, weak) id<KCCarouselViewDataSource> carouselDataSource;

// vertical/horizontal layout
@property(nonatomic, assign) KCCarouselViewStyle style;
@property(nonatomic, assign) CGFloat contentPadding;
@property(nonatomic, assign) BOOL infiniteSwiping;

// tiles currently visible
@property(nonatomic, readonly) NSMutableArray *visibleTiles;
// index of visible tiles
@property(nonatomic, readonly) NSArray *visibleIndexes;
// tiles inset
@property(nonatomic, readwrite, assign) UIEdgeInsets tileDrawInset;

// total number of tiles
@property(nonatomic, readonly) NSInteger count;
// total number of pages
@property(nonatomic, readonly) NSInteger pageCount;

// size of a tile (all tiles have the same size)
@property(readonly) CGSize tileSize;

// gesture recognizers
@property(nonatomic, readonly) UIGestureRecognizer *tileTapRecognizer;
@property(nonatomic, readonly) UIGestureRecognizer *doubleTapRecognizer;

// carousel header/footer
@property(nonatomic, readwrite, strong)  UIView *headerView;
@property(nonatomic, readwrite, strong)  UIView *footerView;

// index represents the carousel index thats at the left-most of the viewport screen
@property(nonatomic, readwrite, assign) NSInteger index;

// hightlight carousel tile
@property(nonatomic, readwrite, assign) NSInteger highlightedIndex;
@property(nonatomic, readwrite, assign) BOOL highlightSelection;

// disables layout subviews while animating flag is on
@property (nonatomic, readwrite, assign) BOOL animating;

- (void) updateTileAtIndex: (NSInteger) index;

// cell dequeuing and nib loading
- (id)dequeueResuableTile;
- (id)dequeueReuseableTileWithIdentifier:(NSString *)identifier;

// move to given tile index, with animation
- (void)setIndex:(NSUInteger)newIndex animated: (BOOL) animated;

// returns the tile with given index if it is visible, nil otherwise
- (id) visibleTileWithIndex: (NSInteger) index;

// refreshes (i.e., reloads and forces tile filing and layout)
- (void) refresh;
// reloads all data (i.e., asks data source for content and tiles)
- (void)reload;

- (void)setTapGestureDisabled: (BOOL) disabled;
- (void)setDoubleTapGestureDisabled: (BOOL) disabled;

// index for tile under given point
- (NSInteger) indexForPoint:(CGPoint)point;
// highlights tile at given index
- (void) highlightTileAtIndex:(NSUInteger)index;

// returns the frame for the tile at given index
- (CGRect) rectForTileAtIndex: (NSInteger) tileIndex;

@end
#endif