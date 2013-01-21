//
//  NSObject+PerformBlock.h
//  
//
//  Created by Olivier Larivain on 12/31/12.
//  Copyright (c) 2012 kra. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (PerformBlock)

- (void) performBlock: (KCVoidBlock) block
            withDelay: (NSTimeInterval) delay;

@end
