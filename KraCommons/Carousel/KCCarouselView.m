//
//  KCCarouselView.m
//
//  Created by Olivier Larivain on 1/11/13.
//  Copyright 2012 kra All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <QuartzCore/QuartzCore.h>

#import "KCCarouselView.h"
//#import "ECCarouselViewTile.h"

#import "KCTileFrames.h"
#import "KCTileFrame.h"

@interface KCCarouselView()

@property (nonatomic, readwrite, weak) id<KCCarouselTile> nibTile;

- (void)sharedInit;

// moves tile to reusable queue and calls appropriate method on it if supported
- (void)queueResuableTile:(UIView *)tile;

// fills the view with the tiles
- (void)fillWithTiles;

// scrolls view to current index/highlighted index
- (void)updatePosition;

// convenience accessor methods
- (void)reindex;

// requests tile from data source
- (UIView *)carouselTileForIndex:(NSUInteger)index;

// returns the area that is using for painting
- (CGRect)drawingRect;

// resizes tiles if size has changed since last layout
- (void) resizeOnLayout;

// updates current page, page count and calls paging delegate methods
- (void)updatePage;

// resizes content size and footer view
- (void)updateSize;
- (void) updateFooterSizeWithMaxX: (CGFloat) maxX andMaxY: (CGFloat) maxY;

// gesture recognizers
- (void) tileTapped:(UITapGestureRecognizer *)recognizer;
- (void) disableTapGestureRecognizer;
- (void) enableTapGestureRecognizer;

- (void) disableDoubleTapGestureRecognizer;
- (void) enableDoubleTapGestureRecognizer;

- (BOOL) warpIfNeeded;

- (KCTileFrame*) frameForTileAtVisibleIndex: (NSInteger) tileIndex;
@end

@implementation KCCarouselView
@synthesize animating;
@synthesize carouselDelegate;
@synthesize carouselDataSource;
@synthesize tileDrawInset;
@synthesize index;
@synthesize visibleTiles;
@synthesize highlightSelection;
@synthesize highlightedIndex;
@synthesize count;
@synthesize tileTapRecognizer;
@synthesize doubleTapRecognizer;
@synthesize style;
@synthesize infiniteSwiping;
@synthesize contentPadding;
@synthesize headerView;
@synthesize footerView;
@synthesize nibTile;


#pragma  mark - Constructor/Destructor etc.
- (id)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        [self sharedInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self sharedInit];
    }
    return self;
}

- (void)sharedInit {
    // we usually don't want this guy to scroll to top,
    // so make this the default behavior.
    self.scrollsToTop = NO;
    
    // wire scroll delegate to ourself.
    // scroll events will be translated and forwarded to the carousel delegate
    self.delegate = self;
    
    // setup "index" ivars
    index = 0;
    highlightedIndex = 0;
    lastSize = CGSizeZero;
    firstVisibleIndex = 0;
    
    visibleTiles = [NSMutableArray arrayWithCapacity: 20];
    availableTilesByIdentifier = [NSMutableDictionary dictionary];
    
    // disable scroll bars
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    
    // start with no inset
    self.tileDrawInset = UIEdgeInsetsZero;
    
    // init tiles array
    tileFrames = [KCTileFrames tileFrames];
    
    // turn on tap gesture by default.
    [self enableTapGestureRecognizer];
}

- (void) setCarouselDelegate:(id<KCCarouselViewDelegate>)aCarouselDelegate {
    carouselDelegate = aCarouselDelegate;
    delegateSupportsDidBeginDragging = [carouselDelegate respondsToSelector:@selector(carouselDidBeginDragging:)];
    delegateSupportsIsScrolling = [carouselDelegate respondsToSelector:@selector(carouselIsScrolling:)];
    delegateSupportsEndDeceleration = [carouselDelegate respondsToSelector:@selector(carouselDidEndScrolling:)];
    
}

- (void) setInfiniteSwiping:(BOOL)value {
    if (value && !self.pagingEnabled) {
        @throw [NSException exceptionWithName: @"IllegalArgumentException"
                                       reason: @"Infinite Swiping can be enabled ONLY on paging KCCarouselView."
                                     userInfo: nil];
    }
    infiniteSwiping = value;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    // if not clipping (ie subviews not visible outside of frame)
    // then clip to bounds.
    if(self.clipsToBounds) {
        return [super pointInside: point withEvent: event];
    }
    
    // Grab the inset rect and test if it contains the point
    CGRect responseRect = UIEdgeInsetsInsetRect(self.bounds, tileDrawInset);
    BOOL containsPoint = CGRectContainsPoint(responseRect, point);
    return containsPoint;
}

- (void)setIndex:(NSInteger)newIndex {
    [self setIndex: newIndex animated: NO];
}

- (void)setIndex:(NSUInteger)newIndex animated: (BOOL) animated {
    index = newIndex;
    
    // sanity check. If we don't have a frame, abort.
    KCTileFrame *tileFrame = [tileFrames frameWithIndex: newIndex];
    if(tileFrame == nil){
        return;
    }
    
    // reset frame to its original position. we're indeed jumping to the right offset when doing this.
    [tileFrame reset];
    
    // we can now safely scroll to rect
    [self scrollRectToVisible: tileFrame.frame animated: animated];
}

