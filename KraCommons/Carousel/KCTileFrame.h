//
//  KCTileFrame.h
//
//  Created by Olivier Larivain on 1/11/13.
//  Copyright 2012 kra All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import <Foundation/Foundation.h>

/*
  Represents a tile's frame of a tile for a given index.
 In order to support infinite swiping, a tile frame can be warped to a given arbitrary point
 and reset to its original position
 */
@interface KCTileFrame : NSObject {
    NSInteger index;
    CGRect frame;
    // origin at the time of init.
    CGPoint savedOrigin;
}

+ (KCTileFrame*) tileFrame;
+ (KCTileFrame*) tileFrameWithIndex: (NSInteger) index andFrame: (CGRect) frame;

@property (nonatomic, readwrite, assign) NSInteger index;
@property (nonatomic, readwrite, assign) CGRect frame;
@property (nonatomic, readonly) CGPoint savedOrigin;

// warps the tile to given point
- (void) warpToPoint: (CGPoint) point;
// resets the tile to its initial origin
- (void) reset;

@end
#endif