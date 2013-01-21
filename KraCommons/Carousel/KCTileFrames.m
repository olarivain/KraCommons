//
//  KCTileFrames.m
//
//  Created by Olivier Larivain on 1/11/13.
//  Copyright 2012 kra All rights reserved.
//
#if __IPHONE_OS_VERSION_MIN_REQUIRED
#import "KCTileFrames.h"
#import "KCTileFrame.h"

@interface KCTileFrames()
@end

@implementation KCTileFrames

+ (KCTileFrames*) tileFrames {
    return  [[KCTileFrames alloc] init];
}

- (id) init {
    self = [super init];
    if(self) {
        frames = [NSMutableArray arrayWithCapacity:20];
    }
    return self;
}


#pragma mark - Convenience accessors
- (KCTileFrame*) frameWithIndex: (NSInteger) index {
    return  [frames boundSafeObjectAtIndex: index];
}

- (KCTileFrame*) frameWithRect: (CGRect) rect {
    for(KCTileFrame *frame in frames) {
        if(CGRectEqualToRect(frame.frame,  rect)) {
            return  frame;
        }
    }
    return nil;
}

- (KCTileFrame*) frameForView: (UIView*) view {
    return [self frameWithRect: view.frame];
}

#pragma mark - Add/Remove
- (void) addRect: (CGRect) rect forIndex: (NSInteger) index {
    KCTileFrame *frame = [KCTileFrame tileFrameWithIndex:index andFrame: rect];
    [frames addObject: frame];
}

- (void) clear {
    [frames removeAllObjects];
}

#pragma mark - Convenience methods
- (BOOL) hasFrames {
    return  [frames count] > 0;
}

- (KCTileFrame*) lastFrame {
    return [frames lastObject];
}

- (NSArray *) allFrames {
    return  frames;
}

- (NSInteger) count {
    return [frames count];
}

#pragma mark - Frame warping
#pragma mark First Frame
- (void) warpFirstFrame {
    KCTileFrame *firstFrame = [self frameWithIndex: 0];
    KCTileFrame *lastFrame = [self frameWithIndex: [self count] -1];
    
    CGPoint lastFrameOrigin = lastFrame.frame.origin;
    CGSize lastFrameSize = lastFrame.frame.size;
    
    CGPoint frameWarpedOrigin = firstFrame.frame.origin;
    frameWarpedOrigin.x = lastFrameOrigin.x + lastFrameSize.width;
    [firstFrame warpToPoint: frameWarpedOrigin];
}

- (void) resetFirstFrame {
    KCTileFrame *firstFrame = [self frameWithIndex: 0];
    [firstFrame reset];
}

#pragma mark Last frame
- (void) warpLastFrame {
    KCTileFrame *lastFrame = [self frameWithIndex: [self count] -1];
    
    CGPoint frameWarpedOrigin = lastFrame.frame.origin;
    frameWarpedOrigin.x = 0;
    [lastFrame warpToPoint: frameWarpedOrigin];

}

- (void) resetLastFrame {
    KCTileFrame *lastFrame = [self frameWithIndex: [self count] -1];
    [lastFrame reset];
}

@end
#endif