#pragma mark - Changing the header/footer views
- (void) setFooterView:(UIView *) aFooterView {
    // no changes, abort
    if(footerView == aFooterView) {
        return;
    }
    
    // don't forget to remove the old one from the view ;-)
    [footerView removeFromSuperview];
    footerView = aFooterView;
    
    // size will also change, so do that now
    [self updateSize];
}

- (void) setHeaderView:(UIView *) aHeaderView {
    // symetrical version of setFooterView
    if(headerView == aHeaderView) {
        return;
    }
    [headerView removeFromSuperview];
    headerView = aHeaderView;
    
    [self updateSize];
}

#pragma mark - Synthetic getters/setters
- (CGSize)tileSize {
    // we are under the assumption that ALL tiles are the same size,
    // so return size for first tile, otherwise CGSizeZero.
    if ([visibleTiles count]) {
        UIView *view = [visibleTiles objectAtIndex:0];
        return view.bounds.size;
    }
    return CGSizeZero;
}

// number of pages in the scroll view (regardless of the number of tiles or their size)
// A page is the *visible* are of the scroll view (== its frame)
- (NSInteger)pageCount {
    
    if (count) {
        NSUInteger pageCount = ceilf(self.contentSize.width / self.bounds.size.width);
        return pageCount;
    }
    
    return 0;
}

#pragma mark - Updating a given tile
- (void) updateTileAtIndex: (NSInteger) theIndex {
    // don't do anything if we're beyound the bounds
    if(theIndex < 0 || theIndex >= count) {
        return;
    }
    
    // don't do anything if the tile is not visible: there's nothing to update anyway.
    UIView *tile = [self visibleTileWithIndex: theIndex];
    if(tile == nil) {
        return;
    }
    
    // copy the original position in the array first, we'll need it at the end
    NSInteger initialIndex = [visibleTiles indexOfObject: tile];
    
    // allright, so now, queue the tile. That'll effectively remove it from the scene,
    // and call -prepareForReuse on it.
    [self queueResuableTile: tile];
    
    // now, ask the data source for a fresh cell
    tile = [carouselDataSource carousel: self
                           tileForIndex: theIndex];
    
    // reposition it
    CGRect tileFrame = [self rectForTileAtIndex:theIndex];
    tile.frame = tileFrame;
    
    // and readd it to the carousel
    [self addSubview: tile];
    [visibleTiles insertObject: tile
                       atIndex: initialIndex];
}

#pragma mark - Tiles recycling

- (id)dequeueResuableTile {
    // default to empty ID :)
    return [self dequeueReuseableTileWithIdentifier:@""];
}

- (id<KCCarouselTile>)dequeueReuseableTileWithIdentifier:(NSString *)identifier {
    // nothing is available, just get he hell out
    if ([availableTilesByIdentifier count] == 0) {
        return  nil;
    }
    
    NSString *key = identifier ? identifier : @"";
    NSMutableSet *set = [availableTilesByIdentifier nullSafeForKey:key];
    if ([set count] == 0) {
        return nil;
    }
    
    id<KCCarouselTile> tile = [set anyObject];
    [set removeObject:tile];
    
    return tile;
}

// marks the tile as being available for reuse.
// optionally notifies tile if it conforms to the protocol.
- (void)queueResuableTile:(UIView *)tile {
    // notify tile is going to get recycled if applicable
    if ([tile respondsToSelector:@selector(prepareForReuse)]) {
        [(id<KCCarouselTile>)tile prepareForReuse];
    }
    
    NSString *identifier = @"";
    if ([tile respondsToSelector:@selector(identifier)]) {
        identifier = [(id<KCCarouselTile>)tile identifier];
    }
    
    NSMutableSet *set = [availableTilesByIdentifier nullSafeForKey:identifier];
    if (!set) {
        set = [NSMutableSet setWithCapacity:20];
        [availableTilesByIdentifier setValue:set forKey:identifier ? identifier : @""];
    }
    
    // move tile from one array to another
    [set addObject:tile];
    [visibleTiles removeObject:tile];
    
    // and remove it from the screen
    [tile removeFromSuperview];
}

- (UIView *)carouselTileForIndex:(NSUInteger)tileIndex {
    // ask data source for the next tile
    UIView *newTile = [carouselDataSource carousel:self tileForIndex:tileIndex];
    return newTile;
}

// highlits tile at given index, if hihglighting is enabled
- (void)highlightTileAtIndex:(NSUInteger)highlightIndex{
    if (!highlightSelection){
        return;
    }
    
    // look for given tile and highlight if found
    UIView *visibleTile = [self visibleTileWithIndex: highlightIndex];
    if(![visibleTile respondsToSelector: @selector(highlightTile:)]) {
        return;
    }
    id<KCCarouselTile> carouselTile = (id<KCCarouselTile>) visibleTile;
    [carouselTile highlightTile: YES];
    
    highlightedIndex = highlightIndex;
}

