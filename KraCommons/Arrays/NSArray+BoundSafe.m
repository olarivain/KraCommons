//
//  NSArray+BoundSafe.m
//  ECUtil
//
//  Created by Larivain, Olivier on 7/15/11.
//  Copyright 2011 Edmunds. All rights reserved.
//

#import "NSArray+BoundSafe.h"


@implementation NSArray (NSArray_BoundSafe)

- (id) boundSafeObjectAtIndex: (NSInteger) index {
    if(index < 0 || index>= [self count]) {
        return  nil;
    }
    
    return [self objectAtIndex: index];
}

@end
