//
//  NSArray+BoundSafe.m
//  KraCommons
//
//  Created by Kra on 12/28/12.
//  Copyright (c) 2012 kra All rights reserved.
//

#import "NSArray+BoundSafe.h"

@implementation NSArray (BoundSafe)

- (id)boundSafeObjectAtIndex:(NSInteger) index
{
    if(index < 0 || index >= self.count)
    {
        return nil;
    }
    
    return [self objectAtIndex: index];
}

@end

@implementation NSMutableArray (NullSafe)

- (void)addObjectNilSafe:(id)object
{
    if(object == nil || object == [NSNull null])
    {
        return;
    }
    
    [self addObject: object];
}

@end

@implementation NSMutableSet (NullSafe)

- (void)addObjectNilSafe:(id)object
{
    if(object == nil || object == [NSNull null])
    {
        return ;
    }
    
    [self addObject: object];
}

@end