#pragma mark - Refreshing/updating view
- (void)updateSize {
    if (![tileFrames hasFrames]) {
        self.contentSize = CGSizeZero;
        return;
    }
    // add header view if avaialable and not already done
    if(headerView.superview != self) {
        [self addSubview: headerView];
    }
    
    // add footer if available
    if (footerView.superview != self) {
        [self addSubview:footerView];
    }
    
    // position header view
    if(headerView) {
        CGRect headerFrame = headerView.frame;
        headerFrame.origin = CGPointMake(0, 0);
        headerView.frame = headerFrame;
    }
    
    // get last tile frame
    CGRect lastTileFrame = [self rectForTileAtIndex: count - 1];
    
    // position the footer view
    CGSize firstTileSize = [carouselDataSource carousel:self sizeForTileAtIndex: 0];
    CGFloat maxTileX = CGRectGetMaxX(lastTileFrame);
    
    // add room for extra tile if we are inifinitely swiping
    if(count > 1 && infiniteSwiping) {
        maxTileX += firstTileSize.width;
    }
    
    CGFloat maxTileY = CGRectGetMaxY(lastTileFrame);
    if (footerView) {
        [self updateFooterSizeWithMaxX: maxTileX andMaxY: maxTileY];
    }
    
    // and update the scroll view's content size
    CGFloat contentSizeWidth = 0;
    CGFloat contentSizeHeight = 0;
    
    // grab footer sizes only if it is displayed, otherwise fail back to CGSizeZero
    CGSize footerSize = CGSizeZero;
    if(footerView != nil && footerView.alpha > 0 && !footerView.hidden ) {
        footerSize = footerView.frame.size;
    }
    
    switch (style) {
            // total width if the end of the last tile, unless
            // there is a footer view - in which case we pick the end of the footer view.
        case KCCarouselViewStyleHorizontal:
        case KCCarouselViewStyleStaggered:
            // figure out width, don't forget header/footer if applicable
            contentSizeWidth = maxTileX + footerSize.width;
            // and height
            contentSizeHeight = self.bounds.size.height - self.contentInset.top - self.contentInset.bottom;
            break;
            // Same applies here, by inverting X and Y.
        case KCCarouselViewStyleGrid:
            // contentSizeWidth use bounds directly because we do not allow horizon scroll in grid mode, otherwise it needs to use tileFrame for max Y
            contentSizeWidth = self.bounds.size.width - self.contentInset.left - self.contentInset.right;
            
            // and the height. Don't forget to make room for footer/header
            contentSizeHeight = maxTileY + CONTENT_PADDING;
            break;
    }
    
    self.contentSize = CGSizeMake(contentSizeWidth, contentSizeHeight);
    
}

- (void) updateFooterSizeWithMaxX: (CGFloat) maxX andMaxY: (CGFloat) maxY {
    CGRect frame = CGRectZero;
    CGSize footerViewSize = footerView.frame.size;
    CGSize frameSize = self.frame.size;
    
    switch(style) {
            // horizontal layout: the footer view goes to the right end of the scroll view
        case KCCarouselViewStyleHorizontal:
        case KCCarouselViewStyleStaggered:
            frame.origin = CGPointMake(maxX, 0);
            frame.size = footerViewSize;
            break;
            // grid view: the footer goes to the bottom of the view.
        case KCCarouselViewStyleGrid:
            frame.origin = CGPointMake(0, maxY);
            frame.size = CGSizeMake(frameSize.width, footerViewSize.height);
            break;
    };
    
    // hide the footer if we don't have at least one tile.
    footerView.frame = frame;
    footerView.alpha = count > 0;
}

/*
 Scrolls the content area to
 - selected index
 - highlight index IF highlightSelection is YES
 If frame for that index is invalid, does nothing.
 */
- (void)updatePosition {
    // default to current index
    NSUInteger scrollToIndex = index;
    // but if we have selection enabled and a valid selection index,
    // scroll to this one.
    if(highlightSelection && (highlightedIndex < count)) {
        scrollToIndex = highlightedIndex;
    }
    
    // abort if the index is invalid
    KCTileFrame *tileFrame = [tileFrames frameWithIndex: scrollToIndex];
    if(tileFrame == nil){
        return;
    }
    
    // scroll to given index
    [self scrollRectToVisible:tileFrame.frame animated:NO];
}

/*
 Update tile count and builds the Frame for EVERY tile in the carousel.
 The result is stored in the tileFrames object
 This assumes all tiles have the same style
 */
