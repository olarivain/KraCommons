//
//  NSObject+PerformBlock.m
//  
//
//  Created by Olivier Larivain on 12/31/12.
//  Copyright (c) 2012 kra. All rights reserved.
//

#import "NSObject+PerformBlock.h"

@implementation NSObject (PerformBlock)

- (void) performBlock: (KCVoidBlock) block
           withDelay: (NSTimeInterval) delay {
    if(block == NULL) {
        return;
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC*delay),
                   dispatch_get_current_queue(), block);
}

@end
