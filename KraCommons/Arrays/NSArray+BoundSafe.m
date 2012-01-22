//
//  NSArray+BoundSafe.m
//
//  Created by Larivain, Olivier on 7/15/11.
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

@implementation NSMutableArray (NSMutableArray_NilSafe)

- (void) addObjectNilSafe: (id) object {
    if(object == nil) {
        return;
    }
    
    [self addObject: object];
}

@end