- (void)reindex {
    // update tiles count
    count = [carouselDataSource numberOfTilesInCarousel:self];
    
    // reset frame dictionaries
    [tileFrames clear];
    
    CGSize headerSize = headerView != nil ? headerView.frame.size : CGSizeZero;
    
    
    CGSize lastTileSize = CGSizeZero;
    if (count > 0) {
        lastTileSize = [carouselDataSource carousel:self sizeForTileAtIndex: count - 1];
    }
    
    CGFloat x= 0.0;
    // in horizontal mode, make room for the header
    if(style == KCCarouselViewStyleHorizontal) {
        x += headerSize.width;
    }
    
    // if infinite swiping and we have more than one cell,
    // make room for the last cell at the beginning of the carousel.
    if(count > 1 && infiniteSwiping) {
        x += lastTileSize.width;
    }
    
    CGFloat y = 0.0;
    if(style == KCCarouselViewStyleGrid) {
        // in grid mode, make room for the header above the carousel
        y += headerSize.height;
    }
    
    // got through every tile
    for (NSInteger i = 0; i < count; i++) {
        CGSize tileSize = [carouselDataSource carousel:self sizeForTileAtIndex:i];
        
        // compute frame for the current tile
        CGSize frameSize = self.frame.size;
        CGRect tileRect = CGRectZero;
        switch (style) {
            case KCCarouselViewStyleHorizontal:
                // position frame at current X position, center in container
                tileRect.origin = CGPointMake(x, (frameSize.height-tileSize.height)/2);
                break;
            case KCCarouselViewStyleGrid:
            case KCCarouselViewStyleStaggered:
                // position at current X/Y position
                tileRect.origin = CGPointMake(x, y);
                break;
        }
        
        // size the tile to whatever the current tile size should be
        tileRect.size = CGSizeMake(tileSize.width, tileSize.height);
        
        // move x position to end of tile rect.
        // in staggered mode, each tile is offset by half of the tile width,
        // so move by only half of the tile width
        if(style == KCCarouselViewStyleStaggered) {
            x += tileRect.size.width / 2 + contentPadding;
        } else {
            x += tileRect.size.width + contentPadding;
        }
        
        // in grid mode, if we went beyond the bounds of the view, reset X to 0
        // (aka "move to next line :))
        NSUInteger maxDrawableX = self.bounds.size.width-(self.contentInset.right+self.contentInset.left);
        if (style == KCCarouselViewStyleGrid && (x + tileRect.size.width) > maxDrawableX) {
            x = 0.0;
            // move y to bottom of current tile
            y = CGRectGetMaxY(tileRect) + contentPadding;
        }
        
        // in staggered mode, even indexed tiles are at the top, odd indexed tiles are one line below
        if(style == KCCarouselViewStyleStaggered) {
            y =  ((i % 2) == 0) * (CGRectGetMaxY(tileRect) + contentPadding);
        }
        
        // and save the tile frame
        [tileFrames addRect: tileRect forIndex: i];
    }
}

- (void) refresh {
    [self reload];
    [self setNeedsLayout];
}

- (void) reload {
    
    // removed tiles are actually the visible ones
    NSMutableArray *tilesToRemove = [NSArray arrayWithArray:visibleTiles];
    
    // just queue everything and reload
    for (UIView *tile in tilesToRemove) {
        [self queueResuableTile:tile];
    }
    
    // hold on to the current scroll rect so we can check if we have to reset it later on.
    CGRect currentScrollRect;
    currentScrollRect.origin = self.contentOffset;
    currentScrollRect.size = self.frame.size;
    
    // recreate tiles
    [self reindex];
    [self updateSize];
    
    // if the previous scroll rect is beyond the bounds of the carousel, reset it to (0,0)
    if(CGRectGetMaxX(currentScrollRect) > self.contentSize.width) {
        self.contentOffset = CGPointMake(- self.contentInset.left, - self.contentInset.top);
    }
    
    // and fill
    [self fillWithTiles];
}

- (void)updatePage {
    // paging is off, get the hell out of here now.
    if(!self.pagingEnabled) {
        return;
    }
    
    // grab page number based of content offset
    CGFloat value = ((double) self.contentOffset.x) / ((double)self.bounds.size.width);
    NSNumber *number = [NSNumber numberWithFloat: value];
    
    NSInteger currentPage = self.contentOffset.x < 1 ? 0 : [number intValue];
    
    // infinite swiping is ON, so make sure we don't have a non sensical page number :)
    if(infiniteSwiping && count > 1) {
        KCTileFrame *firstFrame = [tileFrames frameWithIndex: 0];
        KCTileFrame *lastFrame = [tileFrames frameWithIndex: count - 1];
        CGPoint contentOffset = self.contentOffset;
        if(contentOffset.x < firstFrame.savedOrigin.x) {
            currentPage = count - 1;
        } else if(contentOffset.x > lastFrame.savedOrigin.x) {
            currentPage = 0;
        } else {
            currentPage--;
        }
    }
    // make sure we don't get out of bounds
    currentPage = MIN(currentPage, count - 1);
    
    // page didn't change, get the hell out
    if (currentPage == page) {
        return;
    }
    
    page = currentPage;
    if ([(NSObject *)carouselDelegate respondsToSelector:@selector(carousel:didChangePage:)]) {
        [carouselDelegate carousel:self didChangePage:page];
    }
}

