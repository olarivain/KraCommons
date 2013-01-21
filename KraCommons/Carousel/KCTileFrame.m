//
//  OTKTileFrame.m
//
//  Created by Olivier Larivain on 1/11/13.
//  Copyright 2012 OpenTable, Inc. All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "KCTileFrame.h"

@interface KCTileFrame()
- (id) initWithIndex: (NSInteger) anIndex andFrame: (CGRect) aFrame;
@end

@implementation KCTileFrame

+ (KCTileFrame*) tileFrame {
    return [[KCTileFrame alloc] initWithIndex: 1 andFrame: CGRectZero];
}

+ (KCTileFrame*) tileFrameWithIndex: (NSInteger) index andFrame: (CGRect) frame {
    return [[KCTileFrame alloc] initWithIndex: index andFrame: frame];
}

- (id) initWithIndex: (NSInteger) anIndex andFrame: (CGRect) aFrame {
    self = [super init];
    if(self) {
        index = anIndex;
        frame = aFrame;
        savedOrigin = self.frame.origin;
    }
    return self;
}

@synthesize index;
@synthesize frame;
@synthesize savedOrigin;

#pragma mark - Warping
- (void) warpToPoint: (CGPoint) point {
    frame.origin = point;
}

- (void) reset {
    frame.origin = savedOrigin;
}

@end
#endif