//
//  KCTileFrames.h
//
//  Created by Olivier Larivain on 1/11/13.
//  Copyright 2012 kra All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <Foundation/Foundation.h>

@class KCTileFrame;

/*
 Root aggregate for ECTileFrames. Provides convenience methods, as well as high level 
 business methods, for warping the first and last tile in the context of infinite swiping.
 */
@interface KCTileFrames : NSObject {
    NSMutableArray *frames;
}
// static autoreleased init
+ (KCTileFrames*) tileFrames;

// convenience accessors
- (KCTileFrame*) frameWithIndex: (NSInteger) index;
- (KCTileFrame*) frameWithRect: (CGRect) rect;
- (KCTileFrame*) frameForView: (UIView*) view;

// adds given rect with given tile index
- (void) addRect: (CGRect) rect forIndex: (NSInteger) index;
// removes ALL tiles
- (void) clear;

// whether there is at least one tile
- (BOOL) hasFrames;

// all tile frames
- (NSArray *) allFrames;
- (KCTileFrame*) lastFrame;
// number of tile frames
- (NSInteger) count;

// warps first frame to the end of the scroll view (i.e., right after the last tile)
- (void) warpFirstFrame;
// resets first frame to its original position
- (void) resetFirstFrame;

// warps last frame to the very begining of the scroll view (i.e., right before the first tile)
- (void) warpLastFrame;
// resets last frame to its original position
- (void) resetLastFrame;
@end
#endif