#pragma mark - Layout
- (void)layoutSubviews {
    
    if(didWarp) {
        didWarp = NO;
        return;
    }
    
    // resize tiles if needed
    [self resizeOnLayout];
    
    // update current index
    index = [self indexForPoint:self.contentOffset];
    
    // grab the current drawing rect
    CGRect tileDrawRect = [self drawingRect];
    
    // first remove non visible tiles and queue them for reuse.
    // copy the array because we're going to modify it in the loop :)
    NSArray *tilesToCheckForQueuing = [visibleTiles copy];
    for(UIView *tile in tilesToCheckForQueuing) {
        // tile is visible, don't touch it.
        if (CGRectIntersectsRect(tile.frame, tileDrawRect)) {
            continue;
        }
        
        // we're about to queue the first visible tile, so increment the
        // first visible index
        if (tile == [visibleTiles boundSafeObjectAtIndex: 0]) {
            firstVisibleIndex++;
            
            // make sure we warp firstVisible index when infinite swiping is on.
            if(infiniteSwiping && firstVisibleIndex >= count) {
                firstVisibleIndex = 0;
            }
        }
        
        [self queueResuableTile:tile];
    }
    
    // now recursively fill empty space in fill rect
    [self fillWithTiles];
    
    // don't forget to highlight if needed
    [self highlightTileAtIndex:highlightedIndex];
}

- (void) resizeOnLayout {
    // if we have a size change, reindex and resize visible tiles
    if (CGSizeEqualToSize(lastSize, self.frame.size)) {
        return;
    }
    
    //mmmmh... shouldn't this be also applicable if the width changes?
    // however, if this guy has changed height, it's likely due to a rotation
    // event, so the width will change along. I'll keep it as is for now, but we
    // have a potential bug here.
    // Note 2: actually, no, it could just be a resize mask event kicking in. We'll have to
    // fix this.
    if (lastSize.height != self.frame.size.height) {
        
        // now reindex frame positions
        [self reindex];
        [self updateSize];
        
        NSArray *visibleIndexes = [self visibleIndexes];
        // now let data source swap or update tiles
        for (NSUInteger i=0; i<[visibleTiles count]; i++) {
            
            // grab tile
            UIView *tile = [visibleTiles objectAtIndex:i];
            
            // figure out its global index and resize it
            NSInteger visibleIndex = [[visibleIndexes objectAtIndex:i] intValue];
            KCTileFrame *tileFrame = [tileFrames frameWithIndex: visibleIndex];
            tile.frame = tileFrame.frame;
            UIView *newTile = nil;
            
            // carousel doesn't support resize. Out of here, now!
            if (![carouselDataSource respondsToSelector:@selector(carousel:updateTile:forIndex:)]) {
                break;
            }
            
            // kindly ask datasource to update tile.
            newTile = [carouselDataSource carousel:self updateTile:tile forIndex: visibleIndex];
            
            // no change, move on to next tile
            if (newTile == tile) {
                continue;
            }
            
            // replace updated tile with new one
            NSUInteger subviewIndex = [self.subviews indexOfObject:tile];
            [tile removeFromSuperview];
            
            // also add as subview
            [visibleTiles replaceObjectAtIndex:i withObject:newTile];
            [self queueResuableTile:tile];
            newTile.frame = tileFrame.frame;
            [self insertSubview:newTile atIndex:subviewIndex];
        }
    }
    
    // update position whether the height has changed or not
    [self updatePosition];
    
    // and of course, don't forget to save last known size
    lastSize = self.frame.size;
}

- (void)fillWithTiles {
    // Note: this method is nasty, but it's going to be hard to break down in smaller chunks due to the fact
    // that we'll have to pass too much state around. So it'll stay this nasty bad boy, welcome to the hard world
    // of high performance UI. Fortunately, it should be commented enough so that somebody else than me can read it
    // and get the concept.
    
    // compute the rect we'll be filling
    CGRect fillRect = [self drawingRect];
    // the rect for a new tile, we have to declare it now
    CGRect newTileRect = CGRectZero;
    
    NSInteger newIndex = 0;
    BOOL addToBeginning = YES;
    
    // some tiles already exist, figure out where we will add the new ones
    if ([visibleTiles count] > 0) {
        // get first index
        UIView *firstVisibleTile = [visibleTiles objectAtIndex:0];
        
        // Derive index for new tile from index of first visible tile
        KCTileFrame *tileFrame = [tileFrames frameForView: firstVisibleTile];
        NSInteger firstIndex = tileFrame.index;
        
        // if fillRect overflows to the left or top of the first visible tile, we need to test add a new tile
        // to the left of the first visible rect.
        CGFloat minX = CGRectGetMinX(firstVisibleTile.frame);
        // staggered mode offsets everything by half of the current tile, so take that into account here
        minX += (style == KCCarouselViewStyleStaggered) * firstVisibleTile.frame.size.width / 2;
        
        BOOL hasTileToLeft = CGRectGetMinX(fillRect) < minX;
        BOOL hasTileToTop = style == KCCarouselViewStyleGrid && CGRectGetMinY(fillRect) < CGRectGetMinY(firstVisibleTile.frame);
        
        // yes, -(boolean value). This will evaluate to -1 if infinite swiping is on, which is what we want.
        BOOL shouldFillToLeftOrTop = firstIndex > -infiniteSwiping && (hasTileToLeft || hasTileToTop);
        if (shouldFillToLeftOrTop) {
            newIndex =  (infiniteSwiping && firstIndex == 0 && count > 1) ? count - 1 : firstIndex - 1;
            
            // we're about to show first frame. reset it to its original position.
            // note: we DON'T want to do that if there's only one tile in the carousel, that'll end up
            // in an infinite loop of moving tiles around
            if(count > 1) {
                if(newIndex == 0) {
                    [tileFrames resetFirstFrame];
                }
                // we're about to show the last frame, coming from its right. Warp it to the begininning of the queue.
                if(newIndex == count - 1){
                    [tileFrames warpLastFrame];
                }
            }
            
            // eventually, grab the frame for that new tile
            newTileRect = [self rectForTileAtIndex: newIndex];
            if (!CGRectIntersectsRect(fillRect, newTileRect)) {
                newTileRect = CGRectZero; // DON'T add the new rect if its outside of the fill rect (given padding)
            }
        }
        
        // the frame for the new tile is still empty
        if (CGRectIsEmpty(newTileRect)) {
            // grab last visible tile now.
            UIView *lastVisibleTile = [visibleTiles lastObject];
            // Derive index for new tile from index of last visible tile
            KCTileFrame *lastTileFrame = [tileFrames frameForView: lastVisibleTile];
            NSInteger lastIndex = lastTileFrame.index;
            
            // if fillrect overflows to the right of the last visible tile, we need to add a new tile
            // to the left of the first visible rect.
            CGFloat maxX = CGRectGetMaxX(lastVisibleTile.frame);
            maxX -= (style == KCCarouselViewStyleStaggered) * lastVisibleTile.frame.size.width / 2;
            BOOL hasTileToRight = maxX < CGRectGetMaxX(fillRect);
            BOOL hasTileToBottom = style == KCCarouselViewStyleGrid && CGRectGetMaxY(fillRect) > CGRectGetMaxY(lastVisibleTile.frame);
            BOOL shouldFillToRightOrBottom = lastIndex < (count - 1 + infiniteSwiping) && (hasTileToRight || hasTileToBottom);
            if (shouldFillToRightOrBottom) {
                newIndex = (infiniteSwiping && lastIndex == count - 1 && count > 1) ? 0 : lastIndex + 1;
                
                // we're about to show first frame. reset it to its original position
                // note: we DON'T want to do that if there's only one tile in the carousel, that'll end up
                // in an infinite loop of moving tiles around
                if(count > 1) {
                    if(newIndex == 0) {
                        [tileFrames warpFirstFrame];
                    }
                    // we're about to show the last frame, coming from its right. Warp it to the begininning of the queue.
                    if(newIndex == count - 1){
                        [tileFrames resetLastFrame];
                    }
                }
                
                // eventually, grab the frame for that new tile
                newTileRect = [self rectForTileAtIndex: newIndex];
                if (!CGRectIntersectsRect(fillRect, newTileRect)) {
                    newTileRect = CGRectZero; // DON'T add the new rect if its outside of the fill rect (given padding)
                }
                addToBeginning = NO;
            }
        }
    } else if (index < count && !CGSizeEqualToSize(self.contentSize, CGSizeZero)) {
        // otherwise, just start with current index.
        newIndex = index;
        newTileRect = [self rectForTileAtIndex:index];
    }
    
    // if the new tile is empty, bail out now.
    if (CGRectIsEmpty(newTileRect)) {
        return;
    }
    
    // ask kindly for a new tile, update the frame and add it to the scene
    UIView *newTile = [self carouselTileForIndex:newIndex];
    if(newTile == nil) {
        return;
    }
    
    // position the tile now :) that was easy, wasn't it?
    newTile.frame = newTileRect;
    
    // insert it where relevant in the visible tiles array
    // be careful to insert the views in "lowest index at the lowest z index"
    // fashion, it will help out in case cell overlapping happens.
    if (addToBeginning) {
        firstVisibleIndex = newIndex;
        [self insertSubview:newTile atIndex:0];
        [visibleTiles insertObject:newTile atIndex:0];
    } else {
        [self addSubview:newTile];
        [visibleTiles addObject:newTile];
    }
    
    // recurse until we stop adding tiles
    [self fillWithTiles];
}

#pragma mark - Convenience tile accessors
- (id) visibleTileWithIndex: (NSInteger) tileIndex {
    NSInteger currentIndex = 0;
    for(NSNumber *visibleIndex in [self visibleIndexes]) {
        if([visibleIndex intValue] == tileIndex){
            return [visibleTiles objectAtIndex: currentIndex];
        }
        currentIndex++;
    }
    return nil;
}


#pragma mark - Gesture recognizers
#pragma mark Single Tap Recognizer (aka selection)
- (void) setTapGestureDisabled: (BOOL) disabled {
    if(disabled) {
        [self disableTapGestureRecognizer];
    } else {
        [self enableTapGestureRecognizer];
    }
}

- (void) disableTapGestureRecognizer {
    if(tileTapRecognizer == nil) {
        return;
    }
    self.canCancelContentTouches = NO;
    [self removeGestureRecognizer: tileTapRecognizer];
    tileTapRecognizer = nil;
}

- (void) enableTapGestureRecognizer {
    if(tileTapRecognizer != nil) {
        return;
    }
    
    tileTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tileTapped:)];
    tileTapRecognizer.delegate = self;
    self.canCancelContentTouches = YES;
    if(doubleTapRecognizer != nil) {
        [tileTapRecognizer requireGestureRecognizerToFail: doubleTapRecognizer];
    }
    [self addGestureRecognizer:tileTapRecognizer];
}

#pragma mark Double tap gesture recognizer
- (void)setDoubleTapGestureDisabled: (BOOL) disabled {
    if(disabled) {
        [self disableDoubleTapGestureRecognizer];
    } else {
        [self enableDoubleTapGestureRecognizer];
    }
}

- (void) disableDoubleTapGestureRecognizer {
    if(doubleTapRecognizer == nil) {
        return;
    }
    
    [self removeGestureRecognizer: doubleTapRecognizer];
    doubleTapRecognizer = nil;
}

- (void) enableDoubleTapGestureRecognizer {
    if(doubleTapRecognizer != nil) {
        return;
    }
    
    doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tileTapped:)];
    doubleTapRecognizer.delegate = self;
    doubleTapRecognizer.numberOfTapsRequired = 2;
    [tileTapRecognizer requireGestureRecognizerToFail: doubleTapRecognizer];
    
    [self addGestureRecognizer:doubleTapRecognizer];
}

#pragma mark Tap gesture recognizer and delegate
- (void)tileTapped:(UITapGestureRecognizer *)recognizer {
    if(recognizer.state != UIGestureRecognizerStateRecognized){
        return;
    }
    // first, find the tile that's under the tap
    UIView *tileView = nil;
    for (UIView *visibleTile in visibleTiles) {
        if (CGRectContainsPoint(visibleTile.frame, [recognizer locationInView:self])) {
            tileView = visibleTile;
            break;
        }
    }
    
    // no tile, out.
    if (tileView == nil) {
        return;
    }
    
    // the tile handles the tap itself, don't do anything
    if ([tileView respondsToSelector:@selector(ignoreTapAtLocation:)] && [(id<KCCarouselTile>)tileView ignoreTapAtLocation:[recognizer locationInView:tileView]]) {
        return;
    }
    
    // now figure out if we should go to double/single tap
    if (recognizer == doubleTapRecognizer) {
        if ([tileView respondsToSelector:@selector(handleDoubleTap:)]) {
            [tileView performSelector:@selector(handleDoubleTap:) withObject:recognizer];
        }
        return;
    }
    
    // highlight tile, it's been selected
    KCTileFrame *clickedTileFrame = [tileFrames frameForView: tileView];
    NSInteger clickedTileIndex = clickedTileFrame.index;
    [self highlightTileAtIndex:clickedTileIndex];
    
    // and notify delegate it's been selected, if it supports it
    if([carouselDelegate respondsToSelector:@selector(carousel:didSelectIndex:)]) {
        [carouselDelegate carousel:self didSelectIndex:clickedTileIndex];
    }
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    // we don't want our tap gesture recognizer to block other tap gesture recognizers defined by the cell
    return gestureRecognizer == tileTapRecognizer || otherGestureRecognizer == tileTapRecognizer;
}

#pragma mark - Geometry/Index convenience method
// returns rect for tile at given index
- (CGRect) rectForTileAtIndex: (NSInteger) tileIndex {
    KCTileFrame *tileFrame = [tileFrames frameWithIndex: tileIndex];
    if(tileFrame == nil) {
        return  CGRectZero;
    }
    
    return tileFrame.frame;
}

- (CGRect)drawingRect {
    CGRect inset;
    inset.origin = self.contentOffset;
    inset.size = self.frame.size;
    
    return UIEdgeInsetsInsetRect(inset, tileDrawInset);
}

// for any given point, finds a frame for that point from frame index calculated on -reload
- (NSInteger)indexForPoint:(CGPoint)point {
    // point is origin, return first index, 0
    if (point.x < 1) {
        return infiniteSwiping ? count - 1 : 0;
    }
    
    CGFloat xCoord = point.x;
    // go through all existing frame values and test if the point hits in
    // any of them
    for (KCTileFrame *tileFrame in [tileFrames allFrames]) {
        CGRect rect = tileFrame.frame;
        
        CGFloat begin = rect.origin.x;
        CGFloat end = rect.size.width + begin;
        if (xCoord >= begin && end > xCoord) {
            return tileFrame.index;
        }
    }
    // nothing found, return lasst frame
    NSInteger lastIndex = [tileFrames count] - 1;
    KCTileFrame *lastFrame = [tileFrames frameWithIndex: lastIndex];
    return lastFrame.index;
}

- (NSArray *)visibleIndexes {
    NSMutableArray *visibleIndexes = [NSMutableArray arrayWithCapacity:[visibleTiles count]];
    
    NSInteger currentIndex = 0;
    
    for(UIView *visibleTile in visibleTiles){
        // make sure indexes don't get out of bounds on infinite swiping
        NSInteger visibleIndexInt = firstVisibleIndex + currentIndex;
        if(infiniteSwiping && visibleIndexInt > count - 1) {
            visibleIndexInt -= count;
        }
        
        NSNumber *visibleIndex = [NSNumber numberWithInt: visibleIndexInt];
        [visibleIndexes addObjectNilSafe: visibleIndex];
        currentIndex++;
    }
    
    return visibleIndexes;
}

#pragma mark Visible <-> actual index utility methods
- (BOOL) isIndexVisible: (NSInteger) tileIndex {
    // index is visible if is in the range "first visible, visible count long"
    NSInteger visibleCount = [visibleTiles count];
    return tileIndex >= firstVisibleIndex && tileIndex < (firstVisibleIndex + visibleCount);
}

- (NSInteger) lastVisibleIndex {
    return firstVisibleIndex + [visibleTiles count] - 1;
}

- (NSInteger) actualIndexToVisibleIndex: (NSInteger) actualIndex {
    return actualIndex - firstVisibleIndex;
}

- (NSInteger) visibleIndexToActualIndex: (NSInteger) visibleIndex {
    return visibleIndex + firstVisibleIndex;
}

- (KCTileFrame*) frameForTileAtVisibleIndex: (NSInteger) tileIndex {
    NSInteger globalIndex = [self visibleIndexToActualIndex: tileIndex];
    return [tileFrames frameWithIndex: globalIndex];
}

#pragma mark - Scroll delegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // stopping/starting the recognizer will reset it. That prevents
    // the tap gesture recgonizer to be too sensitive.
    tileTapRecognizer.enabled = NO;
    tileTapRecognizer.enabled = YES;
    
    if(delegateSupportsIsScrolling) {
        [carouselDelegate carouselIsScrolling:self];
    }
}
- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (delegateSupportsDidBeginDragging) {
        [carouselDelegate carouselDidBeginDragging: self];
    }
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    if (self.pagingEnabled) {
        [self updatePage];
    }
    
    if(delegateSupportsEndDeceleration) {
        [carouselDelegate carouselDidEndScrolling:self];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    if (self.pagingEnabled) {
        // if warping, animation end will take care of page update
        [self warpIfNeeded];
        [self updatePage];
    }
    
    if(delegateSupportsEndDeceleration) {
        [carouselDelegate carouselDidEndScrolling:self];
    }
}

#pragma mark - tile warping
- (BOOL) warpIfNeeded {
    CGPoint contentOffset = self.contentOffset;
    
    KCTileFrame *firstFrame = [tileFrames frameWithIndex: 0];
    KCTileFrame *lastFrame = [tileFrames frameWithIndex: count - 1];
    
    // warping from the beginning to the end of the carousel
    if(contentOffset.x < firstFrame.savedOrigin.x) {
        didWarp = YES;
        // grab the currently visible view
        NSInteger visibleIndex = [self actualIndexToVisibleIndex: lastFrame.index];
        didWarp = visibleIndex < [visibleTiles count];
        
        // reset its location
        [tileFrames resetLastFrame];
        
        if(didWarp) {
            UIView *tile = [visibleTiles objectAtIndex: visibleIndex];
            
            // and apply that to the view. We DON'T want layout to kick in here,
            // since it will grab a new tile and reload it.
            CGRect frame = tile.frame;
            frame.origin = lastFrame.frame.origin;
            tile.frame = frame;
        }
        // now jump to new content offset
        [self setContentOffset: lastFrame.savedOrigin animated: NO];
        return YES;
    }
    
    // the other way around, from the end to the beginning
    if(contentOffset.x > lastFrame.savedOrigin.x){
        
        // grab the currently visible view
        NSInteger visibleIndex = [self actualIndexToVisibleIndex: firstFrame.index];
        didWarp = visibleIndex < [visibleTiles count];
        
        // reset its location
        [tileFrames resetFirstFrame];
        
        if(didWarp) {
            UIView *tile = [visibleTiles objectAtIndex: visibleIndex];
            
            // and apply that to the view. We DON'T want layout to kick in here,
            // since it will grab a new tile and reload it.
            CGRect frame = tile.frame;
            frame.origin = firstFrame.frame.origin;
            tile.frame = frame;
        }
        // now jump to new content offset
        [self setContentOffset: firstFrame.savedOrigin animated: NO];
        return YES;
    }
    
    return  NO;
}

@end
#endif